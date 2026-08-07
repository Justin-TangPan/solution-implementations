# 部署 Supabase — 开源 Firebase 替代 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **文档版本：** 02
> **发布日期：** 2026-07-14

---

## 1. 方案概述

### 1.1 应用场景

本方案在华为云 Flexus X 实例上通过 Docker Compose 一键部署 Supabase — 开源的 Firebase 替代品。提供 PostgreSQL 数据库、用户认证、自动生成 REST/GraphQL API、实时数据订阅、文件存储和 Edge Functions 等完整后端服务。正式模板直接使用 Supabase `v1.26.07` 的官方 `docker/` 目录，固定到上游提交 [`949a57d2854b7fcadc0d621cb7fffa167506d581`](https://github.com/supabase/supabase/tree/949a57d2854b7fcadc0d621cb7fffa167506d581/docker)，避免上游滚动更新造成部署结果漂移。

典型应用场景包括：

- **快速搭建后端服务** — 为移动/Web 应用提供数据库 + API + 认证的完整后端基础设施
- **AI 应用开发** — 利用 pgvector 向量搜索扩展，构建 RAG 和语义搜索应用
- **实时数据应用** — 通过 WebSocket 实时订阅数据库变更
- **企业内部应用平台** — 自建后端即服务（BaaS）平台，数据完全自主可控

### 1.2 方案架构

#### 单机部署

图 1-1 单机部署架构图

本方案部署以下资源：

- 1 x 华为云 Flexus X 实例（推荐 8vCPUs 16GiB），运行 11 个 Supabase 官方默认服务
- 1 x 弹性公网 IP（EIP）关联至 ECS，提供公网 Dashboard 和 API 访问
- 1 x VPC 和子网，用于网络隔离

#### 组件架构

正式模板启用固定上游提交中的 11 个官方默认服务，并使用该提交固定的官方镜像版本，不使用 `latest` 标签：

| Compose 服务 | 固定镜像 | 功能 |
|-------------|----------|------|
| `studio` | `supabase/studio:2026.07.07-sha-a6a04f2` | Web 管理面板 |
| `kong` | `kong/kong:3.9.1` | API 网关和端口 `8000` 统一入口 |
| `auth` | `supabase/gotrue:v2.189.0` | 用户认证 |
| `rest` | `postgrest/postgrest:v14.12` | REST API |
| `realtime` | `supabase/realtime:v2.102.3` | WebSocket 实时订阅 |
| `storage` | `supabase/storage-api:v1.60.4` | 文件存储 |
| `imgproxy` | `darthsim/imgproxy:v3.30.1` | 图片处理 |
| `meta` | `supabase/postgres-meta:v0.96.6` | 数据库管理 API |
| `functions` | `supabase/edge-runtime:v1.74.0` | Edge Functions |
| `db` | `supabase/postgres:17.6.1.136` | PostgreSQL 数据库 |
| `supavisor` | `supabase/supavisor:2.9.5` | 数据库连接池 |

官方 Compose 中的可选 `analytics` 和 `vector` 层默认不启用，正式模板也不会激活这两个可选服务。

#### 数据流

1. 开发者/应用通过 Kong API 网关（端口 8000）访问 Supabase 服务
2. 认证请求由 GoTrue 处理，生成 JWT Token
3. 数据请求通过 PostgREST 自动转换为 PostgreSQL 查询
4. 实时订阅通过 WebSocket 推送数据库变更
5. 文件存储通过 Storage 服务持久化到本地卷
6. Edge Functions 请求由 Edge Runtime 执行

### 1.3 方案优势

- **成熟开源项目** — Apache-2.0 协议，社区活跃，持续更新
- **官方 Docker Compose 部署** — 完整保留 11 个默认服务，10-15 分钟完成初始化
- **版本可复现** — 固定 Supabase 官方提交和官方镜像标签，不使用滚动的 `latest` 镜像
- **Docker 代理加速** — Compose 保留官方镜像名，国内 ECS 通过 Docker daemon `registry-mirrors` 使用 `docker.wangzhou3.top` 代理加速
- **内置 PostgreSQL 扩展** — pgvector 向量搜索、pgjwt 认证、PostGIS 地理空间等
- **完整后端能力** — 数据库 + REST API + GraphQL + 认证 + 实时订阅 + 文件存储 + Dashboard
- **自动重试机制** — 5 次重试保障镜像拉取成功率

### 1.4 约束与限制

- 部署前需拥有华为云账号并完成实名认证，账户余额充足。
- 若选择包年包月计费，请确保账户余额足够自动扣费，或前往"费用中心 > 待支付订单"手动支付。
- 部署完成后请等待约 10-15 分钟，让 Docker 镜像拉取和容器启动完成。
- 推荐实例规格为 x1.8u.16g（8vCPUs 16GiB）及以上，以支撑 11 个默认服务同时运行。
- 系统盘建议 100GB 起步，用于存储 Docker 镜像和数据库数据。
- 部署过程使用 Supabase 官方工具随机生成 Dashboard 密码、API 密钥和其他内部密钥；请勿继续使用官方示例密钥，也不要自行手工签发 JWT。
- 当前安全组允许公网访问 `8000` 端口，输出地址为未加密的 HTTP。生产环境必须在 Kong 前配置 HTTPS 终止并按需收紧安全组来源，避免登录凭证和业务数据以明文在公网传输。
- `deploying-supabase_v6.tf` 已经用户确认在华为云 CN 环境云测通过，并已字节级晋升为 `deploying-supabase.tf`。国际站 `v6` 仍是未经确认的独立候选，不在本次晋升范围。

---

## 2. 资源和成本规划

> 本方案将部署如下资源，费用仅供参考，实际费用请以华为云官网价格为准。

### 2.1 单机部署

#### 表 2-1 成本预估（按需计费）

| 华为云服务 | 配置 | 数量 | 预估费用（1小时） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：按需计费<br>区域：华北-北京四<br>规格：x1.8u.16g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 0.20 美元 |
| 弹性公网 IP EIP | 计费模式：按需计费<br>线路：动态 BGP<br>带宽：按流量计费<br>大小：300Mbit/s | 1 | 0.00 美元 |
| **合计** | — | — | **约 0.20 美元** |

> 预估费用仅供参考，实际费用取决于具体使用量。详细价格请参考华为云官网。

#### 表 2-2 成本预估（包年包月）

| 华为云服务 | 配置 | 数量 | 预估费用（1个月） |
|-----------|---------|------|-----------------|
| Flexus X 实例 | 计费模式：包年包月<br>区域：华北-北京四<br>规格：x1.8u.16g<br>镜像：Ubuntu 24.04 server 64bit<br>系统盘：高IO \| 100GB | 1 | 约 146.00 美元 |
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
| ecs_flavor | 云服务器实例规格，x1.8u.16g（8vCPUs 16GiB）及以上推荐 | x1.8u.16g |
| ecs_password | 云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种 | / |
| db_password | PostgreSQL 数据库密码，8-24个字符，支持字母、数字和特殊字符（`~!^*-=_+,`），不支持 `@` | / |
| system_disk_size | 系统盘大小（GB），通用型SSD，取值范围：40-1024，Supabase建议100GB起步 | 100 |
| bandwidth_size | 弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300 | 300 |
| charging_mode | 计费模式：postPaid（按需计费）或 prePaid（包年包月） | postPaid |
| charging_unit | 订购周期类型：month（月）或 year（年），仅 prePaid 模式生效 | month |
| charging_period | 订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效 | 1 |

步骤 3 按需配置加密与权限，单击"下一步"。

步骤 4 查看资源栈内容，可选择单击"创建执行计划"预览预估费用，然后单击"直接部署资源栈"。

步骤 5 等待 `Apply required resource success`，在"输出"页签查看连接信息。基础设施创建成功后，请继续等待约 10-15 分钟，让 ECS 内的 Docker 镜像拉取、容器启动和自检完成。

> **注意：**
> - 若账户余额不足，请前往"费用中心 > 充值"进行充值。
> - 若包年包月自动扣费失败，请前往"费用中心 > 待支付订单"手动支付。
> - CN `v6` 已经用户确认完成华为云实际环境端到端云测。若服务未就绪，请先 SSH 登录 ECS 查看 `/var/log/supabase-bootstrap.log`，不要仅依据 RFS 基础设施状态判断应用已启动。

----结束

### 3.3 开始使用

#### 3.3.1 访问 Supabase Dashboard

步骤 1 在浏览器中访问部署输出中提供的 Dashboard 地址：

```
http://<EIP>:8000/
```

> **注意：** 将 `<EIP>` 替换为 RFS 输出中的弹性公网 IP 地址。该地址是未加密的 HTTP，仅适合部署验证；生产环境必须先在 Kong 前配置 HTTPS，再通过 HTTPS 地址登录。

步骤 2 首次访问时，浏览器应弹出 HTTP Basic Auth 登录框。Dashboard 用户名沿用官方配置，默认为 `supabase`；登录密码由官方工具随机生成。只能 SSH 登录 ECS 后执行以下命令获取密码，并应立即妥善保管：

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

在命令输出中找到 `DASHBOARD_PASSWORD`。不要将该输出粘贴到工单、聊天、截图或普通日志中。如果浏览器没有弹出登录框，请确认访问的是 Kong 的 `8000` 端口，而不是绕过 Kong 直接访问 Studio。

步骤 3 登录 Supabase Studio 管理面板后，您可以：

- 查看和管理数据库表
- 配置用户认证（邮箱、OAuth、手机号等）
- 管理文件存储桶
- 查看实时订阅状态
- 执行 SQL 查询

步骤 4 验证 Supabase 运行状态。官方管理入口为 `/opt/supabase/run.sh`，日常操作应优先使用它：

```bash
# SSH 登录 ECS
ssh root@<EIP>
cd /opt/supabase

# 查看服务状态
sh run.sh status

# 查看最近日志；按 Ctrl+C 退出跟踪
sh run.sh logs --tail 50
```

如必须直接执行 Docker Compose 命令，基础文件名是 `/opt/supabase/docker-compose.yml`，不是 `docker-compose.yaml`。

----结束

#### 3.3.2 获取和管理密钥

正式模板在首次部署时自动调用 Supabase 官方 `utils/generate-keys.sh --update-env` 和 `utils/add-new-auth-keys.sh --update-env`，生成 Dashboard 密码、API 密钥和内部认证材料。部署后使用官方 `run.sh` 查看运维所需的密钥子集：

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

不要使用 `cat /opt/supabase/.env` 输出完整环境文件；其中包含不应进入终端录屏、审计日志、工单或聊天记录的内部密钥。

**表 3-2 `run.sh secrets` 输出项**

| Key | 说明 | 用途 |
|-----|------|------|
| `SUPABASE_PUBLISHABLE_KEY` | 可发布 API Key | 客户端应用使用，权限仍需由 RLS 等策略约束 |
| `SUPABASE_SECRET_KEY` | 服务端 Secret API Key | 仅可信服务端使用，**切勿暴露到客户端** |
| `POSTGRES_PASSWORD` | PostgreSQL 数据库密码 | 数据库连接使用 |
| `DASHBOARD_PASSWORD` | Dashboard 登录密码 | 配合默认用户名 `supabase` 完成 HTTP Basic Auth |
| `S3_PROTOCOL_ACCESS_KEY_ID` | S3 兼容接口 Access Key | 访问 Storage 的 S3 兼容接口 |
| `S3_PROTOCOL_ACCESS_KEY_SECRET` | S3 兼容接口 Secret Key | 仅可信服务端保存，切勿公开 |

> **安全提示：** `run.sh secrets` 会在当前终端显示敏感信息。仅在可信 SSH 会话中执行，使用后清理终端滚屏和录屏记录，并将密钥保存到受控的凭据管理系统。

----结束

#### 3.3.3 轮换安全密钥（如需）

不要手工拼接或签发 JWT，也不要直接编辑 `.env` 中相互关联的认证字段。正式模板已带有固定上游提交中的官方密钥工具：

- `utils/generate-keys.sh`：生成整套基础密钥，其中包括数据库和 Dashboard 密码，仅用于了解首次初始化流程；已运行实例上不可直接执行完整重置。
- `utils/add-new-auth-keys.sh`：基于现有认证配置生成官方的新式认证 Key 和 JWKS 配置。
- `run.sh`：用于查看密钥子集以及启动、停止、重建和检查服务。

密钥轮换会影响客户端、服务端、数据库角色和正在运行的容器。生产环境应先备份数据与 `/opt/supabase/.env`，制定客户端 Key 切换和回滚方案，再在维护窗口按照固定提交对应的 [Supabase 官方自托管文档](https://supabase.com/docs/guides/self-hosting/docker) 使用官方工具执行；完成后通过 `sh run.sh recreate` 重建服务并逐项验证。切勿在未同步数据库角色密码的情况下重新生成 `POSTGRES_PASSWORD`。

----结束

#### 3.3.4 SQL Snippets 持久化

正式模板直接使用官方 Compose 中的 Snippets 配置：Studio 容器内管理目录为 `/app/snippets`，并通过 `./volumes/snippets:/app/snippets:z` 持久化到 ECS 的 `/opt/supabase/volumes/snippets`。因此重建 Studio 容器不会丢失已保存的 SQL Snippets。

可通过以下命令检查环境变量、宿主机目录和容器目录：

```bash
ssh root@<EIP>
cd /opt/supabase

sh run.sh printenv studio | grep '^SNIPPETS_MANAGEMENT_FOLDER=/app/snippets$'
test -d volumes/snippets && test -w volumes/snippets && echo "宿主机 Snippets 目录可写"
docker compose exec -T studio sh -c 'test -d /app/snippets && test -w /app/snippets' \
  && echo "Studio Snippets 目录可写"
```

不要把 `SNIPPETS_MANAGEMENT_FOLDER` 设置成宿主机路径；该变量必须使用容器内路径 `/app/snippets`。SQL Snippets 只持久化在当前 ECS 系统盘，删除 RFS 资源栈或 ECS 前应同时备份 `/opt/supabase/volumes/snippets`。

----结束

#### 3.3.5 常用服务端点

**表 3-3 Supabase 服务端点**

| 端点 | 说明 | 示例 |
|------|------|------|
| Dashboard | Web 管理面板，受 HTTP Basic Auth 保护 | `http://<EIP>:8000/` |
| REST API | 自动生成的 RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | 用户认证 API | `http://<EIP>:8000/auth/v1/` |
| Storage | 文件存储 API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket 实时订阅 | `http://<EIP>:8000/realtime/v1/` |

----结束

### 3.4 卸载

步骤 1 在 RFS 控制台中找到本方案创建的资源栈，单击资源栈名称旁的"删除"按钮。

步骤 2 在弹出的确认框中选择"删除资源"，输入 `Delete`，单击"确定"完成卸载。

> **注意：**
> - 卸载会释放所有资源（ECS、EIP、VPC、安全组）。
> - **删除前请务必备份 `/opt/supabase/volumes/db/data` 中的数据库数据**，卸载后数据将不可恢复。
> - 如需保留 SQL Snippets 和 Edge Functions，还应备份 `/opt/supabase/volumes/snippets` 和 `/opt/supabase/volumes/functions`。

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
| Flexus X | 华为云 Flexus X 实例，新一代柔性算力云服务器 |
| RFS | 资源编排服务（Resource Formation Service），华为云的资源编排服务 |
| SWR | 容器镜像服务（SoftWare Repository for Container），华为云的容器镜像仓库 |
| JWT | JSON Web Token，用于 API 认证的无状态令牌 |

### 4.2 参考链接

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [正式模板固定的 Supabase v1.26.07 官方 Docker 提交](https://github.com/supabase/supabase/tree/949a57d2854b7fcadc0d621cb7fffa167506d581/docker)
- [Supabase 自托管指南](https://supabase.com/docs/guides/self-hosting/docker)
- [华为云 RFS](https://support.huaweicloud.com/rfs/)

---

## 5. 修订记录

| 日期 | 修订记录 |
|---------|---------|
| 2026-07-16 | 用户确认 CN `deploying-supabase_v6.tf` 云测通过，保留候选并字节级晋升为 `deploying-supabase.tf`；INTL `v6` 不在本次范围。 |
| 2026-07-14 | 新增 `deploying-supabase_v6.tf` 候选：修复 Docker 在 mirror 配置写入前已启动、`enable --now` 未重载配置的问题；重启后检查运行中 daemon 的 mirror，删除测试失败的 `_v5`。|
| 2026-07-14 | 新增 `deploying-supabase_v5.tf` 候选：删除 cloud-init 的 GitHub 直连依赖，内置并校验固定提交的官方运行资产，渲染后 `user_data` 控制在华为云 ECS 32 KB 限制内；删除测试失败的 `_v4`。|
| 2026-07-14 | 新增 `deploying-supabase_v4.tf` 候选：Docker APT 密钥和源列表显式设为 `0644`，修复 `_apt` 无权读取密钥导致的 `NO_PUBKEY`；删除测试失败的 `_v3`。|
| 2026-07-14 | 新增 `deploying-supabase_v3.tf` 候选：删除 `db_password` 的字母数字正则和 CN 规格格式正则，使用 Base64 和 `.env` 字面量引用安全传递特殊字符；删除测试失败的 `_v2`。|
| 2026-07-14 | 新增 `deploying-supabase_v2.tf` 候选：将 `charging_period` 的校验改为仅引用自身变量，修复 RFS `Failed to init workflow due to bad template` 错误；删除测试未通过的 `_v1` 文件。|
| 2026-07-14 | 同步 `deploying-supabase_v1.tf` 候选：固定官方 Docker 提交及镜像版本，启用完整 11 个默认服务和 Edge Functions，默认排除可选 Analytics/Vector；补充 Dashboard Basic Auth、官方密钥工具、SQL Snippets 持久化、HTTPS 生产要求及云上待验证声明。|
| 2026-07-09 | 国内模板改为保留官方 Docker Hub 镜像名，并通过 Docker daemon `registry-mirrors` 使用 `docker.wangzhou3.top` 代理，避免代理站未同步自定义镜像路径导致拉取失败。|
| 2026-07-07 | 模板改为全内联 user_data（模式 B），docker-compose/kong.yml/.env 全部在 user_data heredoc 中生成，移除 OBS 脚本分发依赖。|
| 2026-07-02 | 完善部署脚本：修复 JWT 密钥一致性（ANON/SERVICE_ROLE_KEY 改由随机 JWT_SECRET 派生签发）、补全 imgproxy 接线与 meta 健康检查、Terraform 密码参数校验。|
| 2026-06-26 | 首次发布。|
