# Dify LLM 应用开发平台——部署指南

> 文档类型：华为云解决方案实践部署指南
> 适用站点与区域：cn（中国站），cn-north-4（华北-北京四）
> 依据：`standard`、`css` 与 `ha` 现有 Terraform 模板；用户已确认这些模板曾完成实际云上验证。

## 1. 方案概述

本实践通过华为云资源编排服务（RFS）部署 Dify 社区版，提供三个现有模板：单 ECS 标准版、带 CSS 与模型 ECS 的增强版（`css`），以及 CCE、RDS、DCS、CSS 组成的高可用版（`ha`）。模板通过下载公开 OBS 中的启动脚本或直接声明 Kubernetes 工作负载完成应用安装；OBS 脚本内容不在本仓库，本文不将其未展示的运行行为写成实现事实。

## 2. 前提条件

1. 使用具有 RFS、VPC、EIP、ECS 权限的华为云账号；`ha` 还需要 CCE、ELB、NAT、RDS、DCS、CSS、OBS 及 Kubernetes Provider 所需权限。
2. 在 `cn-north-4` 核对目标规格、可用区和配额。`ha` 需要 CCE 集群、3 个初始节点、ELB、NAT、RDS 主备、DCS 高可用、3 节点 CSS 与 3 个 EIP。
3. 为所有密码变量准备受控凭据；不得写入模板、参数文件、日志或工单。`ha` 的 `obs_bucket` 必须是同区域已有桶，AK/SK 用于上传知识库文件。
4. 上传下列**原有模板**创建 RFS 资源栈：

| 部署方式 | 模板路径 | 默认 Dify 版本 |
|---|---|---|
| 标准版 | `practices/dify/cn/cn-north-4/standard/terraform/deploying-dify.tf.json` | `1.8.1` |
| CSS 增强版 | `practices/dify/cn/cn-north-4/css/terraform/deploying-dify-css.tf.json` | `1.8.1` |
| 高可用版 | `practices/dify/cn/cn-north-4/ha/terraform/deploying-dify-ha.tf` | `1.7.1` |

## 3. 架构与参数

### 3.1 标准版

模板创建 `172.16.0.0/16` VPC、`172.16.1.0/24` 子网、安全组、1 个按流量计费的 EIP 和 1 台 Ubuntu 22.04 ECS。ECS 默认 `x1.8u.16g`、100 GB SAS 系统盘、300 Mbit/s EIP，启动时下载并执行 `dify_search.sh`，默认传入 Dify `1.8.1`。公开 TCP `80`、`443`、`8000`；SSH `22` 仅允许 `121.36.59.153/32`。

必填/常用参数为 `dify_version`、`vpc_name`、`security_group_name`、`ecs_name`、`ecs_flavor`、敏感 `ecs_password`、`system_disk_size`、`bandwidth_size`、`charging_mode`、`charging_unit` 和 `charging_period`。版本仅允许 `1.8.1`、`1.6.0`、`1.4.1`、`1.1.3`、`0.15.8`。

### 3.2 CSS 增强版

除标准版 Dify ECS 外，模板还创建：1 台默认 `x1e.16u.16g` 的 Ubuntu 模型 ECS（100 GB GPSSD、独立 EIP），以及 Elasticsearch `7.10.2` 单节点 CSS（`ess.spec-4u8g`、40 GB `ULTRAHIGH`）。Dify ECS 启动脚本完成后会将其 `.env` 配置为 Elasticsearch 向量存储，并使用 CSS 的 VPC 终端节点 IP 和端口 `9200`。模型 ECS 执行另一个 OBS 安装脚本；公开 TCP `11434`、`9997`，并保留标准版的 `80`、`443`、`8000`。

额外参数为 `css_name` 与 `embedding_reranker_flavor`；其余公共参数与标准版相同。脚本没有在仓库中保存，模型服务的具体镜像、模型、健康接口和启动时长须以实际云测记录和脚本来源为准。

### 3.3 高可用版

模板创建 `192.168.0.0/16` VPC（公网、私网和两个 ENI 子网）、ELB、NAT 网关及 3 个 EIP；CCE Turbo `v1.31` 使用 ENI 网络和默认 3 个 `x1.16u.16g` Ubuntu 24.04 节点。ELB 对外为 HTTP `80`，CCE API 使用 1 个 EIP，NAT 使用 1 个 EIP。数据层包括 PostgreSQL 16 主备 RDS（默认 `rds.pg.x1.2xlarge.4.ha`、100 GB `CLOUDSSD`）、Redis 6.0 高可用 DCS（默认 4 GB）和 Elasticsearch `7.10.2` 三节点 CSS（每节点 `ess.spec-4u8g`、40 GB `ULTRAHIGH`）。DCS 自动备份保留 3 天。

