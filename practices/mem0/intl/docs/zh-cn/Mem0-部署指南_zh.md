# Mem0，AI Agent 通用记忆层——部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 1.0
> **发布日期：** 2026-08-06
> **适用站点：** intl（国际站）
> **适用区域：** ap-southeast-1 / ap-southeast-2 / ap-southeast-3 / af-south-1 / af-north-1 / la-north-2 / sa-brazil-1 / tr-west-1

## 1. 方案概述

Mem0 是一个 AI Agent 通用记忆层，为 AI 应用提供持久化、可学习的记忆能力。本方案通过华为云资源编排服务 RFS，在国际站所选区域创建 1 个资源栈，部署 Mem0 自托管服务。

### 1.1 应用场景

- **AI 助手持久记忆：** 为 AI 助手添加跨会话的用户偏好和历史记忆，实现个性化交互。
- **客户支持系统：** 记录客户历史对话和偏好，在多次服务交互中保持上下文。
- **RAG 应用记忆层：** 在检索增强生成应用中增加用户级别的记忆管理。
- **多 Agent 协作：** 不同 Agent 共享统一的记忆层，保持协作上下文一致。

### 1.2 方案架构

```text
互联网
  │
EIP
  │
ECS（Ubuntu 24.04，Docker Compose）
  ├─ Mem0 API :8888（FastAPI 服务）
  ├─ PostgreSQL + pgvector :5432（向量存储）
  └─ Mem0 Dashboard :3000（管理界面）
```

标准版在 1 个 RFS 资源栈中创建 1 个 VPC、1 个子网、1 个安全组、1 个 EIP 和 1 台 ECS。ECS 上由 Docker Compose 运行 3 个容器；PostgreSQL 数据与 Mem0 历史数据保存在 ECS 系统盘上的 Docker 卷中。

模板将 TCP 8888（API）和 3000（Dashboard）开放到公网，SSH 22 仅允许模板指定的 Cloud Shell 地址访问。API 输出 HTTP 地址，不包含 TLS 终止，生产使用前应限制安全组来源或增加 HTTPS 入口。

### 1.3 方案优势

- **单栈交付：** 由 1 个 RFS 资源栈管理，便于审阅执行计划、部署和统一删除。
- **一键部署：** 自动安装 Docker、克隆代码库、构建镜像、启动 Mem0 全栈服务。
- **密钥自动生成：** 数据库密码和 JWT 密钥在部署时在 ECS 本地随机生成，不通过模板变量传递。
- **多种 LLM 支持：** 默认使用 OpenAI，可通过 Dashboard 切换到 Anthropic、Gemini 或其他提供商。

### 1.4 约束与限制

- Mem0 需要 LLM API Key 才能正常工作（默认 OpenAI）。部署后必须在 Dashboard 或 `/opt/mem0/.env` 中配置 API Key。
- 部署前须确认账号状态、服务权限、资源配额与目标规格在所选区域可售。
- 首次部署时需要构建 Docker 镜像，约需 10-15 分钟。
- 本方案是单 ECS 架构，没有计算、数据库或缓存高可用。
- 删除 ECS/资源栈会删除系统盘及其本地 Docker 卷数据。

### 1.5 上线信息

```text
形式：RFS 一键部署
站点：intl（国际站）
Region：ap-southeast-1 / ap-southeast-2 / ap-southeast-3 / af-south-1 / af-north-1 / la-north-2 / sa-brazil-1 / tr-west-1
```

## 2. 资源与成本规划

以下表格不填写固定价格。云服务价格会随区域、规格、计费方式、购买时长、折扣和流量变化；请在部署前使用 RFS 执行计划和华为云价格计算器取得当前估算，并以实际账单为准。所有表格均不包含 LLM Provider 调用费。

### 2.1 按需计费

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| VPC、子网、安全组 | `172.16.0.0/16`，1 个业务子网 | 各 1 | 在执行计划中核对是否产生独立费用 |
| ECS | `c7n.2xlarge.2`，Ubuntu 24.04 | 1 | 按需实例时长 |
| ECS 系统盘 | GPSSD，默认 100 GB | 1 | 按容量与使用时长 |
| EIP 与公网带宽 | 动态 BGP，默认 200 Mbit/s，按流量 | 1 | 公网流量及相关 EIP 费用 |

