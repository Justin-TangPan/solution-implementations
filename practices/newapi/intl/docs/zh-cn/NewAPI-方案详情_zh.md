# NewAPI 方案详情

> 状态：已验证的本地发布候选。用户确认本目录保留的标准版和高可用版模板已经过实际云上验证；本仓库未打包或审计标准版引用的外部 OBS 脚本正文。

## 概述

本实践在华为云国际站 `ap-southeast-1`（中国香港）通过 RFS 部署 NewAPI，提供标准版和高可用版。NewAPI 用于管理上游模型渠道、访问令牌、用户权限和用量数据。模板保留原有资源、运行方式和公网入口。

| 变体 | 应用拓扑 | 公网入口 |
|---|---|---|
| 标准版 | 单 ECS + EIP；首次启动从外部 OBS 下载并运行 bootstrap 脚本 | ECS EIP 的 TCP `3000` |
| 高可用版 | ELB + CCE + RDS for MySQL + DCS Redis + NAT | ELB EIP 的 HTTP `80` |

## 资源事实

### 标准版

- VPC：`172.16.0.0/16`；子网：`172.16.1.0/24`。
- 一台 Ubuntu 22.04 ECS，默认规格 `x1.8u.16g`，`100` GB SAS 系统盘。
- 一条按流量计费的 `300` Mbit/s EIP。
- 安全组对公网开放 TCP `3000`；SSH 仅允许 `119.8.185.245/32`。
- `user_data` 下载 `newapi_deploy.sh` 并执行后删除本地脚本；该脚本内容、校验和和供应链审计不属于本交付件。

### 高可用版

- VPC：`192.168.0.0/16`；子网：`192.168.200.0/24`、`192.168.201.0/24` 和 `192.168.202.0/24`。
- 三条 EIP 分别用于 ELB、CCE API Server 和 NAT；ELB 对外监听 HTTP `80`，NAT 通过 SNAT 提供私网出口。
- CCE Turbo 集群版本 `v1.34`，3 个 Ubuntu 24.04 节点；集群 API Server 配置公网 EIP。
- RDS for MySQL 8.0 主备，`100` GB CLOUDSSD；DCS Redis 6.0 主备，默认 `1` GB，自动备份保留 3 天。
- Kubernetes 中创建 `new-api` 命名空间，部署 1 个 Master 和 3 个 Slave Pod，经 ClusterIP Service 和 CCE Ingress 接入 ELB。
- 应用镜像固定解析为 `swr.cn-east-3.myhuaweicloud.com/sac/new-api:v1.0.0-rc.8`；这是模板当前固定来源，不表示镜像位于目标 Region，也不表示上游最新版本。

## 运维与安全边界

- 标准版 TCP `3000` 和高可用版 HTTP `80` 均是公网应用入口。模板未配置 HTTPS 终止或证书；承载会话、密钥或生产流量前，应由运营方在入口层补齐 TLS 和访问控制。
- 高可用版 CCE API Server 使用 EIP，且模板说明部署后如不再需要公网 API 访问可释放该 EIP。运营方应按控制面访问需求限制或撤除公网暴露。
- 标准版依赖外部 OBS bootstrap；部署、变更、故障排查和供应链责任必须以该对象的实际内容和可用性为准。本交付件不能据此复现或审计应用安装步骤。
- 规格、配额、可用区、价格及镜像跨 Region 可达性由创建资源栈时的账号和区域状态决定。

## 计费与适用场景

标准版涉及 ECS、EIP 和流量；高可用版还涉及 CCE 节点、ELB、NAT、RDS、DCS 和三条 EIP。模板默认 `postPaid`，并提供 `prePaid`、`month|year` 与周期参数；实际价格以华为云国际站控制台为准。

适用于已获得上游模型服务授权、需要统一 API、令牌、配额和用量管理的组织。使用者应遵守适用法律、上游服务条款和数据处理要求。

## 交付范围

- Terraform：`standard/terraform/deploying-newapi.tf.json` 与 `ha/terraform/deploying-newapi.tf`。
- 文档：国际站中文和英文的方案详情、部署指南。
- 不包含外部 OBS 脚本正文、其校验和、镜像离线副本或凭证。

## 参考资料

- [NewAPI 官方仓库](https://github.com/QuantumNous/new-api)
- [NewAPI 官方文档](https://docs.newapi.pro/en/docs)
- [华为云资源编排服务](https://www.huaweicloud.com/intl/en-us/product/aos.html)
