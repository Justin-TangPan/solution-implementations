# Cognee——部署指南

> 文档类型：华为云解决方案实践部署指南
> 适用范围：cn（中国站）、cn-north-4（华北-北京四）、`standard`
> 依据：`cn/cn-north-4/standard/terraform/deploying-cognee.tf`；用户已确认 Cognee v1 云测通过。

## 1. 方案概述

本实践在一个私有 VPC 中创建一台 Ubuntu 24.04 ECS，并通过 Docker Compose 运行 Cognee `v1.4.0` 与 PostgreSQL 17（pgvector）。服务仅提供私网 API；模板不创建 EIP 或公网入口。

Docker 保留官方镜像名 `cognee/cognee` 和 `pgvector/pgvector`，以 digest 固定实际镜像，并将 Docker daemon 的镜像加速器配置为 `https://docker.wangzhou3.top`。该域名是镜像拉取加速器，不是 Compose 镜像地址。

## 2. 前提条件

1. 使用具备 RFS、VPC、ECS 和安全组权限的华为云中国站账号，并在北京四核对配额、`x1.4u.8g` 规格和 Ubuntu 24.04 公共镜像可用性。
2. 准备 ECS `root` 密码。`ecs_password` 为敏感变量，须满足 8–26 位且包含至少三类字符；不得写入模板、版本库、日志或截图。
3. 准备能从同一 VPC 访问 API 的客户端。安全组只允许 `172.16.0.0/16` 访问 TCP `8000`；外部网络不能直接访问。
4. 如需 Cognee 调用 LLM 或嵌入服务，部署后由客户准备相应凭据和该服务的私网/受控网络连通性。本模板不创建模型服务，也不包含任何模型凭据。

## 3. 资源与网络

| 项目 | 模板默认值 |
|---|---|
| Region | `cn-north-4` |
| VPC / 子网 | `172.16.0.0/16` / `172.16.1.0/24` |
| ECS | 1 台 Ubuntu 24.04，`x1.4u.8g`（4 vCPU、8 GiB） |
| 系统盘 | SSD，100 GiB；同时承载容器、数据库卷和 Cognee 持久化目录 |
| 计费 | `postPaid`（按需） |
| API | TCP `8000`，仅 `172.16.0.0/16` |
| 运维 SSH | TCP `22`，仅 `121.36.59.153/32`（华为 CloudShell） |
| 公网 | 不创建 EIP，不提供公网入口 |

启动脚本将 PostgreSQL 数据保存在 Docker 命名卷 `cognee_postgres_data`，并将 Cognee 的 data、system、cache、logs 目录挂载到 `/var/lib/cognee/`。数据库密码和 JWT 密钥在 ECS 本地随机生成，写入 `/opt/cognee/.env`，权限为 `0600`；它们不作为 Terraform 变量或状态内容交付。

## 4. 部署步骤

1. 在 RFS 创建资源栈，上传 `practices/cognee/cn/cn-north-4/standard/terraform/deploying-cognee.tf`，区域选择 `cn-north-4`。
2. 设置 `solution_name` 和敏感参数 `ecs_password`。可按需要调整 `ecs_flavor`、`system_disk_size`、`charging_mode`、`charging_unit`、`charging_period`；先审阅执行计划中的资源、规格和计费项。
3. 提交资源栈，等待 ECS 的 cloud-init 完成。启动过程会安装 Docker、设置镜像加速器、拉取固定 digest 的官方镜像、生成本地 `.env` 并启动 Compose 服务。
4. 通过允许的 CloudShell 来源 SSH 到 ECS 后，检查启动日志和服务状态：

```bash
sudo tail -n 100 /var/log/cognee-bootstrap.log
cd /opt/cognee
sudo docker compose ps
sudo docker compose exec -T cognee curl -fsS http://localhost:8000/health
```

5. 从 `172.16.0.0/16` 内的客户端访问 `http://<ECS 私网 IP>:8000/health`。该端点可用是服务就绪的最小检查；请不要通过放宽安全组把端口 `8000` 暴露到公网。

## 5. 注入 LLM 与嵌入凭据

初始 `.env` 只包含数据库和安全运行参数。客户在选定模型或嵌入服务后，按该服务和 Cognee 版本要求将所需变量加入 `/opt/cognee/.env`；不要把凭据写入 Terraform、Compose 文件、Shell 历史或日志。

```bash
sudoedit /opt/cognee/.env
sudo chmod 0600 /opt/cognee/.env
cd /opt/cognee
sudo docker compose up -d
sudo docker compose exec -T cognee curl -fsS http://localhost:8000/health
```

只允许受信任的管理员读取该文件。修改后如需排障，使用 `docker compose ps` 和服务日志确认状态，避免把 `.env` 内容复制到工单。

## 6. 升级、备份与卸载

本模板以 digest 锁定 Cognee 和 PostgreSQL 镜像，未提供自动升级。升级前应在隔离环境验证目标版本与现有数据的兼容性，备份数据并制定回退步骤；不要直接将镜像标签替换为未验证版本。

模板不创建高可用资源、异地副本或自动备份。进行 ECS 维护、升级或删除前，客户必须按自身恢复目标备份 `cognee_postgres_data` 及 `/var/lib/cognee/` 下的持久化目录，并在非生产环境演练恢复。

卸载前先确认备份可恢复。删除 RFS 资源栈会删除栈内计算和网络资源；ECS 设置了 `delete_disks_on_termination = false`，系统盘不会随实例终止自动删除。请在控制台核对保留系统盘中的数据、按需保留或手动清理，并确认没有遗留费用。

## 7. 限制与安全责任

- 这是单 ECS 标准版，不提供 HA、跨可用区或跨 Region 容灾。
- API 的可达性依赖私有 VPC 路由和安全组；没有 EIP、域名、TLS 终止或公网访问配置。
- 模板启用后端访问控制、认证和 API Key 哈希，且禁用本地文件路径、HTTP 请求和 Cypher 查询；客户仍须按组织策略管理账号、API Key、模型凭据、日志和备份。
- 用户已确认 `v1` 完成云测，但该结果不替代当前账号、配额、镜像加速连通性或模型外部依赖的再次验证。

有关架构边界见 [Cognee 方案详情](Cognee-方案详情_zh.md)。
