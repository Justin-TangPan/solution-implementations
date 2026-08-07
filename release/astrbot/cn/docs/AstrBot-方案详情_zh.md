# AstrBot

> 文档类型：华为云解决方案实践方案详情
> 站点与区域：cn（中国站），cn-north-4（华北-北京四）

## 1. 方案概述

AstrBot 是一个开源的多平台智能体聊天平台，面向个人、开发者和团队，提供 LLM 对话、多模态、Agent、MCP、技能、知识库、人格设定、自动上下文压缩、WebUI 和 Web ChatUI 等能力。本实践使用官方仓库 `v4.26.7` 对应的容器镜像，交付中国站 `cn-north-4` 的单节点标准版模板。

## 2. 架构（architecture）

```text
互联网 → EIP:6185 → Ubuntu 22.04 ECS → Docker Compose → soulter/astrbot:v4.26.7
                                     └→ /opt/astrbot/data:/AstrBot/data
```

| 项目 | 事实 |
|---|---|
| 部署形式 | 单 ECS 标准版 |
| 网络 | `172.16.0.0/16` VPC，`172.16.1.0/24` 子网 |
| 入口 | `http://EIP:6185` |
| 安全组 | SSH 仅 `121.36.59.153/32`，业务端口 `6185` 对公网开放，`6199` 不开放 |
| 存储 | `/opt/astrbot/data` 作为持久化目录 |
| 运行方式 | Docker CE + Docker Compose |
| 计费 | EIP 为按流量计费的 `postPaid`，带宽 `300 Mbit/s` |

## 3. 方案优势（advantage）

- **部署链路短：** 一个 RFS 资源栈就能完成网络、EIP、ECS 和应用容器的创建。
- **事实边界清晰：** 模板只声明基础设施和容器启动方式，不预置 LLM、平台或插件凭据，便于后续按需接入。
- **版本固定：** 运行镜像锁定为 `soulter/astrbot:v4.26.7`，便于审阅和复现。
- **数据路径明确：** 业务数据集中在 `/opt/astrbot/data`，迁移和备份路径单一。

## 4. 关键实现事实

| 类别 | 事实 |
|---|---|
| 解决方案名称 | `astrbot` |
| ECS 规格 | `x1.4u.8g` |
| 系统盘 | `100 GiB`，`SAS` |
| Ubuntu 镜像 | `Ubuntu 22.04 server 64bit` |
| 容器策略 | `restart: always` |
| 安全策略 | `no-new-privileges:true` |
| 时区 | `Asia/Shanghai` |
| Docker 来源 | 华为云 Docker CE 镜像源与 registry mirror |
| 入口端口 | `6185` |
| 额外暴露端口 | 无，`6199` 未开放 |

模板中没有 `llm_api_key`、`platform_token`、`web_access_cidr` 等变量；这些配置应在部署完成后由用户在 AstrBot 中自行填写。

## 5. 使用场景

- 个人或团队的多平台聊天机器人初始部署。
- 需要先搭建 WebUI，再逐步接入模型、平台和插件的验证环境。
- 需要知识库、Agent、MCP 和插件能力，但暂不要求多节点高可用的场景。
- 需要保留单一数据目录并控制运维复杂度的单机部署场景。

## 6. 限制与责任（limitation）

- 当前模板是单节点方案，SQLite 持久化意味着它不是主动-主动 HA 架构。
- 直接公网 HTTP 访问是模板默认设计，属于接受风险，不等于安全最优解。
- 初始密码会按上游行为出现在 Docker logs 中，运维人员必须在首次登录后立即修改。
- 外部模型、消息平台和插件能否连通，取决于用户运行时配置和网络条件，不由模板保证。
- AstrBot 采用 `AGPL-3.0-or-later`，商业使用前应完成许可证审查。

## 7. 总结（summary）

这是一套面向 `cn-north-4` 的标准单机 AstrBot 部署实践，适合快速落地和后续自行接入业务配置。更多部署步骤、验证方法和卸载方式见 [AstrBot 部署指南](AstrBot-部署指南_zh.md)。