### 2.2 包年包月

| 资源 | 模板配置 | 数量 | 计费核对方式 |
|---|---|---:|---|
| ECS 与系统盘 | `charging_mode=prePaid`；购买周期由 `charging_unit`、`charging_period` 指定 | 1 | 在订单和执行计划中核对订购费用 |
| EIP 与公网带宽 | 模板固定 EIP 为 `postPaid`、按流量；不随 ECS 改为包年包月 | 1 | 按实际公网流量核对 |
| VPC、子网、安全组 | 与按需部署相同 | 各 1 | 在执行计划中核对 |

> **费用声明：** 预估费用仅供参考，实际费用取决于所选规格、计费模式、折扣与实际用量，最终以华为云账单为准。请使用[华为云价格计算器](https://www.huaweicloud.com/pricing/)获取实时估算。

## 3. 实施步骤

### 3.1 准备工作

1. 注册并实名认证华为云账号，确认账户无欠费或冻结。
2. 确认在所选区域具备 RFS、VPC、EIP、ECS 等资源权限。
3. 为 RFS 配置专用 IAM 权限委托，并按实际资源采用最小权限。RFS 官方创建资源栈说明见[创建资源栈](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0003.html)。
4. 核对配额：至少需要 1 个 VPC、1 个 EIP、1 台 ECS。
5. 准备 OpenAI API Key（或后续在 Dashboard 中配置 Anthropic/Gemini Key）。
6. 使用密码学安全随机数生成器准备 ECS root 密码：

   ```bash
   openssl rand -base64 16
   ```

### 3.2 快速部署

1. 登录华为云控制台，进入"资源编排服务 RFS > 资源栈 > 创建资源栈"。
2. 选择上传本地 `.tf` 文件并上传所选区域的 `deploying-mem0.tf`。
3. 填写下表全部变量。表中默认值以实际 Terraform 为准。

| 参数 | 默认值 | 说明 |
|---|---|---|
| `solution_name` | `mem0-memory-layer` | 资源名称前缀；4-24 位，小写字母开头，仅含小写字母、数字和中划线 |
| `ecs_flavor` | `c7n.2xlarge.2` | ECS 规格；模板校验 `c7n.{U}xlarge.{G}` 格式 |
| `ecs_password` | 无 | **敏感值**；ECS root 密码，8-26 位，至少包含大写、小写、数字、特殊字符中的三类 |
| `openai_api_key` | 无 | **敏感值**；OpenAI API Key，用于 Mem0 默认 LLM 和 Embedding 模型 |
| `system_disk_size` | `100` | 系统盘 GB，范围 40-1024 |
| `bandwidth_size` | `200` | EIP 带宽 Mbit/s，范围 1-300，按流量计费 |
| `charging_mode` | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月 |
| `charging_unit` | `month` | 包年包月周期单位：`month` 或 `year` |
| `charging_period` | `1` | 购买周期；按月 1-9、按年 1-3 |

4. 选择权限委托，检查高级配置与删除保护设置。
5. 建议先创建执行计划，审阅将创建的资源和实时费用估算，再部署资源栈。
6. 资源栈显示部署完成后，查看输出 `access_info`。等待 ECS 启动脚本完成（约 10-15 分钟），再使用输出中的 API、Dashboard 和 API Docs 地址。

### 3.3 开始使用与验证

从 RFS 输出 `access_info` 复制实际地址并设置本地变量：

```bash
export MEM0_API='从 access_info 复制 API 地址（不含端口，如 http://123.xxx.xxx.xxx）'
export MEM0_DASHBOARD='从 access_info 复制 Dashboard 地址'
```

#### 验证 API 健康状态

```bash
curl --fail --silent --show-error "$MEM0_API:8888/docs"
```

预期返回 Swagger UI HTML 页面。

#### 访问 Dashboard 完成初始设置

1. 在浏览器中打开 Dashboard 地址 `http://<EIP>:3000`。
2. 首次访问时，注册管理员账号（邮箱、密码、名称）。
3. 登录后进入 Settings > API Keys，创建一个 API Key。
4. 进入 Configuration 页面，确认默认 LLM 和 Embedder 设置（默认使用 `OPENAI_API_KEY`）。

#### 测试 Mem0 API

```bash
export API_KEY='从 Dashboard 创建的 API Key'

curl -X POST "$MEM0_API:8888/memories" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "I like hiking"}], "user_id": "test-user"}'
```

搜索记忆：

```bash
curl -X POST "$MEM0_API:8888/search" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "outdoor activities", "user_id": "test-user"}'
```

### 3.4 配置 LLM 和 Embedding 服务

部署后，可通过以下两种方式配置 LLM：

**方式一：Dashboard 配置**

登录 Dashboard > Configuration，选择 LLM 提供商（OpenAI/Anthropic/Gemini），输入 API Key 并保存。

**方式二：直接编辑配置文件**

```bash
sudoedit /opt/mem0/.env
sudo chmod 0600 /opt/mem0/.env
```

修改或添加以下变量：

```bash
# OpenAI（默认）
OPENAI_API_KEY=sk-...

# 或 Anthropic
# ANTHROPIC_API_KEY=sk-ant-...

# 或 Google Gemini
# GOOGLE_API_KEY=...
```

修改后重启 Mem0 服务：

```bash
cd /opt/mem0
docker compose restart mem0
```

### 3.5 故障排查

| 现象 | 核对项 |
|---|---|
| 资源栈完成但 API 不可用 | 查看 `/var/log/mem0-bootstrap.log`、`docker compose ps` 与 `/opt/mem0/` 下的容器日志；确认 8888/3000 安全组来源符合访问端 |
| Dashboard 无法连接 API | 确认 Dashboard 的 `NEXT_PUBLIC_API_URL` 为 `http://localhost:8888`，且 mem0 容器已正常运行 |
| API 返回 `provider_auth_failed` | 未配置 LLM 提供商 API Key；在 Dashboard 或 `/opt/mem0/.env` 中配置 |
| 记忆添加/搜索慢 | pgvector 索引需要时间构建；确认 ECS 规格满足推荐配置 |
| Docker 镜像拉取失败 | 检查 ECS 出站网络连通性；使用 `docker compose logs` 查看具体错误 |

### 3.6 快速卸载

1. 备份仍需保留的记忆数据与 PostgreSQL 数据，并验证备份可恢复。
2. 登录 RFS 资源栈列表，选择目标资源栈并执行删除资源操作。
3. 按控制台提示确认删除，持续观察资源事件直至删除完成。
4. 在 VPC、EIP 和 ECS 控制台复核是否仍有资源需要处理，避免遗留费用。

> PostgreSQL 数据与 Mem0 历史数据位于 ECS 系统盘上的 Docker 卷中。模板设置随 ECS 删除磁盘。删除前必须自行完成数据保留策略。

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|---|---|
| Mem0 | AI Agent 通用记忆层，为 LLM 应用提供持久化、可学习的记忆能力 |
| pgvector | PostgreSQL 的向量相似度搜索扩展，用于存储和检索记忆嵌入向量 |
| RFS | 资源编排服务，通过 Terraform 模板管理云资源栈生命周期 |
| EIP | 弹性公网 IP，为 ECS 提供公网访问能力 |
| GPSSD | 通用型 SSD，华为云 EVS 的一种磁盘类型 |
| JWT | JSON Web Token，用于 API 认证的令牌格式 |

### 4.2 参考文档

- [Mem0 官方文档](https://docs.mem0.ai)
- [Mem0 GitHub 仓库](https://github.com/mem0ai/mem0)
- [Mem0 研究论文](https://arxiv.org/abs/2504.19413)
- [华为云 RFS 创建资源栈](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0003.html)
- [华为云价格计算器](https://www.huaweicloud.com/pricing/)

## 5. 修订记录

| 发布日期 | 修订记录 |
|---|---|
| 2026-08-06 | 初始版本，基于 `deploying-mem0.tf` 实现 intl 多区域标准版。 |
