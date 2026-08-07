# 快速部署 JiuwenSwarm — 部署指南

> **文档类型：** 华为云解决方案实践部署指南
> **模板状态：** 候选 `deploying-jiuwenswarm_v7.tf`，待云测
> **适用区域：** 中国站，华北-北京四（`cn-north-4`）
> **发布日期：** 2026-07-14

> [!IMPORTANT]
> 候选 `v7` 已改用用户提供的官方 Docker Compose 定义，尚待华为云 RFS 云测。公网入口无 TLS 和应用认证，不得用于生产敏感数据。

## 1. 方案概述

本方案使用华为云资源编排服务 RFS，在 `cn-north-4` 一次创建 JiuwenSwarm 标准单机版所需的 6 类资源，并在弹性云服务器 ECS 中使用官方 Dockerfile 和 Docker Compose 构建、启动 JiuwenSwarm。部署过程不要求把模型 API Key 写入模板，模型服务凭证应在部署完成后通过 JiuwenSwarm 界面配置。

JiuwenSwarm 面向需要通过自然语言驱动多 Agent 协作、Skill 和工具调用的开发者与团队。上游项目提供规划、性能和集群三种执行模式；实际可用能力取决于您配置的模型服务、网络连通性和工具权限。

### 1.1 应用场景

- **多智能体协作验证**：在独立云主机中体验多个 Agent 的分工协作与任务执行。
- **开发与工具调用实验**：为代码、文档和自动化任务配置模型与工具，开展非生产验证。
- **Skill 能力实践**：在受控环境中试用、管理和迭代 JiuwenSwarm Skill。

### 1.2 方案架构

RFS 资源栈一次创建以下 6 类资源：

| 资源类型 | 数量 | 用途 |
|---|---:|---|
| 虚拟私有云 VPC | 1 | 提供 `172.16.0.0/16` 私有网络 |
| 子网 | 1 | 提供 `172.16.1.0/24` ECS 子网 |
| 安全组 | 1 | 承载 Web 和 Cloud Shell SSH 入方向规则 |
| 安全组规则 | 2 | 放行官方默认 Web 端口 5173，以及固定 Cloud Shell 出口到 TCP 22 |
| 弹性公网 IP EIP | 1 | 为 ECS 提供公网出口和 Web 入口 |
| 弹性云服务器 ECS | 1 | 运行 Ubuntu 24.04、Docker CE 和 JiuwenSwarm 容器 |

数据流如下：客户端通过上游官方默认地址 `http://<EIP>:5173` 访问 JiuwenSwarm。Compose 将 ECS 的 5173 端口映射到容器 5173，并将数据持久化到 `/opt/jiuwenswarm/jiuwenswarm-data`。Dockerfile 从清华 PyPI 镜像安装构建时可用的 JiuwenSwarm 版本。

### 1.3 方案优势

- **一次堆栈部署**：将 VPC、子网、安全组、安全组规则、EIP、ECS 创建及应用初始化压缩为一次 RFS 资源栈部署。
- **官方部署定义**：内联使用用户提供的官方 Dockerfile 和 Docker Compose，不依赖外部安装脚本。
- **最小凭证暴露**：模板只接收 ECS 密码且标记为敏感变量，不预置模型 API Key。
- **容器化运行**：应用由单一 Compose 服务运行，数据目录映射到 ECS。

### 1.4 约束与安全限制

- 当前只有 RFS 标准单机版，尚未提供高可用、负载均衡、受信任 CA 证书、备份或灾难恢复能力。
- Web 沿用上游官方默认端口 TCP 5173，不提供客户可修改的端口或访问来源参数。该入口没有 TLS 和应用认证，不应承载生产敏感数据；正式公网生产使用前需另行增加可信 TLS、认证和访问控制。
- SSH 端口 22 仅允许模板内固定的 Cloud Shell 出口地址 `121.36.59.153/32`，未提供自定义 SSH 白名单变量。
- ECS 需要访问 Ubuntu 软件源、清华 PyPI 镜像及所选模型服务。网络不可达会导致安装或后续调用失败。
- 上游说明要求 Python 3.11 至 3.13；模板使用 Ubuntu 24.04 的 `python3` 创建虚拟环境。实际解释器版本须在后续回归中持续确认。
- ECS 规格和镜像可用性随区域与账号变化；默认 `x1.4u.8g` 需以创建执行计划结果为准。
- Compose 配置 `restart: unless-stopped`；Docker 恢复后会自动拉起未被人工停止的容器。

## 2. 资源和成本规划

RFS 本身用于编排资源；实际费用来自 ECS、系统盘、EIP 带宽和公网流量等资源。VPC、子网和安全组的具体计费以华为云账单为准。

### 2.1 按需计费

