# NewAPI 部署指南

> 状态：已验证的本地发布候选。用户确认现有模板已完成实际云上验证；请保留原模板行为。标准版安装依赖外部 OBS 脚本，其正文未随本交付件打包或审计。

## 1. 选择模板

在华为云国际站 `ap-southeast-1` 创建 RFS 资源栈时，选择下列一个模板：

| 变体 | 模板 | 使用条件 |
|---|---|---|
| 标准版 | `standard/terraform/deploying-newapi.tf.json` | 单 ECS 部署；接受外部 OBS bootstrap 和公网 TCP `3000` |
| 高可用版 | `ha/terraform/deploying-newapi.tf` | 需要 CCE、RDS、Redis、ELB、NAT 和三条 EIP；接受公网 HTTP `80` 与 CCE API EIP |

不要在同一个 Terraform 目录中同时加载两个模板。

## 2. 部署前核对

1. 确认账户在 `ap-southeast-1` 具备相应资源配额和计费授权。
2. 为 ECS/CCE、MySQL、Redis、`session_secret` 与 `crypto_secret` 输入彼此独立的强随机值；这些敏感参数不得写入文档、日志或源码。
3. 确认可接受模板的公网入口：标准版 TCP `3000`，高可用版 HTTP `80`。模板没有 HTTPS 终止配置。
4. 使用标准版时，确认外部 OBS 对象可按模板地址被 ECS 获取。该对象的脚本正文和哈希未包含在本交付件中，不能在此文档中提供安装步骤或完整性结论。
5. 使用高可用版时，确认目标账号可用 CCE `v1.34`、3 个 Ubuntu 24.04 节点、MySQL 8.0 主备、Redis 6.0 主备、ELB、NAT 和三条 EIP；并确认目标环境可拉取固定镜像 `swr.cn-east-3.myhuaweicloud.com/sac/new-api:v1.0.0-rc.8`。

## 3. 模板参数

### 标准版

| 参数 | 默认值 | 说明 |
|---|---|---|
| `vpc_name` / `security_group_name` / `ecs_name` | `building-a-newapi-llm-gateway-demo` | 新建资源名称 |
| `ecs_flavor` | `x1.8u.16g` | Ubuntu 22.04 ECS 规格 |
| `ecs_password` | 空 | ECS root 密码，敏感 |
| `system_disk_size` | `100` | SAS 系统盘（GB） |
| `bandwidth_size` | `300` | EIP 带宽（Mbit/s），按流量计费 |
| `charging_mode` | `postPaid` | 可选 `postPaid` 或 `prePaid` |
| `charging_unit` / `charging_period` | `month` / `1` | 预付费周期 |

标准版固定 VPC `172.16.0.0/16`、子网 `172.16.1.0/24`，并仅允许 `119.8.185.245/32` 访问 SSH；公网 TCP `3000` 对所有 IPv4 地址开放。

### 高可用版

| 参数 | 默认值 | 说明 |
|---|---|---|
| `resource_name_prefix` | `ha-new-api` | 资源名称前缀 |
| `cce_cluster_flavor` | `cce.s2.small` | CCE Turbo 集群规格 |
| `cce_node_pool_flavor` / `cce_node_pool_count` | `x1.8u.16g` / `3` | Ubuntu 24.04 节点规格和数量 |
| `cce_node_pool_password` | 空 | CCE 节点密码，敏感 |
| `rds_flavor` | `rds.mysql.n1.xlarge.2.ha` | MySQL 8.0 主备规格 |
| `mysql_password` / `mysql_user_password` | 空 | 数据库密码，敏感 |
| `redis_capacity` / `redis_password` | `1` / 空 | Redis 6.0 主备容量（GB）及密码 |
| `session_secret` / `crypto_secret` | 空 | NewAPI 会话与渠道加密密钥，敏感 |
| `charging_mode` / `charging_unit` / `charging_period` | `postPaid` / `month` / `1` | 计费参数 |

高可用版固定 VPC `192.168.0.0/16`，使用 `192.168.200.0/24`、`192.168.201.0/24`、`192.168.202.0/24` 三个子网。RDS 使用 `100` GB CLOUDSSD；Redis 自动备份保留 3 天。应用以 1 个 Master 和 3 个 Slave Pod 运行，ELB 的 HTTP `80` 转发至服务端口 `3000`。

## 4. 创建与验证

1. 在 RFS 控制台选择 `ap-southeast-1`，创建资源栈并上传所选模板。
2. 填写参数，核对资源清单与费用后创建资源栈。
3. 等待资源栈创建完成。标准版访问输出中的 ECS EIP `:3000`；高可用版访问输出中的 ELB EIP 的 HTTP `80`。
4. 高可用版还应在运维侧核对 CCE 节点、RDS、DCS、ELB、Master/Slave Pod 和 `/api/status` 探针状态。

## 5. 运行与卸载

- 标准版故障排查以 ECS 的 cloud-init 日志和外部 OBS 对象可达性为准；本地交付件没有该脚本可供比对。
- 高可用版镜像拉取失败时，核对目标环境到固定 SWR 镜像地址的连通性和权限。
- 在公网端点传输会话、上游 API Key 或生产流量前，运营方应部署 TLS 并施加访问控制。
- 若不再需要高可用版的公网 CCE API 访问，按模板注释释放或限制该 EIP。
- 删除资源栈前导出需要保留的 NewAPI 配置和业务数据；删除后核对 EIP、NAT、ELB、CCE、RDS、DCS 和磁盘的实际保留状态。

## 6. 修订记录

| 日期 | 状态 | 说明 |
|---|---|---|
| 2026-07-21 | verified local-release candidate | 基于保留的已云测模板更新交付文档；明确外部 OBS 脚本未打包或审计。 |
