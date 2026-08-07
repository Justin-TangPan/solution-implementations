# Cognee——方案详情

> 文档类型：华为云解决方案实践方案详情
> 适用范围：cn（中国站）、cn-north-4（华北-北京四）、`standard`
> 交付状态：用户已确认 Cognee `v1` 云测通过。

## 1. 方案概述

Cognee 是面向知识与记忆场景的应用组件。本实践交付其在华为云北京四的最小私网部署：单台 ECS 上用 Docker Compose 运行 Cognee `v1.4.0` 和 PostgreSQL 17（pgvector）。它适用于在现有 VPC 内验证或承载单实例服务；模型与嵌入服务由客户自行接入。

## 2. 架构

```text
同一私有 VPC（172.16.0.0/16）内客户端
                 │ TCP 8000
                 ▼
Ubuntu 24.04 ECS（x1.4u.8g，100 GiB SSD）
  └─ Docker Compose
       ├─ Cognee v1.4.0
       └─ PostgreSQL 17 + pgvector
             ├─ Docker 卷：cognee_postgres_data
             └─ 主机持久化目录：/var/lib/cognee/

外部 LLM / Embedding 服务（客户部署后配置；不由模板创建）
```

ECS 没有 EIP。安全组仅允许 VPC CIDR `172.16.0.0/16` 到 API TCP `8000`，并仅允许华为 CloudShell `121.36.59.153/32` 到 SSH TCP `22`。镜像使用官方名称和固定 digest；Docker daemon 通过 `docker.wangzhou3.top` 加速拉取。

## 3. 实现要点

| 范围 | 已实现内容 |
|---|---|
| 编排 | 一个 RFS/Terraform 模板，单 ECS 标准版 |
| 运行时 | Docker Engine 与 Docker Compose；Compose 包含 `cognee`、`db` 两个服务 |
| 数据 | PostgreSQL Docker 命名卷，以及 `/var/lib/cognee/data`、`system`、`cache`、`logs` 主机目录 |
| 本地密钥 | 数据库密码与 JWT 在 ECS 启动时随机生成，存于 `/opt/cognee/.env`，权限 `0600` |
| API 检查 | `http://localhost:8000/health`；VPC 客户端使用 ECS 私网 IP 的同一路径 |
| 镜像策略 | 官方镜像名 + digest；`docker.wangzhou3.top` 仅作为 Docker daemon mirror |

运行配置启用后端访问控制、认证和 API Key 哈希，并禁用本地文件路径、HTTP 请求和 Cypher 查询。LLM/Embedding 凭据不在模板中：客户在部署后以受限权限更新 `.env` 并重启 Compose 服务。

## 4. 适用边界

- 需要在 VPC 内使用 Cognee API，且可接受单 ECS 故障域的场景。
- 已有或将自行提供受控网络可达的 LLM、Embedding 服务及其凭据的场景。
- 希望以固定镜像内容部署、避免把运行时数据库密码和 JWT 写进 Terraform 状态的场景。

## 5. 不包含的能力

本实践不创建 EIP、ELB、域名、TLS、OBS、RDS、Neo4j、Redis、GPU、模型服务、自动备份、异地副本或高可用集群。它不承诺固定费用、性能指标、恢复时间或模型供应商兼容性。

## 6. 运维与风险

数据与服务同处一台 ECS；实例、系统盘或主机故障会影响服务。模板也未创建备份或恢复自动化。变更、升级、系统维护及资源栈删除前，应先备份 PostgreSQL 命名卷和 `/var/lib/cognee/`，并完成恢复演练。

镜像 digest 防止标签漂移，但首次拉取仍依赖 `docker.wangzhou3.top` 的网络可用性。模型/嵌入服务的凭据与连通性由客户负责；应继续使用权限 `0600` 的 `.env`，不得将其内容提交、上传或记录到日志中。

ECS 终止时模板保留系统盘（`delete_disks_on_termination = false`）。这有助于避免自动删除数据，但也要求卸载后人工核对残留磁盘与费用。

## 7. 交付范围

| 站点 | Region | 变体 | 模板 |
|---|---|---|---|
| cn | `cn-north-4` | `standard` | `practices/cognee/cn/cn-north-4/standard/terraform/deploying-cognee.tf` |

部署、凭据注入、验证和卸载步骤见 [Cognee 部署指南](Cognee-部署指南_zh.md)。
