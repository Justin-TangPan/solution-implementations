# Cognee 方案详情

> 文档类型：华为云解决方案实践方案详情
> 适用范围：`cn` / `cn-north-4` / `standard`

## 1. 方案概述

本方案在华北-北京四的单个 VPC 内部署 Cognee。单台 Ubuntu 24.04 ECS 通过 Docker Compose 运行 Cognee 和 PostgreSQL（pgvector）；EIP 绑定 ECS，Cognee API 通过公网 TCP `8000` 访问。LLM 与 Embedding 服务由客户自行提供和配置。

适用于需要快速部署并通过公网访问知识与记忆类应用、且可接受单实例故障域的场景。

## 2. 架构与数据流

```text
Internet
   │ TCP 8000
   ▼
EIP
   │
              ▼
Ubuntu 24.04 ECS（1 台，x1.4u.8g，100 GiB SAS）
  └─ Docker Compose
       ├─ Cognee API
       └─ PostgreSQL + pgvector
          ├─ Docker 卷 cognee_postgres_data
          └─ /var/lib/cognee/{data,system,cache,logs}

客户自有 LLM / Embedding 服务
              ▲  部署后由客户在 ECS 本地配置凭据与连通性
```

模板创建并绑定 EIP，安全组对公网开放 Cognee TCP `8000` 端口；部署完成后使用 `http://<EIP>:8000` 访问服务。

## 3. 已交付内容

| 范围 | 内容 |
|---|---|
| 云资源 | 1 个 VPC（`172.16.0.0/16`）、1 个子网（`172.16.1.0/24`）、安全组、EIP、1 台 ECS |
| 运行时 | Docker Engine、Docker Compose、Cognee 与 PostgreSQL + pgvector 容器 |
| 网络 | API TCP `8000` 对公网开放；SSH TCP `22` 仅允许华为 CloudShell 来源 `121.36.59.153/32` |
| 数据 | PostgreSQL 命名卷 `cognee_postgres_data`；Cognee 数据、系统、缓存与日志目录挂载至 `/var/lib/cognee/` |
| 密钥 | 启动时在 ECS 本地随机生成数据库密码和 JWT 密钥，保存在权限为 `0600` 的 `/opt/cognee/.env` |
| 安全配置 | 启用后端访问控制、认证与 API Key 哈希；禁用本地文件路径、HTTP 请求和 Cypher 查询 |

## 4. 使用与运维边界

- 客户须在 `/opt/cognee/.env` 中配置所选 LLM 和 Embedding 服务所需的变量与凭据，并重启 Compose 服务；模板不创建模型或嵌入服务，也不保存其凭据。
- 服务、PostgreSQL 数据和持久化目录位于同一台 ECS。维护、升级或删除资源栈前，应按自身恢复要求备份数据并验证恢复过程。
- ECS 终止时系统盘设置为不自动删除；删除资源栈后仍须在控制台核对保留磁盘与可能产生的费用。

## 5. 不包含的能力

本标准版不包含 HA、RDS、ELB、TLS、自动备份、跨可用区/跨 Region 容灾，以及 LLM 或 Embedding 服务。方案未给出费用、性能、可用性或恢复时间承诺。

部署操作见 [Cognee 部署指南](Cognee-部署指南_zh.md)。
