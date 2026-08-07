# Cognee 部署指南

> 文档类型：华为云解决方案实践部署指南
> 适用范围：`cn` / `cn-north-4` / `standard`
> 实施依据：`practices/cognee/cn/cn-north-4/standard/terraform/deploying-cognee_v2.tf`

## 1. 部署前准备

1. 准备具有 RFS、VPC、ECS、EIP 和安全组权限的华为云中国站账号，并在 `cn-north-4` 核对配额及 Ubuntu 24.04 公共镜像可用性。
2. 准备 ECS `root` 密码。`ecs_password` 是敏感输入；不要写入模板、代码库、日志或截图。
3. 准备通过 EIP 访问 Cognee API 的客户端。安全组向公网开放 TCP `8000`。
4. 如需使用 Cognee 的模型和嵌入能力，准备客户自有 LLM、Embedding 服务的受控网络连通性及凭据。本模板不创建这些外部依赖。

## 2. 资源与网络

| 项目 | 模板默认值或行为 |
|---|---|
| Region | `cn-north-4` |
| VPC / 子网 | `172.16.0.0/16` / `172.16.1.0/24` |
| ECS | 1 台 Ubuntu 24.04，`x1.4u.8g` |
| 系统盘 | SAS，100 GiB |
| EIP | 创建并绑定 ECS；带宽按流量计费，默认 `300` Mbit/s |
| API | TCP `8000`，公网访问 |
| 运维 SSH | TCP `22`，仅 `121.36.59.153/32`（华为 CloudShell） |
| 计费模式 | 默认 `postPaid`；可选择 `prePaid` |

> EIP 是 Cognee 的公网入口。请通过 `http://<EIP>:8000` 访问服务；数据库、缓存和 SSH 不对公网开放。

## 3. 创建资源栈

1. 在 RFS 控制台创建资源栈，上传 `deploying-cognee_v2.tf`，并选择区域 `cn-north-4`。
2. 设置 `solution_name` 和 `ecs_password`；按需要修改 `ecs_flavor`、`system_disk_size`、`bandwidth_size`、`charging_mode`、`charging_unit`、`charging_period`。
3. 在部署前审阅执行计划中的资源、规格和计费项，然后提交资源栈。
4. 等待 ECS 初始化完成。脚本会安装 Docker、配置镜像加速器、拉取固定 digest 的官方镜像、在 ECS 本地创建 `.env` 并启动 Docker Compose。

## 4. 检查服务

通过允许的 CloudShell 来源登录 ECS 后执行：

```bash
cd /opt/cognee
sudo docker compose ps
sudo docker compose exec -T cognee curl -fsS http://localhost:8000/health
```

然后通过 EIP 访问：

```text
http://<EIP>:8000/health
```

API 已启用后端访问控制与认证；请按 Cognee 的认证机制管理 API Key，并在生产环境使用受控入口与 TLS。

## 5. 配置 LLM 和 Embedding 服务

初始 `/opt/cognee/.env` 包含数据库连接和安全运行参数。根据所选 LLM、Embedding 服务及实际 Cognee 配置要求，在可信管理员会话中补充所需变量和凭据；不要在 Terraform、Compose 文件、Shell 历史或日志中保存这些值。

```bash
sudoedit /opt/cognee/.env
sudo chmod 0600 /opt/cognee/.env
cd /opt/cognee
sudo docker compose up -d
sudo docker compose exec -T cognee curl -fsS http://localhost:8000/health
```

仅允许受信任的管理员读取 `.env`。排障时使用 `sudo docker compose ps` 或 `sudo docker compose logs`，不要输出 `.env` 内容。

## 6. 数据保护、升级与卸载

PostgreSQL 数据保存在 Docker 命名卷 `cognee_postgres_data`，Cognee 持久化目录位于 `/var/lib/cognee/`。模板不提供自动备份、自动恢复或高可用；对 ECS 维护、镜像变更、升级和资源栈删除，应先按组织恢复要求备份这些数据并验证恢复。

镜像以 digest 固定，模板不提供自动升级流程。升级前应在隔离环境验证目标镜像与数据的兼容性，并准备回退方案。

删除资源栈前，确认备份可恢复。ECS 的系统盘不会随实例终止自动删除；请在控制台核对保留的系统盘、按需处理其中的数据，并确认可能的遗留费用。

## 7. 限制与安全责任

- 本方案是单 ECS 标准版，不提供 HA、RDS、ELB、TLS、自动备份或容灾。
- API 通过 EIP 的 TCP `8000` 公网访问；数据库、缓存和 SSH 不向公网开放。公网访问使用明文 HTTP，生产环境应在受控入口终止 TLS。
- 模板生成的数据库密码与 JWT 密钥仅保存在 ECS 本地 `/opt/cognee/.env`；客户负责管理该文件及 LLM、Embedding 凭据。
- 请根据组织安全策略管理 API Key、访问主体、日志、备份与外部模型服务的网络权限。

架构范围见 [Cognee 方案详情](Cognee-方案详情_zh.md)。
