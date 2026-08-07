# 部署 Supabase — 开源 Firebase 替代 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 02（候选）
> **更新日期：** 2026-07-14

> **验证状态：** 本指南已与 `deploying-supabase_v6.tf` 候选模板对齐；版本号与中国站候选同步递增，但国际站仍使用官方上游网络。尚未完成华为云真实部署、cloud-init 和应用验证，不应视为已通过生产验证的版本。

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 ECS 实例上部署 Supabase。候选模板在官方 commit `00ecb5305965ff85e1b5757e34a8eb5eb787f6f6` 检出完整 `docker/` 目录，并使用官方 `docker-compose.yml` 和 `run.sh`。它提供 PostgreSQL、用户认证、REST/GraphQL API、实时订阅、文件存储、Edge Functions 和 Web Dashboard。

典型应用场景包括：

- **快速搭建后端服务** — 为移动/Web 应用提供数据库 + API + 认证的完整后端基础设施
- **AI 应用开发** — 利用 pgvector 向量搜索扩展，构建 RAG 和语义搜索应用
- **实时数据应用** — 通过 WebSocket 实时订阅数据库变更
- **企业内部应用平台** — 自建后端即服务（BaaS）平台，数据完全自主可控

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 ECS 实例（推荐 8vCPUs 16GiB），运行官方默认的 11 个服务
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网 Dashboard 和 API 访问
- 1 x VPC 和子网，用于网络隔离

#### 组件架构

```
Kong (API Gateway) ← 统一入口 :8000
├── Studio (Web 管理面板，由 HTTP Basic Auth 保护)
├── GoTrue / auth (认证服务)
├── PostgREST / rest (REST API)
├── Realtime (WebSocket 实时订阅)
├── Storage (文件存储)
├── imgproxy (图片处理)
├── postgres-meta / meta (数据库管理 API)
├── Edge Runtime / functions (Edge Functions)
├── PostgreSQL / db
└── Supavisor (连接池)
```

候选模板使用固定官方 Compose 文件中的明确镜像标签：

| 服务 | 固定镜像 |
|------|----------|
| Studio | `supabase/studio:2026.07.07-sha-a6a04f2` |
| Kong | `kong/kong:3.9.1` |
| Auth | `supabase/gotrue:v2.189.0` |
| REST | `postgrest/postgrest:v14.12` |
| Realtime | `supabase/realtime:v2.102.3` |
| Storage | `supabase/storage-api:v1.60.4` |
| imgproxy | `darthsim/imgproxy:v3.30.1` |
| Meta | `supabase/postgres-meta:v0.96.6` |
| Functions | `supabase/edge-runtime:v1.74.0` |
| Database | `supabase/postgres:17.6.1.136` |
| Supavisor | `supabase/supavisor:2.9.5` |

可选 Analytics 和 Vector 日志服务默认不启用。PostgreSQL 的 `pgvector` 扩展与可选 Vector 日志服务不是同一组件。

#### 数据流

1. 开发者/应用通过 Kong API 网关（端口 8000）访问 Supabase 服务
2. 认证请求由 GoTrue 处理，生成 JWT Token
3. 数据请求通过 PostgREST 自动转换为 PostgreSQL 查询
4. 实时订阅通过 WebSocket 推送数据库变更
5. 文件存储通过 Storage 服务持久化到本地卷
6. Edge Functions 由官方 Edge Runtime 服务执行

### 1.3 方案优势

- **与上游一致的部署方式** — 使用不可变官方 commit 中的完整 Docker 目录
- **官方生命周期命令** — 通过随附的 `run.sh` 完成镜像拉取、启停、状态、日志和密钥显示
- **固定镜像与服务集** — 以明确镜像标签运行 11 个默认服务，可选 Analytics/Vector 服务保持禁用
- **内置 PostgreSQL 扩展** — pgvector 向量搜索、pgjwt 认证、PostGIS 地理空间等
- **完整后端能力** — 数据库 + REST API + GraphQL + 认证 + 实时订阅 + 文件存储 + Edge Functions + Dashboard
- **Dashboard 保护与 Snippets 持久化** — Kong 强制 HTTP Basic Auth，Studio SQL Snippets 持久化到主机挂载目录

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 请预留约 10-20 分钟完成 cloud-init、Docker 镜像拉取和服务健康检查。
- 推荐实例规格为 c7n.2xlarge.2（8vCPUs 16GiB）及以上，以支撑全部 11 个服务。
- 系统盘建议 100GB 起步，用于存储 Docker 镜像和数据库数据。
- 候选模板在 8000 端口提供明文 HTTP。HTTP Basic Auth 可阻止未认证访问 Dashboard，但不会加密凭证和业务流量。评估时应限制来源 IP；投入生产前必须在服务前配置 HTTPS/TLS 并实施适当的网络访问控制。
- 这是单 ECS 部署。数据库、Storage 和 SQL Snippets 均保存在 ECS 系统盘，不具备高可用性。
- 可选 Analytics 和 Vector 日志服务不在默认部署范围内。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| ECS 实例 | 计费模式：按需计费<br>区域：中国-香港（ap-southeast-1）<br>规格：c7n.2xlarge.2<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 0.20 美元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 美元 |
| **合计** | — | — | **约 0.20 美元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| ECS 实例 | 计费模式：包年包月<br>区域：中国-香港（ap-southeast-1）<br>规格：c7n.2xlarge.2<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 146.00 美元 |
| 弹性公网 IP EIP | 计费模式：按流量计费<br>线路：动态 BGP<br>带宽：300Mbit/s | 1 | 按实际流量计费 |
| **合计** | — | — | **约 146.00 美元/月 + EIP 流量费** |

