# Mem0 方案详情

> 文档类型：华为云解决方案实践方案详情
> 适用范围：`cn` / `cn-north-4` / `standard`

## 1. 方案概述

本方案在华北-北京四的单个 VPC 内部署 Mem0。单台 Ubuntu 24.04 ECS 通过 Docker Compose 运行 Mem0 API、PostgreSQL（pgvector）和 Mem0 Dashboard；EIP 绑定 ECS，Mem0 API 通过公网 TCP `8888` 访问，Dashboard 通过公网 TCP `3000` 访问。LLM 与 Embedding 服务由客户在部署后通过 Dashboard 或本地配置文件配置。

Mem0（62.6k GitHub Stars，Apache 2.0 许可，Y Combinator S24 孵化）是一个 AI Agent 通用记忆层，为 AI 应用提供持久化、可学习的记忆能力，支持多层级记忆（用户/会话/Agent）、智能检索、实体链接和时间感知查询。

适用于需要为 AI 应用添加持久记忆层、支持个性化交互和上下文感知的场景。

## 2. 架构与数据流

```text
Internet
   │
EIP
   │
Ubuntu 24.04 ECS（1 台，x1.4u.8g，100 GiB GPSSD）
  └─ Docker Compose
       ├─ Mem0 API（FastAPI，:8000，映射公网 :8888）
       ├─ PostgreSQL + pgvector（:5432，仅内部访问）
       └─ Mem0 Dashboard（Next.js，:3000）

客户自有 LLM / Embedding 服务
              ▲  部署后由客户在 Dashboard 或 /opt/mem0/.env 中配置凭据
```

模板创建并绑定 EIP，安全组对公网开放 Mem0 API TCP `8888` 端口和 Dashboard TCP `3000` 端口；部署完成后使用 `http://<EIP>:8888` 访问 API，`http://<EIP>:3000` 访问 Dashboard。

## 3. 已交付内容

| 范围 | 内容 |
|---|---|
| 云资源 | 1 个 VPC（`172.16.0.0/16`）、1 个子网（`172.16.1.0/24`）、安全组、EIP、1 台 ECS |
| 运行时 | Docker Engine、Docker Compose、Mem0 API、PostgreSQL + pgvector、Mem0 Dashboard |
| 网络 | API TCP `8888` 与 Dashboard TCP `3000` 对公网开放；PostgreSQL TCP `5432` 仅内部通信；SSH TCP `22` 仅允许华为 CloudShell 来源 `121.36.59.153/32` |
| 数据 | PostgreSQL 命名卷 `mem0_postgres_data`；Mem0 历史数据命名卷 `mem0_history_data` |
| 密钥 | 启动时在 ECS 本地随机生成数据库密码和 JWT 密钥，保存在权限为 `0600` 的 `/opt/mem0/.env` |
| 安全配置 | 启用 JWT 认证与 API Key 访问控制 |

## 4. 使用与运维边界

- 客户须在 Dashboard 的 Configuration 页面或 `/opt/mem0/.env` 中配置所选 LLM 和 Embedding 服务所需的 API Key（默认为 OpenAI）。模板不创建 LLM 或 Embedding 服务。
- Mem0 使用 OpenAI `gpt-5-mini` 作为默认 LLM，`text-embedding-3-small` 作为默认嵌入模型。可在 Dashboard 中切换为 Anthropic Claude 或 Google Gemini。
- 服务、PostgreSQL 数据和持久化目录位于同一台 ECS。维护、升级或删除资源栈前，应按自身恢复要求备份数据并验证恢复过程。
- ECS 终止时系统盘设置为不自动删除；删除资源栈后仍须在控制台核对保留磁盘与可能产生的费用。
- 生产环境建议：配置 TLS 终止（通过反向代理或 ELB）、定期备份 PostgreSQL 数据、设置请求日志清理策略。

## 5. 不包含的能力

本标准版不包含 HA、RDS、ELB、TLS、自动备份、跨可用区/跨 Region 容灾，以及 LLM 或 Embedding 服务。方案未给出费用、性能、可用性或恢复时间承诺。

部署操作见 [Mem0 部署指南](Mem0-部署指南_zh.md)。
