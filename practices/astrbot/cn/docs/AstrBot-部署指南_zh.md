# AstrBot——部署指南

> 文档类型：华为云解决方案实践部署指南
> 适用站点与区域：cn（中国站），cn-north-4（华北-北京四）
> 依据：`practices/astrbot/cn/cn-north-4/standard/terraform/deploying-astrbot_v1.tf`、已确认的单节点标准版架构事实、AstrBot `v4.26.7` 官方仓库信息。

## 1. 方案概述

AstrBot 是一个开源的多平台智能体聊天平台，支持 WebUI、聊天界面、插件、知识库、Agent、MCP 和多平台消息接入。本实践交付的是中国站 `cn-north-4` 的 `standard` 单节点模板，使用华为云资源编排服务（RFS）一次性创建 VPC、子网、安全组、EIP 和 1 台 Ubuntu 22.04 ECS，并在 ECS 上通过 Docker Compose 运行 `soulter/astrbot:v4.26.7`。

该模板不内置任何 LLM API、IM 平台或插件凭据，部署完成后由用户在 AstrBot WebUI 中自行配置。当前架构是单 ECS + SQLite 持久化，不提供横向主动-主动高可用。

## 2. 前提条件（prerequisite）

1. 使用具备 RFS、VPC、EIP 和 ECS 权限的华为云账号。
2. 准备可用于登录云服务器的密码参数；该参数属于敏感信息，不得写入模板、日志或工单。
3. 确认可以访问华为云 Docker CE 镜像源、镜像代理，以及 `soulter/astrbot:v4.26.7` 镜像。
4. 部署后由用户自行准备并录入 AstrBot 所需的 LLM、平台和插件配置。
5. 仅允许 CloudShell 来源 `121.36.59.153/32` 访问 SSH `22`；业务端口为 `6185`，直接公网访问。

## 3. 架构与参数

### 3.1 基础架构

```text
互联网 → EIP → Ubuntu 22.04 ECS → Docker Compose → AstrBot v4.26.7
                               └→ /opt/astrbot/data:/AstrBot/data
```

模板固定的基础事实如下：

| 项目 | 取值 |
|---|---|
| 站点 / Region | `cn` / `cn-north-4` |
| 部署形式 | `standard` 单节点 |
| ECS 规格 | `x1.4u.8g` |
| 系统盘 | `100 GiB`，`SAS` |
| VPC | `172.16.0.0/16` |
| 子网 | `172.16.1.0/24` |
| EIP | 按流量计费，带宽 `300 Mbit/s`，`postPaid` |
| 公网入口 | `http://EIP:6185` |
| SSH | 仅 `121.36.59.153/32` |
| 额外端口 | `6199` 不开放 |
| 容器 | `soulter/astrbot:v4.26.7` |
| 运行时策略 | `restart: always`，`no-new-privileges:true`，时区 `Asia/Shanghai` |
| 持久化路径 | `/opt/astrbot/data:/AstrBot/data` |

### 3.2 关键参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `solution_name` | `astrbot` | 资源命名前缀 |
| `ecs_flavor` | `x1.4u.8g` | ECS 规格 |
| `ecs_password` | 空 | 云服务器登录密码，敏感参数 |
| `system_disk_size` | `100` | 系统盘大小，单位 GiB |
| `bandwidth_size` | `300` | EIP 带宽，单位 Mbit/s |
| `charging_mode` | `postPaid` | 按需计费 |
| `charging_unit` | `month` | 仅包年包月时生效 |
| `charging_period` | `1` | 订购周期 |

模板未声明 `llm_api_key`、`platform_token`、`web_access_cidr`，也不接受这些值作为部署参数。

## 4. 部署步骤（deployment）

1. 在 RFS 中上传 `practices/astrbot/cn/cn-north-4/standard/terraform/deploying-astrbot_v1.tf`，选择 `cn-north-4`，填写云服务器密码和其他必填参数。
2. 提交资源栈并等待 ECS 初始化完成。模板会安装 Docker CE、配置华为云镜像源和 registry mirror，然后启动 AstrBot 容器。
3. 首次启动后访问 `http://EIP:6185`。上游行为会把初始密码输出到 Docker logs，部署后应立即查看、登录并修改密码。
4. 在 AstrBot WebUI 中按实际业务需要配置模型提供方、消息平台和插件。
5. 如需保留默认数据，使用 `/opt/astrbot/data` 作为唯一持久化目录；不要把 LLM 或平台凭据写入模板。

## 5. 验证（verification）

1. 确认资源栈状态为成功，ECS 正常运行，EIP 已绑定到实例。
2. 通过浏览器打开 `http://EIP:6185`，确认 AstrBot WebUI 可访问。
3. 使用 Docker 检查容器状态，确认 `astrbot` 容器处于运行中。
4. 核对持久化目录 `/opt/astrbot/data` 已创建，且业务配置会落在该目录。
5. 确认安全组未对外暴露 `6199`，SSH 仅允许 CloudShell 来源访问。

## 6. 卸载（uninstall）

1. 如需保留数据，先备份 `/opt/astrbot/data`。
2. 在 RFS 中删除该资源栈，按创建顺序回收 ECS、EIP、安全组和 VPC 资源。
3. 删除后复核账单和控制台，确认没有残留 EIP、ECS 或磁盘费用。

## 7. 限制与安全责任（limitation）

- 该模板保留直接公网 HTTP 管理入口，属于已接受的中等残余风险，生产使用前应由业务方自行评估。
- 初始密码会按上游行为出现在 Docker logs 中，必须在首次登录后立即修改。
- 当前方案是单节点 SQLite 持久化，不支持横向主动-主动高可用，也不应被写成 HA 方案。
- AstrBot 采用 AGPL-3.0-or-later 许可证，正式商用前应完成许可证合规审查。
- 镜像拉取、外部模型和消息平台连接都依赖运行时网络可达性；模板只保证声明，不保证外部服务可用。

## 8. 总结（summary）

该模板适合快速交付 AstrBot 单节点验证环境，默认只暴露 WebUI 入口 `http://EIP:6185`。如果后续需要私网接入、多节点高可用或更严格的入口收敛，应在新的架构合同中重新设计。