---

## 3. 实施步骤

### 3.1 准备工作

#### 3.1.1 创建 rf_admin_trust 委托（可选）

步骤 1 打开华为云控制台，将鼠标悬停在右上角用户名，打开"统一身份认证"。

步骤 2 进入"委托"页面，搜索 `rf_admin_trust`。

如已存在该委托，跳过以下创建步骤。
如不存在，请按以下步骤创建。

步骤 3 单击"创建委托"，委托名称填写 `rf_admin_trust`，委托类型选择"云服务"，云服务选择 `RFS`，单击"完成"。

步骤 4 单击"立即授权"。

步骤 5 搜索并选择 `Tenant Administrator`，单击"下一步"。

步骤 6 授权范围选择"所有资源"，单击"确定"完成配置。

步骤 7 确认委托列表中出现 `rf_admin_trust`。

----结束

### 3.2 快速部署

> 本节帮助您高效完成 Supabase 方案部署，请按以下步骤进行一键部署。

步骤 1 单击"开始部署"，跳转至 RFS 资源编排控制台。

步骤 2 单击"下一步"，确认基础配置，并设置 ECS 密码和数据库密码。

**表 3-1 配置参数**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| solution_name | 解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头 | supabase |
| ecs_flavor | 云服务器实例规格，c7n.2xlarge.2（8vCPUs 16GiB）及以上推荐，请根据目标区域可用规格调整 | c7n.2xlarge.2 |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| db_password | PostgreSQL 数据库密码，8-24个字符，支持字母、数字和特殊字符（`~!^*-=_+,`），不支持 `@` | / |
| system_disk_size | 系统盘大小（GB），高IO类型，取值范围：40-1024，Supabase建议100GB起步 | 100 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看 Dashboard 地址和部署日志路径。请预留约 10-20 分钟完成 cloud-init、镜像拉取和健康检查。RFS 资源创建成功不代表应用初始化已经完成。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。

----结束

### 3.3 开始使用

#### 3.3.1 访问 Supabase Dashboard

步骤 1 在浏览器中访问部署输出中提供的 Dashboard 地址：

```
http://<EIP>:8000/
```

> **注意：** 将 `<EIP>` 替换为 RFS 输出中的弹性公网 IP 地址。该地址使用未加密 HTTP，仅应在受控评估环境中使用，生产使用前必须配置 HTTPS。

步骤 2 加载 Studio 前，浏览器必须弹出 HTTP Basic Auth 登录框。Dashboard 用户名保持上游默认值 `supabase`；密码在引导时随机生成，且故意不写入 RFS 输出。仅在 SSH 登录后获取：

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

使用用户名 `supabase` 和命令输出中的 `DASHBOARD_PASSWORD` 登录。不要将命令输出发送到日志、工单或聊天消息。

步骤 3 认证通过后，您可以：

- 查看和管理数据库表
- 配置用户认证（邮箱、OAuth、手机号等）
- 管理文件存储桶
- 查看实时订阅状态
- 执行 SQL 查询
- 创建和管理 Edge Functions

步骤 4 使用官方生命周期辅助脚本验证 Supabase 运行状态：

```bash
# SSH 登录 ECS
ssh root@<EIP>

# 进入官方 Docker 部署目录
cd /opt/supabase

# 查看服务状态或跟踪日志
sh run.sh status
sh run.sh logs

# 服务未就绪时查看 cloud-init/引导进度
tail -n 200 /var/log/supabase-bootstrap.log
```

----结束

#### 3.3.2 获取 API Keys

使用官方辅助脚本显示随机生成的密码和 API 密钥。不要输出完整 `.env` 文件：

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

**表 3-2 API Keys**

| Key | 说明 | 用途 |
|-----|------|------|
| `SUPABASE_PUBLISHABLE_KEY` | 可发布客户端密钥 | 客户端应用，受数据库授权策略限制 |
| `SUPABASE_SECRET_KEY` | 服务端秘密密钥 | 仅用于可信服务端组件，**切勿暴露到客户端** |
| `POSTGRES_PASSWORD` | PostgreSQL 数据库密码 | 数据库连接使用 |
| `DASHBOARD_PASSWORD` | 随机 Dashboard Basic Auth 密码 | 与用户名 `supabase` 一起用于浏览器登录 |
| `S3_PROTOCOL_ACCESS_KEY_ID` / `S3_PROTOCOL_ACCESS_KEY_SECRET` | S3 兼容 Storage 凭证 | 仅用于可信服务端 S3 客户端 |