工作负载位于 `dify` 命名空间，包含 sandbox、SSRF proxy、API、worker、web、SearXNG；非 0.x 版本还创建 plugin daemon 和 `dify_plugin` 数据库。`embedding_reranker_flavor` 置空时不创建可选模型 ECS；默认 `x1e.32u.32g`。必须提供 CCE 节点、RDS 管理员、数据库用户、Redis 和可选 ECS 密码，以及同区域 OBS 桶、AK、SK。还必须通过敏感变量提供 `plugin_dify_inner_api_key`、`plugin_daemon_key`、`searxng_secret_key` 与 `sandbox_api_key`；这些值替代模板此前的运行时固定密钥。

> 限制：plugin daemon 使用节点 `hostPath` `/root/dify/app/plugin/storage`。该存储不随 Pod 在节点间迁移；节点替换、调度迁移及恢复流程必须先完成备份与实际演练。该模板还使用 Kubernetes Provider；其行为以已验证模板和云上验证为准。

## 4. 部署步骤

1. 在 RFS 创建资源栈，上传所选模板，选择 `cn-north-4`，并填写该模板声明的变量。先创建执行计划，核对资源、规格、计费周期和实时价格。
2. 密码、AK、SK 和 HA 的四个运行时密钥仅通过 RFS 的敏感参数输入；不保存到本地参数文件。`ha` 的 `obs_bucket` 与资源栈区域保持一致。
3. 提交资源栈并观察事件至完成。标准/CSS 模板输出访问提示为 EIP 的 HTTP 地址；HA 模板输出 ELB EIP 的 HTTP 地址。请以资源栈实际输出为准。
4. 部署完成后先访问 Dify 初始化页面，创建首个管理员并按 Dify 界面配置模型、应用或知识库。模型 Provider 凭据及费用不由本模板创建或承担。

## 5. 验证

1. 在 RFS 事件中确认资源栈完成，并在 VPC、ECS/CCE、ELB、RDS、DCS、CSS 控制台核对资源状态。
2. 使用资源栈输出的实际 URL 完成首次管理员初始化；创建一个非敏感测试应用并执行一次测试调用。
3. CSS 版核对 Dify ECS、模型 ECS 和 CSS 状态；高可用版核对 CCE 节点、`dify` 命名空间工作负载、ELB、RDS、DCS、CSS 与 NAT。不要把内部服务端口直接暴露到公网。
4. 本仓库仅能证明 Terraform 声明；用户确认的历史云测可作为既有模板可行性的证据，但当前账号、区域可售性、外部 OBS 脚本可访问性与运行结果仍应在本次部署中复核。

## 6. 故障排查与卸载

| 现象 | 核对项 |
|---|---|
| 资源栈等待或失败 | RFS 事件、区域配额、规格可售性、IAM 权限与公网下载连通性 |
| 标准/CSS 页面不可达 | EIP、80/443 安全组规则、ECS 状态及资源栈输出；外部 OBS 脚本内容不在本仓库，需从其受控来源排查 |
| CSS 向量能力异常 | CSS 集群状态、VPC 终端节点、9200 内网连通性及 Dify `.env` 中由模板写入的 Elasticsearch 配置 |
| HA 应用不可达 | ELB、HTTP 80、CCE 节点与 `dify` 工作负载、NAT 出站、RDS/DCS/CSS 私网连通性 |
| HA 插件异常或节点迁移后数据缺失 | 检查 plugin daemon `hostPath`，从备份恢复；该路径不是共享持久卷 |

卸载前导出需保留的 Dify 数据、知识库文件及应用配置，并验证恢复方式。然后在 RFS 删除目标资源栈；删除后复核 EIP、OBS 数据、DNS（如自行配置）、备份和其他未随栈删除的资源，避免遗留费用或数据误删。

## 7. 限制与安全责任

- 模板均由用户确认曾实际云测；本指南不把历史验证扩展为 SLA、持续可用性或本次部署成功承诺。
- 标准和 CSS 模板公开 HTTP/HTTPS 与模板列出的附加端口；上线前应按组织安全策略收紧来源、配置 TLS、身份认证、备份与监控。
- CSS 模板将 Elasticsearch `security_mode=false`；其端点应仅经 VPC 和安全组访问，不能对公网开放。
- 固定价格、性能、恢复时间、模型安装明细和外部 OBS 脚本运行细节均无仓库内可核实来源，未在本文承诺。