| 华为云服务 | 正式默认配置 | 数量 | 费用说明 |
|---|---|---:|---|
| ECS | `x1.4u.8g`；Ubuntu 24.04；100 GiB 高 IO 系统盘；`postPaid` | 1 | 按实际规格和使用时长计费 |
| EIP | 全动态 BGP；独享带宽 300 Mbit/s；按流量计费、按需付费 | 1 | 按公网 IP、带宽及实际流量规则计费 |
| VPC、子网、安全组 | 模板固定网络配置 | 各 1 | 以产品当前计费规则为准 |

### 2.2 包年包月

当 `charging_mode=prePaid` 时，ECS 按 `charging_unit` 和 `charging_period` 购买；模板中的 EIP 仍固定为 `postPaid` 且按流量计费。

| 华为云服务 | 正式配置 | 数量 | 费用说明 |
|---|---|---:|---|
| ECS | 规格、镜像和系统盘同上；按月 1—9 或按年 1—3 | 1 | 以订单页显示金额为准 |
| EIP | `postPaid`；300 Mbit/s；按流量计费 | 1 | 不随 ECS 切换为包年包月 |

本文档不写入静态金额。请在 [华为云价格计算器](https://www.huaweicloud.com/pricing/) 选择华北-北京四、ECS 规格、系统盘、计费模式、EIP 带宽和预计流量进行实时估算。预估费用仅供参考，最终以实际订单和账单为准。

## 3. 实施步骤

### 3.1 准备工作

1. 使用已实名认证、状态正常且余额充足的华为云账号。
2. 确认账号具有在 `cn-north-4` 创建 RFS、VPC、ECS 和 EIP 等资源的权限；如组织要求使用 RFS 委托，请按组织最小权限策略配置。
3. 准备符合模板校验规则的 ECS root 密码。不要在聊天记录、工单、截图或日志中公开该密码。
4. 确认目标账号可购买 `x1.4u.8g` 或其他至少 4 vCPU、8 GiB 的可用 ECS 规格。
5. 使用候选文件 `practices/openjiuwen/cn/cn-north-4/jiuwenswarm/terraform/deploying-jiuwenswarm_v7.tf`。

### 3.2 快速部署

1. 登录华为云控制台，进入资源编排服务 RFS，在华北-北京四创建资源栈。
2. 上传正式 Terraform 模板，创建执行计划并检查预计创建的资源、规格和费用。
3. 配置全部 8 个标准变量：

| 参数 | 必填 | 默认值 | 规则与说明 |
|---|---:|---|---|
| `solution_name` | 是 | `jiuwenswarm` | 4—24 字符；小写字母开头；仅小写字母、数字、中划线；以小写字母或数字结尾 |
| `ecs_flavor` | 是 | `x1.4u.8g` | 目标区域实际可用规格；推荐 4 vCPU、8 GiB 或更高 |
| `ecs_password` | 是 | 无 | 8—26 位；大写、小写、数字、特殊字符至少三类；敏感变量 |
| `system_disk_size` | 是 | `100` | 40—1024 GiB；高 IO（SAS）系统盘 |
| `bandwidth_size` | 是 | `300` | 1—300 Mbit/s；EIP 固定按流量、按需计费 |
| `charging_mode` | 是 | `postPaid` | `postPaid` 按需或 `prePaid` 包年包月；只作用于 ECS |
| `charging_unit` | 是 | `month` | `month` 或 `year`；仅 `prePaid` 生效 |
| `charging_period` | 是 | `1` | 按月 1—9；按年应填 1—3；仅 `prePaid` 生效 |

4. 确认没有生产 API Key 或其他敏感凭证进入模板参数。
5. 执行资源栈部署。首次启动将安装系统包和固定版本 JiuwenSwarm，耗时受软件源和网络影响。
6. 等待 RFS 显示部署完成，再查看 `access_instructions` 输出。

| 输出 | 含义 | 示例格式 |
|---|---|---|
| `access_instructions` | JiuwenSwarm Web 访问地址和安装日志位置 | `http://<EIP>:5173` |

### 3.3 部署验证

候选 `v7` 尚待实际云测；静态检查不能替代以下回归步骤。

1. 打开 `jiuwenswarm_url`，确认官方默认 Web 端口 5173 可访问。
2. 使用 Cloud Shell 连接 ECS，执行：

```bash
cd /opt/jiuwenswarm
sudo docker compose ps
curl --fail --silent --show-error http://127.0.0.1:5173/ >/dev/null && echo OK
sudo docker compose exec -T jiuwenswarm pip show jiuwenswarm
sudo docker compose logs --tail=200
```

期望容器状态为 `Up`、本机健康检查输出 `OK`，并能显示已安装的 JiuwenSwarm 版本。

3. 在 JiuwenSwarm Web 界面中配置测试专用的模型 API 地址、模型名称和 API Key，保存后执行一条不含敏感数据的测试对话。凭证不得写入 Terraform、cloud-init 日志或公开截图。
4. 重启 ECS 后重复容器状态和页面访问检查，确认 Compose 的 `restart: unless-stopped` 生效。

### 3.4 开始使用

部署验证通过后，在 Web 界面按上游指引配置模型提供商。JiuwenSwarm 支持华为云 MaaS 以及多种 OpenAI 兼容接口；具体可用提供商和参数以容器内实际安装版本的界面为准。

该单机方案允许 Agent 读取、编辑或执行 ECS 上获准的文件与工具。请遵循最小权限原则，只导入测试数据，并审查 Skill、MCP 服务和工具权限后再启用。

### 3.5 故障排查

| 现象 | 检查 | 处理 |
|---|---|---|
| RFS 创建 ECS 失败 | 执行计划、配额、规格库存、账号余额 | 选择 `cn-north-4` 可用规格，补充配额或余额后重试 |
| 页面连接超时 | TCP 5173、安全组、容器状态 | 确认安全组放行端口 5173，并运行 `docker compose ps` |
| 容器未启动 | Compose 日志和 cloud-init | 运行 `cd /opt/jiuwenswarm && sudo docker compose logs --tail=200`，并检查 `/var/log/jiuwenswarm-bootstrap.log` |
| 安装阶段失败 | ECS 到 Ubuntu 源和清华 PyPI 镜像的网络 | 修复 DNS/出口网络后重新创建测试栈；模板内置 3 次 pip 重试 |
| 本机健康检查失败 | 上游默认端口 5173、服务日志 | 对 5173 执行 `curl`，检查端口占用和服务异常 |
| 模型测试失败 | API Key、API Base URL、模型名、出口网络 | 使用测试凭证逐项核对；API Base URL 通常不含 `/chat/completions` 后缀 |
| Cloud Shell 无法 SSH | TCP 22 来源限制 | 确认从华为云 Cloud Shell 发起；模板不开放普通公网 SSH |

> 启动日志可能包含环境和错误上下文。分享日志前必须脱敏，禁止复制密码、Token、API Key、私有地址或业务数据。

### 3.6 快速卸载

1. 如需保留 JiuwenSwarm 数据，先通过受控方式备份 `/var/lib/jiuwenswarm`。删除资源栈会删除 ECS 和系统盘，模板设置了随 ECS 删除磁盘。
2. 进入 RFS 资源栈列表，找到本方案资源栈并选择“删除”。
3. 选择删除资源，在确认框输入 `Delete` 后执行。
4. 确认 ECS、EIP、VPC、子网、安全组和相关规则均已删除，并在费用中心检查是否仍有未释放或待支付资源。

## 4. 上线信息与限制

| 项目 | 当前状态 |
|---|---|
| 候选模板 | `deploying-jiuwenswarm_v7.tf` |
| JiuwenSwarm 版本 | Docker 镜像构建时从 PyPI 获取 |
| 正式无版本模板 | 待候选云测通过后晋升 |
| 正式 RFS 入口 | 未生成 |
| 云上部署验证 | `v7` 待验证 |
| 可上架状态 | 否；公网入口无 TLS 和应用认证，且未生成生产 RFS 入口 |

## 5. 参考资料

- [JiuwenSwarm 上游仓库](https://gitcode.com/openJiuwen/jiuwenswarm)
- [华为云价格计算器](https://www.huaweicloud.com/pricing/)
- [华为云 RFS 用户指南](https://support.huaweicloud.com/usermanual-aos/)
- [删除 RFS 资源栈](https://support.huaweicloud.com/usermanual-aos/rf_04_0007.html)

## 6. 修订记录

| 日期 | 版本 | 修订说明 |
|---|---|---|
| 2026-07-14 | 候选 0.1 | 基于 `deploying-jiuwenswarm_v1.tf` 和 JiuwenSwarm `0.2.2` 生成中国站云测候选文档；明确未云测、HTTP 无认证及 `/32` 白名单限制。 |
| 2026-07-15 | 候选 0.2 | 同步 `v2`：HTTPS 443、自签证书指纹核验、回环应用端口和完整哈希依赖锁；明确仍未云测、未晋升。 |
| 2026-07-15 | 候选 0.3 | 按 SAC/Hermes 模板约定收敛 `v3`：默认 300M 按需 EIP、沿用上游官方默认 5173、全内联安装，并删除客户可改端口、CIDR和依赖锁 URL。 |
| 2026-07-16 | 正式 0.4 | 用户确认 `v4` 云测通过，保留候选并字节级晋升为 `deploying-jiuwenswarm.tf`；生产安全限制保持不变。 |
| 2026-07-29 | 候选 0.6 | 更新到 JiuwenSwarm `0.2.3` 官方安装链路；取消 systemd Service，改由非登录应用用户以普通后台进程启动。 |
| 2026-07-29 | 候选 0.7 | 改用用户提供的官方 Dockerfile 和 Docker Compose；数据持久化到宿主机目录并启用容器自动恢复。 |