> **安全提示：** 引导脚本使用官方 `utils/generate-keys.sh --update-env` 和 `utils/add-new-auth-keys.sh --update-env` 生成密钥且抑制输出，然后以 `0600` 权限将 `.env` 保存在权限为 `0700` 的 `/opt/supabase` 目录。在本方案中，`run.sh secrets` 是支持的凭证获取方式。切勿向客户端暴露秘密密钥、数据库密码或 S3 密码。

----结束

#### 3.3.3 官方运维与凭证变更

在 `/opt/supabase` 目录中通过固定版本的官方 `run.sh` 执行生命周期操作：

```bash
cd /opt/supabase
sh run.sh status
sh run.sh restart
sh run.sh stop
sh run.sh start
```

不要手工构造 JWT，也不要直接修改 `.env` 中的单个值。JWT/API 密钥和 PostgreSQL 密码变更会影响多个服务及数据库角色。请先备份数据，再重建资源栈，或遵循该固定上游版本的协同凭证轮换流程。候选模板中的官方密钥生成脚本用于首次引导，不是独立的部署后数据库密码轮换工具。

----结束

#### 3.3.4 SQL Snippets 持久化

固定官方 Compose 文件为 Studio 设置 `SNIPPETS_MANAGEMENT_FOLDER=/app/snippets`，并挂载 `./volumes/snippets:/app/snippets:z`。因此，Studio 中保存的 SQL Snippets 会在容器重启后继续保留于 `/opt/supabase/volumes/snippets`。该目录仍位于单 ECS 系统盘，删除或重建 ECS 前必须备份。

#### 3.3.5 常用服务端点

**表 3-3 Supabase 服务端点**

| 端点 | 说明 | 示例 |
|------|------|------|
| Dashboard | Web 管理面板 | `http://<EIP>:8000/` |
| REST API | 自动生成的 RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | 用户认证 API | `http://<EIP>:8000/auth/v1/` |
| Storage | 文件存储 API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket 实时订阅 | `http://<EIP>:8000/realtime/v1/` |
| Edge Functions | Edge Functions 端点 | `http://<EIP>:8000/functions/v1/` |

----结束

> **安全提示：** 上述示例均使用候选模板当前的明文 HTTP 端点，API 密钥和业务载荷不受传输加密保护。生产使用前必须配置 HTTPS/TLS。由于 Analytics/Vector 服务默认禁用，可选 Analytics 端点不可用。

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

> **注意：**
> - 卸载会释放所有资源（ECS、EIP、VPC、安全组）。
> - **删除前请务必备份 `/opt/supabase/volumes/db/data`、Storage 数据和 `/opt/supabase/volumes/snippets`**，卸载后本地数据将不可恢复。

----结束

---

## 4. 附录

### 4.1 名词解释

| 术语 | 说明 |
|------|------|
| Supabase | 开源的 Firebase 替代品，提供 PostgreSQL 数据库、认证、REST API、实时订阅、文件存储等完整后端服务 |
| PostgreSQL | 开源关系型数据库，Supabase 的核心数据存储引擎 |
| Kong | 开源 API 网关，作为 Supabase 的统一入口 |
| GoTrue | 开源用户认证服务，支持邮箱、OAuth、手机号等多种认证方式 |
| PostgREST | 自动生成 PostgreSQL 数据库的 RESTful API |
| pgvector | PostgreSQL 向量搜索扩展，用于 AI 和语义搜索应用 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |
| JWT | JSON Web Token，用于 API 认证的无状态令牌 |

### 4.2 参考链接

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [固定版本的官方 Docker 部署目录](https://github.com/supabase/supabase/tree/00ecb5305965ff85e1b5757e34a8eb5eb787f6f6/docker)
- [Supabase 自托管指南](https://supabase.com/docs/guides/self-hosting/docker)
- [华为云 RFS](https://support.huaweicloud.com/intl/zh-cn/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|------|---------|
| 2026-07-14 | 新增 `_v6`，与中国站候选版本号同步；删除 `_v5` 候选。 |
| 2026-07-14 | 新增 `_v5`，与中国站候选版本号同步；删除 `_v4` 候选。 |
| 2026-07-07 | 国际站 ap-southeast-1（香港）首次发布。|
| 2026-07-14 | 候选指南对齐固定官方 Docker Compose 部署：11 个固定镜像服务、Basic Auth、官方 `run.sh`、Snippets 持久化，云上验证待完成。 |
| 2026-07-14 | 新增 `_v2` 候选：`charging_period` 校验只引用自身变量以兼容 RFS，删除测试未通过的 `_v1` 候选文件。 |
| 2026-07-14 | 新增 `_v3`：删除数据库密码和 CN 规格格式正则，增加 Base64 与 dotenv 字面量安全处理，删除测试失败的 `_v2` 候选。 |
| 2026-07-14 | 新增 `_v4`：将 Docker APT 密钥和源列表设为 `0644`，修复严格 umask 导致的 `_apt` `NO_PUBKEY`，删除测试失败的 `_v3` 候选。 |
