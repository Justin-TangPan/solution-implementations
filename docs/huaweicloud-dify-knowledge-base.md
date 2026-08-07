# 华为云 Dify-LLM 应用开发平台 — 高保真综合知识库文档

> **历史网页快照。** 内容、价格和页面状态固定于生成日期，不是实时事实源，也不定义当前
> Dify Practice 的部署或质量状态。正式范围见 `project.config.json`，当前实现见 `practices/dify/`。

> **文档版本**：v1.0  
> **生成日期**：2026-06-17  
> **数据来源**：华为云官网实时爬取  
> **覆盖范围**：中国站详情页、中国站文档、国际站英文详情页、国际站英文文档、国际站中文文档

---

## 目录

- [第一部分：板块梳理与定位](#第一部分板块梳理与定位)
- [第二部分：中国站详情页](#第二部分中国站详情页)
- [第三部分：中国站文档（全量）](#第三部分中国站文档全量)
- [第四部分：国际站英文详情页](#第四部分国际站英文详情页)
- [第五部分：国际站英文文档（全量）](#第五部分国际站英文文档全量)
- [第六部分：国际站中文详情页](#第六部分国际站中文详情页)
- [第七部分：国际站中文文档（全量）](#第七部分国际站中文文档全量)
- [第八部分：六板块差异对比总表](#第八部分六板块差异对比总表)

---

## 第一部分：板块梳理与定位

| 序号 | 板块名称 | 站点 | 语言 | URL 模式 | 定价货币 | 部署区域 |
|------|----------|------|------|----------|----------|----------|
| 1 | **中国站详情页** | `huaweicloud.com` | 简体中文 | `/solution/implementations/building-a-dify-llm-application-development-platform.html` | CNY（人民币） | 华北-北京四 |
| 2 | **中国站文档** | `support.huaweicloud.com` | 简体中文 | `/dify-aislt/dify_*.html` | CNY（人民币） | 华北-北京四 |
| 3 | **国际站英文详情页** | `huaweicloud.com/intl/en-us/` | 英文 | `/intl/en-us/solution/implementations/bdadp.html` | USD（美元） | 亚太-曼谷等 10 个区域 |
| 4 | **国际站英文文档** | `support.huaweicloud.com/intl/en-us/` | 英文 | `/intl/en-us/dify-aislt/dify_*.html` | USD（美元） | 亚太-曼谷 |
| 5 | **国际站中文详情页** | — | 简体中文 | 内容同中国站详情页 | CNY | 华北-北京四 |
| 6 | **国际站中文文档** | `support.huaweicloud.com/intl/zh-cn/` | 简体中文 | `/intl/zh-cn/dify-aislt/dify_*.html` | USD（美元） | 亚太-曼谷 |

### 说明

- **国际站中文详情页**：国际站无独立的中文详情页，直接跳转/内容同中国站详情页。
- **国际站中文文档**：有独立的中文文档站（`support.huaweicloud.com/intl/zh-cn/`），内容框架与中国站文档一致，但**区域使用亚太-曼谷、定价货币为 USD**，部分术语和内容存在差异。
- **中国站文档 vs 国际站中文文档**：虽然语言同为简体中文，但面向的客户群体不同（国内客户 vs 海外中文客户），因此区域、定价、部分服务配置存在差异。

---

## 第二部分：中国站详情页

> **URL**：https://www.huaweicloud.com/solution/implementations/building-a-dify-llm-application-development-platform.html  
> **语言**：简体中文  
> **定价**：人民币（CNY）  
> **部署区域**：华北-北京四

### 2.1 页面定位

华为云官方解决方案实践页面，主题为"快速搭建Dify-LLM应用开发平台"，面向希望私有化部署Dify的用户群体。

### 2.2 核心价值主张

帮助用户在华为云上部署Dify平台，实现"快速私有化部署开箱即用的Dify LLM应用开发平台"，使开发者能快速搭建生产级生成式AI应用。代码能力弱的人群也可上手，"知识库和对话数据均隔离保存以确保数据安全"。

**行动入口**：
- 立即部署（单机版）
- 部署指南
- 方案咨询

**适用客户**：
- 初创企业加速AI产品开发
- 中小企业低代码构建AI应用
- 大企业灵活扩展AI平台

### 2.3 方案优势（三大核心）

| 优势 | 说明 |
|------|------|
| **多样化产品组合** | 根据业务并发、可用性需求和部署成本差异，组合不同云服务，提供三种全覆盖部署方案 |
| **开发运维友好** | 一键部署后，即使运营、产品经理等代码能力较弱的人群也能快速构建原型 |
| **严格保护数据隐私** | 私有化部署保证知识库、对话数据均保存在环境隔离的资源实例中 |

### 2.4 架构与部署（三种方案）

#### 方案一：社区版单机版
- **费用**：2~5元（按需：Flexus 0.95元/小时，EIP 0.80元/GB）
- **时长**：5分钟
- **组件**：Flexus云容器X实例、EIP、安全组

#### 方案二：知识库搜索增强版
- **费用**：6~12元（Flexus 3.3元/小时，CSS 1.3元/小时，EIP 0.80元/GB）
- **时长**：10分钟
- **组件**：Flexus云容器X实例（Dify核心应用）、Flexus云容器X实例（Embedding/Reranker）、EIP、CSS、安全组

#### 方案三：CCE容器高可用版
- **费用**：35~70元（各资源累积约35元/小时）
- **时长**：15分钟
- **组件（11项）**：EIP、ELB、NAT网关、FlexusX集群（5个核心插件+Embedding/Reranker）、CCE、安全组、OBS、DCS（Redis）、RDS for PostgreSQL（主备跨AZ）、CSS（OpenSearch）

### 2.5 应用场景（四大场景）

| 场景 | 说明 |
|------|------|
| **企业级知识库问答（RAG）** | Dify知识库上传文档，Q&A模式实现高精度检索，构建私有AI助手 |
| **多智能体协作工作流** | 工作流编排拆解任务，如文案撰写、HTTP节点调用API合成海报，实现自动化 |
| **自动化内容营销与自媒体助手** | 搭建小红书文案生成器，模板变量批量生成风格化文案，自动推送至企业微信/Slack |
| **连接业务系统的AI代理** | Dify MCP模式让Agent接入CRM/ERP等系统，销售助手实时查询库存订单 |

### 2.6 关联解决方案实践

1. **数字人交互智能问答解决方案**：基于MetaStudio、ModelArts Studio和Dify快速部署数字人交互服务
2. **快速体验智能问数**：基于Dify + DeepSeek-R1构建，实现自然语言→数据查询→分析→可视化
3. **快速部署MCP SSE服务器**：基于Flexus云服务器X实例部署MCP SSE服务器

### 2.7 页脚信息

- 售前咨询热线：950808转1
- 邮箱：sales@huaweicloud.com
- 备案：黔ICP备20004760号-14

---

## 第三部分：中国站文档（全量）

> **根URL**：https://support.huaweicloud.com/dify-aislt/  
> **语言**：简体中文  
> **定价货币**：人民币（CNY）  
> **最后更新**：2026-05-21

### 文档结构总览

| 页面 | URL | 最后更新 |
|------|-----|----------|
| 方案概述 | `dify_01.html` | 2026-05-21 |
| 资源和成本规划 | `dify_02.html` | 2026-05-21 |
| 实施步骤（导航页） | `dify_03.html` | — |
| 准备工作 | `dify_04.html` | 2026-05-21 |
| 快速部署 | `dify_05.html` | 2026-05-21 |
| 开始使用 | `dify_06.html` | 2026-05-21 |
| 快速卸载 | `dify_07.html` | 2026-05-21 |
| 附录 | `dify_08.html` | 2026-05-21 |
| 修订记录 | `dify_09.html` | 2026-05-21 |

### 3.1 方案概述

#### 3.1.1 应用场景

支持快速部署三种版本的Dify LLM应用开发平台：
1. **社区单机版**
2. **知识库搜索增强版**
3. **CCE容器高可用版**

同时支持将Dify中创建的文档知识库挂载到华为云对象存储服务OBS桶。

> Dify 是一款开源的大语言模型(LLM)应用开发平台，融合了后端即服务（BaaS）和 LLMOps 的理念，使开发者能快速搭建生产级的生成式AI应用。

#### 3.1.2 方案架构（三张架构图）

##### 社区版单机部署 — 资源清单

| 资源 | 数量 | 用途 |
|------|:----:|------|
| Flexus云服务器X实例 | 1台 | 搭建Dify-LLM应用开发平台 |
| 弹性公网IP EIP | 1个 | 关联FlexusX，提供公网访问 |
| 安全组 | 1个 | 安全防护 |

##### 知识库搜索增强版 — 资源清单

| 资源 | 数量 | 用途 |
|------|:----:|------|
| Flexus云服务器X实例 | 1台 | 搭建Dify-LLM应用开发平台 |
| Flexus云服务器X实例 | 1台 | 部署Embedding (bge-m3) 及 Reranker (bge-reranker-v2-m3) |
| 弹性公网IP EIP | 2个 | 公网访问 |
| 云搜索服务CSS | 1个 | OpenSearch集群，提供在线分布式搜索及语义搜索 |
| 安全组 | 1个 | 安全防护 |

##### CCE容器高可用版 — 资源清单

| 资源 | 数量 | 用途 |
|------|:----:|------|
| Flexus云服务器X实例 | 3台 | 安装部署Dify 5个核心插件 + Embedding及Reranker模型 |
| 云容器引擎CCE Turbo | 1个 | 纳管上述3台FlexusX为容器集群Node节点 |
| Flexus云服务器X实例 | 1台 | 部署Embedding及Reranker模型 |
| 弹性公网IP EIP | 3个 | 公网访问 |
| 弹性负载均衡ELB | 1个 | 绑定EIP，流量分发 |
| NAT网关 | 1个 | 绑定EIP，SNAT规则 |
| 对象存储服务OBS | 1个 | Dify知识库挂载 |
| 分布式缓存Redis®版 | 1个 | 兼容Redis，高性能NoSQL |
| 云数据库RDS for PostgreSQL | 1个 | 主备分区部署，跨AZ容灾 |
| 云搜索服务CSS | 1个 | OpenSearch集群 |
| 安全组 | 4个 | 安全防护 |

#### 3.1.3 方案优势

- **成本优化**：高性价比云服务器，按需选择规格，支持自动扩展
- **高可用性**：通过CCE、RDS for PostgreSQL、CSS OpenSearch部署
- **一键部署**：一键即可完成云服务资源创建及Dify平台搭建

#### 3.1.4 约束与限制

1. 需注册华为账号并开通华为云，完成实名认证，账号不能处于欠费或冻结状态
2. 包年包月模式需确保账户余额充足以便自动支付
3. 若选用IAM委托权限部署资源，需确保华为云账号有IAM的足够权限

---

### 3.2 资源和成本规划

#### 方案一：社区版单机部署

**按需计费（月预估）**

| 资源 | 配置 | 数量 | 月预估费用 |
|------|------|:----:|:----------:|
| VPC | 华北-北京四，172.16.0.0/16 | 1 | 0.00元 |
| 子网 | 172.16.1.0/24 | 1 | 0.00元 |
| 安全组 | 开放ping、端口22、端口80 | 1 | 0.00元 |
| Flexus云服务器X实例 | x1.8u.16g, Ubuntu 22.04, 高IO 100GB | 1 | **683.28元** |
| 弹性公网IP EIP | 动态BGP, 按流量, 300Mbit/s | 1 | 0.80元/GB |
| MaaS tokens（可选） | DeepSeek-V3等 | — | 按量计费 |

> **合计**：683.28元 + EIP费用 + MaaS tokens费用

**包年包月（月预估）**：467.00元 + EIP费用 + MaaS tokens费用

#### 方案二：知识库搜索增强版

**按需计费（月预估）**：**3,324.96元** + EIP费用 + MaaS tokens费用

| 资源 | 月预估费用 |
|------|:----------:|
| Flexus云服务器X实例（Dify应用） | 683.28元 |
| Flexus云服务器X实例（知识库，性能模式开启） | 1,686.96元 |
| 云搜索服务CSS（4u8g, 40GB, 单节点） | 954.72元 |
| EIP | 0.80元/GB |

**包年包月（月预估）**：**2,271.74元** + EIP费用 + MaaS tokens费用

#### 方案三：CCE容器高可用版

**按需计费（月预估）**

| 资源 | 配置 | 数量 | 月预估费用 |
|------|------|:----:|:----------:|
| VPC | 192.168.0.0/16 | 1 | 0.00元 |
| 子网 | 4个（192.168.1.0/24 ~ 192.168.4.0/24） | 4 | 0.00元 |
| 安全组 | 华北-北京四 | 4 | 0.00元 |
| FlexusX实例（工作节点） | x1.16u.16g, 高IO 40GB+100GB | 3 | **3,064.18元** |
| FlexusX实例（管理节点，性能模式开启） | x1e.32u.32g, 通用型SSD 40GB | 1 | **3,262.18元** |
| 弹性公网IP | 动态BGP, 按流量, 300Mbit/s | 3 | 0.80元/GB |
| 对象存储服务OBS | 多AZ标准存储，私有桶 | 1 | 详见账单 |
| 云容器引擎CCE | cce.s2.small（50节点） | 1 | **2,095.20元** |
| 分布式缓存服务Redis | 4G基础版，主备，副本数2 | 1 | **414.72元** |
| 云数据库RDS PostgreSQL | 8vCPU/32GB独享，SSD 100GB，主备 | 1 | **4,190.40元** |
| 云搜索服务CSS | 4u8g, 超高I/O 40GB, 3节点 | 1 | **2,864.16元** |
| 弹性负载均衡ELB | 独享型，网络型+应用型弹性规格 | 1 | **108元 + LCU费用** |
| NAT网关 | 小型，SNAT规则3个 | 1 | **360元** |

> **合计**：**16,358.84元** + 应用型LCU费用 + EIP费用 + OBS费用 + MaaS tokens费用

**包年包月（月预估）**：**11,057.22元** + 应用型LCU费用 + EIP费用 + OBS费用 + MaaS tokens费用

---

### 3.3 实施步骤

#### 3.3.1 准备工作

##### （可选）创建 rf_admin_trust 委托

7个步骤：
1. 进入华为云控制台 → 统一身份认证
2. 进入"委托"菜单，搜索"rf_admin_trust"（已存在则跳过）
3. 创建委托：名称 `rf_admin_trust`，类型"云服务"，输入"RFS"
4. 单击"立即授权"
5. 搜索并勾选 "Tenant Administrator"
6. 选择"所有资源"→"确定"
7. 确认委托列表中显示 `rf_admin_trust`

##### （可选）登录CCE控制台授权

仅适用于CCE高可用版本。首次开通CCE需先登录CCE控制台并完成授权。

##### 获取OBS桶名（CCE高可用版本）

1. 准备OBS桶（已有可跳过）
2. 获取OBS桶名
3. 复制桶名

> OBS桶须和方案部署region一致

#### 3.3.2 快速部署（17步骤）

**Step 1**：登录解决方案实践平台，选择"快速搭建Dify-LLM应用开发平台"，单击"开始部署"

**Step 2**：基础配置 — 选择计费模式、区域、解决方案名称、购买时长

**Step 3**：Flexus云服务器X实例配置（应用容器节点）— 3台，配置规格、密码

**Step 4**：Flexus云服务器X实例配置（向量化/排序模型节点）— 1台

**Step 5**：云容器引擎CCE配置 — 默认CCE Turbo集群，3 master实例

**Step 6**：分布式缓存Redis配置 — 选择规格、密码

**Step 7**：云数据库RDS配置 — 选择规格、管理员密码、database用户密码

**Step 8**：云搜索服务CSS配置 — 选择规格，默认3节点

**Step 9**：弹性负载均衡ELB配置 — 默认按需、独享型

**Step 10**：弹性公网IP配置 — 默认全动态BGP，按流量计费

**Step 11**：公网NAT网关配置 — 默认小型

**Step 12**：对象存储服务OBS配置 — 选择已有OBS桶，填写AK/SK

**Step 13**：确认配置概要

**Step 14**：一键部署（需确保账户余额充足）

**Step 15**：跳转至资源栈详情

**Step 16**：等待"Apply required resource success"

**Step 17**：在"输出"页面查看访问链接（需等待5~10分钟）

#### 3.3.3 开始使用

##### 安全组规则修改（可选）
- 端口80用于Dify访问，需配置IP白名单
- 端口22用于SSH远程登录

##### Dify基础使用
1. 访问地址，首次登录注册管理员账号
2. 对接大模型：与MaaS服务对接 或 与一键部署DeepSeek对接

##### 与MaaS服务对接
1. 访问MaaS控制台 → 在线推理 → 预置服务
2. API Key管理（最多30个）
3. 创建API Key
4. Dify平台安装"华为云Maas平台"插件
5. 配置模型信息（填写API Key）

##### 与一键部署DeepSeek对接
1. 设置 → 模型供应商 → Ollama → 添加模型
2. 配置模型名称、基础URL、端口号11434

##### 创建知识库
- **经济型**：默认配置，保存与处理
- **高质量型**：选择Embedding模型（bge-m3）、混合检索、Reranker模型（bge-reranker-v2-m3）、Score阈值0.5

##### 应用创建与使用
- 创建聊天助手
- （可选）联网搜索：开通MaaS联网增强MCP服务（9步骤）
- 创建工作流：导入DSL文件（URL）
- 发布应用（API/直接访问/嵌入网站）

##### Dify配置公网域名（社区版单机部署）
1. 管理解析 → 添加A记录
2. 远程登录服务器
3. 上传SSL证书至 `/dify/docker/nginx/ssl`
4. 执行 `sh /dify/docker/configure_dify_domain_name.sh ${域名}`
5. 通过域名访问

#### 3.3.4 快速卸载

**高可用版预处理**：需停止Dify对外服务，断开数据库连接

**步骤**：
1. 进入RDS控制台 → 数据库实例详情
2. 智能DBA助手 → 会话管理 → 选中数据库名`dify`、用户名`postgres`的进程 → Kill会话
3. 登录RFS资源栈 → 找到资源栈 → 删除
4. 确认：删除方式"删除资源"，输入"Delete"

---

### 3.4 附录：名词解释

| 术语 | 说明 |
|------|------|
| **Flexus云服务器X实例** | 新一代面向中小企业和开发者的柔性算力云服务器，灵活vCPU内存配比，支持热变配 |
| **弹性云服务器 ECS** | 云上可随时自助获取、可弹性伸缩的计算服务 |
| **虚拟私有云 VPC** | 用户在华为云上申请的隔离、私密的虚拟网络环境 |
| **弹性公网IP EIP** | 独立的公网IP资源，可与多种资源灵活绑定及解绑 |
| **云容器引擎 CCE** | 提供高度可扩展、高性能的企业级Kubernetes集群 |
| **云搜索服务 CSS** | 完全兼容开源Elasticsearch的分布式搜索引擎服务 |
| **分布式缓存服务 DCS** | 兼容Redis，提供单机、主备、集群等实例类型 |
| **云数据库 RDS for PostgreSQL** | 开源对象关系型数据库，支持NoSQL类型和GIS地理信息处理 |
| **NAT网关 NAT** | 为VPC内云主机提供SNAT和DNAT功能 |

### 3.5 修订记录

| 发布日期 | 修订内容 |
|----------|----------|
| 2026-05-21 | 更新快速部署方式 |
| 2025-09-01 | 更新CCE容器高可用 |
| 2025-05-30 | 单机部署支持云搜索及Embedding&Reranker模型 |
| 2025-03-12 | 支持CCE容器高可用部署 |
| 2024-11-07 | 第一次正式发布 |

---

## 第四部分：国际站英文详情页

> **URL**：https://www.huaweicloud.com/intl/en-us/solution/implementations/bdadp.html  
> **语言**：English  
> **Version**：2.0.0  
> **Last Updated**：November 2025  
> **Deployment Time**：~20 minutes  
> **Uninstallation Time**：~10 minutes

### 4.1 Solution Overview

Rapid deployment of both standalone and high-availability Dify instances, with support for mounting Dify knowledge bases to Huawei Cloud OBS buckets.

> Dify is an open-source large language model (LLM) application development platform that integrates the concepts of BaaS and LLMOps.

### 4.2 Available Regions (10 regions)

AP-Bangkok, CN-Hong Kong, AP-Singapore, AF-Cairo, AF-Johannesburg, LA-Mexico City2, LA-Santiago, LA-Sao Paulo1, ME-Riyadh, TR-Istanbul

### 4.3 Deployment Options

#### Option 1: Single-Cloud Server Deployment

| Resource | Purpose |
|----------|---------|
| 1x Flexus X Instance | Host the Dify platform |
| 1x EIP | Internet access |
| 1x Security Group | Protect cloud servers |

#### Option 2: HA Deployment in CCE Container

| Resource | Count | Purpose |
|----------|:-----:|---------|
| EIPs | 3 | Internet access |
| ELB | 1 | Distribute traffic across backend services |
| NAT Gateway | 1 | SNAT rules for outbound connectivity |
| FlexusX Instances | 3 | Run five core Dify plug-ins |
| CCE Turbo Cluster | 1 | Node pool managing the 3 FlexusX instances |
| FlexusX (models) | 1 | Deploy Embedding (bge-m3) and Reranker (bge-reranker-v2-m3) |
| OBS | 1 | Mount Dify knowledge base to OBS bucket |
| DCS for Redis | 1 | High-performance NoSQL; ensures data consistency |
| RDS for PostgreSQL | 1 | Primary/standby across AZs for disaster recovery |
| CSS OpenSearch | 1 | Online distributed search and semantic search |
| Security Groups | 4 | Protect cloud services |

### 4.4 Advantages

- **Cost optimization** — cost-efficient ECSs, auto-scaling support
- **High availability** — leverages CCE, RDS for PostgreSQL, and CSS OpenSearch
- **Easy deployment** — one-click deployment

### 4.5 Deployment Links

Each region provides deployment buttons for Cloud Server Deployment and/or HA Deployment in CCE Container, powered by Huawei Cloud Resource Formation (Terraform JSON templates).

**Deployment Guide**：https://support.huaweicloud.com/intl/en-us/dify-aislt/dify_01.html

---

## 第五部分：国际站英文文档（全量）

> **根 URL**：https://support.huaweicloud.com/intl/en-us/dify-aislt/  
> **语言**：English  
> **定价货币**：USD  
> **最后更新**：2025-09-02

### 文档结构总览

| Page | URL | Last Updated |
|------|-----|:------------:|
| Solution Overview | `dify_01.html` | 2025-05-14 |
| Resource Planning and Costs | `dify_02.html` | 2025-09-02 |
| Implementation Procedure (nav) | `dify_03.html` | 2025-05-14 |
| Preparations | `dify_04.html` | 2025-05-14 |
| Rapid Deployment | `dify_05.html` | 2025-09-02 |
| Getting Started | `dify_06.html` | 2025-09-02 |
| Quick Uninstallation | `dify_07.html` | 2025-05-14 |
| Appendix | `dify_08.html` | 2025-05-14 |
| Change History | `dify_09.html` | 2025-09-02 |

### 5.1 Solution Overview

**Scenarios**：Enables rapid deployment of both standalone and high-availability Dify versions. Supports mounting Dify document knowledge bases to Huawei Cloud OBS buckets.

**Two deployment architectures**：

#### Single-Cloud Server Deployment

| Resource | Purpose |
|----------|---------|
| 1 × Flexus X Instance (FlexusX) | Hosts the Dify platform |
| 1 × Elastic IP (EIP) | Associated with FlexusX for internet access |
| 1 × Security Group | Protects the cloud server |

#### HA Deployment in CCE Container

| Resource | Purpose |
|----------|---------|
| 3 × EIPs | Enable internet access |
| 1 × ELB | Distributes traffic; enhances external service capabilities |
| 1 × NAT Gateway | SNAT rules for outbound connectivity |
| 3 × FlexusX instances | Deploy five core Dify plug-ins |
| 1 × CCE Turbo cluster | Manages the three FlexusX instances |
| 1 × FlexusX | Deploys Embedding (bge-m3) and Reranker (bge-reranker-v2-m3) |
| 1 × OBS | Mounts the Dify knowledge base to an OBS bucket |
| 1 × DCS for Redis | High-performance, cost-effective NoSQL database |
| 1 × RDS for PostgreSQL | Primary/standby deployment across AZs |
| 1 × CSS OpenSearch cluster | Online distributed search and semantic search |
| 4 × Security Groups | Protect cloud services |

**Advantages**：Cost optimization, High availability, Easy deployment

**Constraints**：
- HUAWEI ID with access to the target region required
- Yearly/monthly billing: sufficient balance for auto-payment
- IAM agency permissions check

### 5.2 Resource Planning and Costs

#### Single-Cloud Server Deployment (Pay-per-use)

| Service | Configuration | Qty | Est. Monthly Cost |
|---------|--------------|:---:|:-----------------:|
| VPC | AP-Bangkok, 172.16.0.0/16 | 1 | $0.00 USD |
| Subnet | AP-Bangkok, 172.16.1.0/24 | 1 | $0.00 USD |
| Security Group | AP-Bangkok | 1 | $0.00 USD |
| Flexus X Instance | x1.8u.16g, Ubuntu 22.04, 100 GB High I/O | 1 | **$195.98 USD** |
| EIP | $0.11/GB/hr, dynamic BGP, 300 Mbit/s | 1 | $0.11 USD/GB/hr |

> **Total**：$195.98 USD + EIP traffic fee

**Yearly/Monthly**：$144.44 USD + EIP traffic fee

#### HA Deployment in CCE Container (Pay-per-use)

| Service | Configuration | Qty | Est. Monthly Cost |
|---------|--------------|:---:|:-----------------:|
| VPC | AP-Bangkok, 192.168.0.0/16 | 1 | $0.00 |
| Subnet | 4 subnets | 4 | $0.00 |
| Security Group | 4 SGs | 4 | $0.00 |
| Flexus X (3 nodes) | x1.16u.16g, 40GB+100GB | 3 | **$1,045.01** |
| ECS (embed/rerank) | c7n.8xlarge.2, 32vCPU/64GiB, Ubuntu 24.04 | 1 | **$1,022.40** |
| EIP (3) | $0.11/GB/hr each | 3 | $0.33/GB/hr |
| OBS | Multi-AZ Standard, Private | 1 | Varies |
| CCE | cce.s2.small (50 nodes) | 1 | **$280.80** |
| DCS for Redis | 4 GB master/standby, 2 replicas | 1 | **$92.16** |
| RDS for PostgreSQL | 8vCPU/32GB, SSD 100GB, PG 16.8 | 1 | **$842.40** |
| CSS OpenSearch | 4vCPU/8GB, 40GB | 3 nodes | **$563.33** |
| ELB | Dedicated, private network | 1 | **$38.16** |
| NAT Gateway | Small, 3 SNAT rules | 1 | **$73.14** |

> **Total**：**$3,957.40 USD** + EIP traffic fee + OBS storage and traffic fee

**Yearly/Monthly**：**$2,992.97 USD** + EIP traffic fee + OBS storage and traffic fee

### 5.3 Implementation Procedure

#### Preparations

**Creating the rf_admin_trust Agency** (7 steps, same as Chinese version)
1. Navigate to IAM
2. Check for existing agency
3. Create agency: name `rf_admin_trust`, type Cloud service, RFS
4. Click Authorize
5. Search for "Tenant Administrator"
6. Set scope to "All resources"
7. Verify

**Obtaining the OBS Bucket Name** (for HA deployment)
1. Prepare an OBS bucket
2. Locate the bucket
3. Copy the bucket name

#### Rapid Deployment (10 steps)

**Step 1**: Log in to Huawei Cloud Solutions, select the solution, click Deploy
**Step 2**: Select Template → Next
**Step 3**: Configure Parameters

**Single-Cloud Server Deployment Parameters**：

| Parameter | Type | Mandatory | Description | Default |
|-----------|------|:---------:|-------------|---------|
| `vpc_name` | String | Yes | VPC name, unique, ≤54 chars | `dify-llm-application-development-platform-demo` |
| `secgroup_name` | String | Yes | Security group name, ≤64 chars | Same as above |
| `ecs_name` | String | Yes | Server instance name, ≤64 chars | Same as above |
| `ecs_flavor` | String | Yes | ECS or FlexusX flavor | `x1.8u.16g` |
| `ecs_password` | String | Yes | 8-26 chars, 3 of 4 categories | Empty |
| `system_disk_size` | Number | Yes | 40-1024 GB, High I/O | 100 |
| `bandwidth_size` | Number | Yes | 1-300 Mbit/s, traffic-billed | 300 |
| `charging_mode` | String | Yes | `postPaid` or `prePaid` | postPaid |
| `charging_unit` | String | Yes | `month` or `year` | month |
| `charging_period` | Number | Yes | 1-9 months or 1-3 years | 1 |

**HA Deployment in CCE Container Parameters**：

| Parameter | Type | Mandatory | Description | Default |
|-----------|------|:---------:|-------------|---------|
| `dify_version` | string | Yes | Community Edition version: 1.7.1, 1.4.1, 0.15.8 | 1.7.1 |
| `resource_name_prefix` | String | Yes | 4-24 chars, lowercase, digits, hyphens | `ha-dify-app` |
| `bandwidth_size` | String | Yes | 1-300 Mbit/s | 300 |
| `cce_cluster_flavor` | String | Yes | small/medium/large/xlarge | `cce.s2.small` |
| `cce_node_pool_password` | String | Yes | 8-24 chars | Empty |
| `cce_node_pool_flavor` | String | Yes | Min 3vCPUs, 6GiB | `x1.16u.16g` |
| `rds_flavor` | String | Yes | Primary/standby | `rds.pg.n1.large.2.ha` |
| `pgsql_password` | String | Yes | 8-24 chars | Empty |
| `pgsql_user_password` | String | Yes | Different from username | Empty |
| `redis_capacity` | Number | Yes | 1 GB to 64 GB | 4 |
| `redis_password` | String | Yes | 8-24 chars | Empty |
| `obs_bucket` | String | Yes | Existing OBS bucket name | Empty |
| `access_key` | String | Yes | 20 characters | Empty |
| `secret_key` | String | Yes | 40 characters | Empty |
| `embedding_reranker_flavor` | String | Optional | Leave blank to skip | `c7n.4xlarge.2` |
| `ecs_password` | String | Optional | 8-24 chars | Empty |
| `charging_mode` | String | Yes | postPaid or prePaid | postPaid |
| `charging_unit` | String | Yes | month or year | month |
| `charging_period` | Number | Yes | 1-9 months or 1-3 years | 1 |

**Step 4**: (Optional) Agency setting — select `rf_admin_trust`
**Step 5**: Create execution plan
**Step 6**: Name the execution plan
**Step 7**: Deploy → Execute
**Step 8**: (Optional) Manual payment for yearly/monthly
**Step 9**: Verify "Apply required resource success"
**Step 10**: View access URL in Outputs tab (wait 5-10 minutes)

#### Getting Started

**(Optional) Modifying Security Group Rules**
- Port 80: access Dify, configure IP whitelist
- Port 22: SSH remote login, configure IP whitelist
- Initialization: 5-10 minutes post-deployment

**Using Dify**
1. Log in to Dify using the access address
2. Create administrator account on first login

**Interconnecting with DeepSeek Models**
1. Settings → Model Provider → Ollama → Add Model
2. Configure model name, base URL (private IP or public IP), port 11434

**HA Deployment in CCE Container** (18 steps)
1. Log in to Dify and add model
2. Add Embedding and Reranker models
3. Create knowledge base (Economical or High Quality)
4. Import DSL file from URL
5. Configure search plug-in
6. Test and publish

#### Quick Uninstallation (5 steps)

1. Ensure Dify external services are stopped
2. Navigate to RDS console, find the database instance
3. Kill active sessions (database: `dify`, username: `postgres`)
4. Delete the resource stack from RFS console
5. Confirm deletion (select "Delete resource", type "Delete")

### 5.4 Appendix: Terms Glossary

| Term | Description |
|------|-------------|
| **Flexus X Instance** | Next-gen flexible cloud server for SMEs and developers |
| **Elastic Cloud Server (ECS)** | Scalable, on-demand computing service |
| **Virtual Private Cloud (VPC)** | Isolated, private virtual network on Huawei Cloud |
| **Elastic IP (EIP)** | Static public IPs and scalable bandwidths |
| **Cloud Container Engine (CCE)** | Enterprise-class Kubernetes clusters |
| **Cloud Search Service (CSS)** | Managed distributed search engine (Elasticsearch-compatible) |
| **Distributed Cache Service (DCS)** | In-memory cache service compatible with Redis |
| **RDS for PostgreSQL** | Open-source object-relational database |
| **NAT Gateway** | Provides SNAT and DNAT for VPC cloud servers |

### 5.5 Change History

| Released On | Change Description |
|:-----------:|--------------------|
| 2025-09-02 | Update CCE Container High Availability |
| 2025-04-30 | Supported HA deployment of Dify platform in CCE containers |
| 2025-02-11 | First official release |

---

## 第六部分：国际站中文详情页

> **说明**：国际站无独立的中文详情页，其内容指向中国站详情页（https://www.huaweicloud.com/solution/implementations/building-a-dify-llm-application-development-platform.html）。

### 6.1 与中国站详情页的关系

| 维度 | 中国站详情页 | 国际站中文详情页 |
|------|-------------|-----------------|
| URL | `huaweicloud.com/solution/...` | 指向中国站详情页 |
| 语言 | 简体中文 | 简体中文 |
| 内容 | 完整方案展示 | 同中国站 |
| 定价 | CNY | CNY |
| 区域 | 华北-北京四 | 华北-北京四 |

### 6.2 差异说明

国际站中文用户访问详情页时，看到的实际是中国站的内容。如需面向海外中文用户展示独立内容（如海外区域部署、USD定价），需通过国际站文档站获取。

---

## 第七部分：国际站中文文档（全量）

> **根 URL**：https://support.huaweicloud.com/intl/zh-cn/dify-aislt/  
> **语言**：简体中文（面向海外中文用户）  
> **定价货币**：USD（美元）  
> **部署区域**：亚太-曼谷

### 7.1 文档结构总览

| 页面 | URL | 最后更新 |
|------|-----|:--------:|
| 方案概述 | `dify_01.html` | 2025-04-21 |
| 资源和成本规划 | `dify_02.html` | 2025-09-02 |
| 实施步骤（导航页） | `dify_03.html` | 2025-04-10 |
| 准备工作 | `dify_04.html` | 2026-04-13 |
| 快速部署 | `dify_05.html` | 2026-04-13 |
| 开始使用 | `dify_06.html` | 2025-09-02 |
| 快速卸载 | `dify_07.html` | 2025-05-08 |
| 附录 | `dify_08.html` | 2025-05-08 |

> **注意**：国际站中文文档不包含修订记录页面，或修订记录内容较少。

### 7.2 方案概述

**应用场景**：支持快速部署单机版和高可用版Dify LLM应用开发平台，可将文档知识库挂载到华为云对象存储服务OBS桶。

**方案架构**（两张架构图）：
- 图1：方案架构图（单机部署）
- 图2：方案架构图（高可用部署）

**部署资源清单**：

#### 云服务器单机部署
- Flexus云服务器X实例 × 1
- 弹性公网IP EIP × 1
- 安全组 × 1

#### CCE容器高可用部署
- EIP × 3
- ELB × 1
- NAT网关 × 1
- FlexusX实例 × 3（Dify 5个核心插件）
- CCE Turbo集群 × 1
- FlexusX实例 × 1（Embedding/Reranker）
- OBS × 1
- DCS for Redis × 1
- RDS for PostgreSQL × 1（主备跨AZ）
- CSS OpenSearch × 1
- 安全组 × 4

**方案优势**：成本优化、高可用性、一键部署

**约束与限制**：
1. 部署前需拥有可访问该区域的华为账号且已开通华为云
2. 包年包月需确保账户余额充足
3. IAM委托权限

### 7.3 资源和成本规划

> **注意**：国际站中文文档的资源和成本数据与中国站文档**存在差异**——区域使用亚太-曼谷，货币使用美元（USD），部分服务规格不同。

#### 云服务器单机部署（按需计费）

| 服务 | 配置 | 数量 | 月预估花费 |
|------|------|:----:|:----------:|
| VPC | 亚太-曼谷，172.16.0.0/16 | 1 | USD 0.00 |
| 子网 | 亚太-曼谷，172.16.1.0/24 | 1 | USD 0.00 |
| 安全组 | 亚太-曼谷 | 1 | USD 0.00 |
| Flexus云服务器X实例 | 8核/16GB, Ubuntu 22.04, 高IO 100GB | 1 | **USD 195.98** |
| 弹性公网IP | USD 0.11/GB/小时, 动态BGP, 300Mbit/s | 1 | USD 0.11/GB/小时 |

> **合计**：USD 195.98 + EIP流量费用

**包年包月**：USD 144.44 + EIP流量费用

#### CCE容器高可用部署（按需计费）

| 服务 | 配置 | 数量 | 月预估花费 |
|------|------|:----:|:----------:|
| Flexus云服务器X实例（3台） | 16核/16GB, 40GB+100GB | 3 | **USD 1,045.01** |
| ECS (embedding-reranker) | 32vCPU/64GiB, Ubuntu 24.04 | 1 | **USD 1,022.40** |
| CCE | cce.s2.small (50节点) | 1 | **USD 280.80** |
| Redis | 4GB, 主备, 副本数2 | 1 | **USD 92.16** |
| RDS PostgreSQL | 8vCPU/32GB, SSD 100GB | 1 | **USD 842.40** |
| CSS OpenSearch | 4vCPU/8GB, 40GB | 3节点 | **USD 563.33** |
| ELB | 独享型, 私网 | 1 | **USD 38.16** |
| NAT网关 | 小型, SNAT规则3 | 1 | **USD 73.14** |

> **合计**：**USD 3,957.40** + EIP流量费用 + OBS费用

**包年包月**：**USD 2,992.97** + EIP流量费用 + OBS费用

### 7.4 实施步骤

#### 准备工作

**创建rf_admin_trust委托**（7步骤，内容同中国站）

**(可选) 登录CCE控制台授权**：仅适用于CCE高可用版本

**获取OBS桶名（CCE高可用版本）**：3步骤

#### 快速部署

> **与中国站文档的差异**：国际站中文文档的部署流程与中国站**基本一致**，但在参数描述中使用了USD计费示例和亚太-曼谷区域。

**步骤1**：登录解决方案实践 → 选择"快速搭建Dify-LLM应用开发平台" → 选择版本

**步骤2**：选择模板 → 下一步

**步骤3**：配置参数（参数列表同中国站，详见参数说明表）

**步骤4**：（可选）委托设置

**步骤5**：创建执行计划

**步骤6**：命名执行计划

**步骤7**：部署 → 执行

**步骤8**：（可选）包年包月费用支付

**步骤9**：验证"Apply required resource success"

**步骤10**：在"输出"查看访问说明（等待5-10分钟）

#### 开始使用

**安全组规则修改（可选）**：配置80端口和22端口的IP白名单

**Dify基础使用**：
1. 登录开发平台
2. 与一键部署DeepSeek模型对接（设置 → 模型供应商 → Ollama → 添加模型）
3. CCE容器高可用版：添加Embedding/Reranker模型 → 创建知识库 → 创建Dify工作流（导入DSL文件）→ 配置搜索插件 → 测试并发布

#### 快速卸载

1. 停止Dify对外服务，断开数据库连接
2. 进入RDS控制台 → 终止数据库会话
3. 登录RFS资源栈 → 删除资源栈
4. 确认删除

### 7.5 附录：名词解释

国际站中文文档的附录包含 **10项** 名词解释：

1. **华为云Flexus云服务器X实例** — 柔性算力云服务器
2. **弹性云服务器 ECS** — 可弹性伸缩的计算服务
3. **虚拟私有云 VPC** — 隔离的虚拟网络环境
4. **弹性公网IP EIP** — 独立的公网IP资源
5. **云容器引擎 CCE** — 企业级Kubernetes集群
6. **云搜索服务 CSS** — 分布式搜索引擎服务
7. **分布式缓存服务 DCS** — 兼容Redis的缓存服务
8. **云数据库 RDS for PostgreSQL** — 开源对象关系型数据库
9. **NAT网关 NAT** — 公网NAT/私网NAT

> **与中国站附录的差异**：国际站中文文档多出"云容器引擎CCE"、"云搜索服务CSS"、"分布式缓存服务DCS"、"云数据库RDS for PostgreSQL"、"NAT网关NAT"这5项，中国站附录只覆盖了前4项。

---

## 第八部分：六板块差异对比总表

### 8.1 基础信息对比

| 维度 | 中国站详情页 | 中国站文档 | 国际站英文详情页 | 国际站英文文档 | 国际站中文详情页 | 国际站中文文档 |
|------|:----------:|:---------:|:--------------:|:-------------:|:--------------:|:-------------:|
| 语言 | 中文 | 中文 | 英文 | 英文 | 中文 | 中文 |
| 货币 | CNY | CNY | USD | USD | CNY | USD |
| 区域 | 华北-北京四 | 华北-北京四 | 10个区域 | 亚太-曼谷 | 华北-北京四 | 亚太-曼谷 |
| 部署方案 | 3种 | 3种 | 2种 | 2种 | 3种 | 2种 |
| 版本号 | — | — | v2.0.0 | — | — | — |
| 最后更新 | — | 2026-05-21 | 2025-11 | 2025-09-02 | — | 2026-04-13 |
| 架构图数量 | 3张 | 3张 | 1张 | 2张 | 3张 | 2张 |

### 8.2 定价对比（单机版参考）

| 对比维度 | 中国站（CNY） | 国际站（USD） |
|----------|:------------:|:------------:|
| 按需 FlexusX (8u16g) | 683.28元/月 | $195.98/月 |
| 包月 FlexusX (8u16g) | 467.00元/月 | $144.44/月 |
| EIP 流量 | 0.80元/GB | $0.11/GB/hr |
| 区域 | 华北-北京四 | 亚太-曼谷 |

### 8.3 内容差异要点

| 差异项 | 中国站 | 国际站英文 | 国际站中文 |
|--------|:------:|:---------:|:---------:|
| 部署方案数量 | 3种（含知识库增强版） | 2种（无知识库增强版） | 2种（无知识库增强版） |
| 详情页应用场景 | 4大场景 | 未明确列出 | 同中国站 |
| 关联解决方案 | 3个关联方案 | 未列出 | 同中国站 |
| 文档修订记录 | 5条记录 | 3条记录 | 未提供/无独立页面 |
| 附录名词数量 | 4项 | 9项 | 9项 |
| 部署步骤详细度 | 17步骤（表单式） | 10步骤（流程式） | 10步骤（流程式） |
| 快速部署参数表 | 无独立参数表 | 有详细参数表 | 有详细参数表 |
| "开始使用"内容 | 含MaaS对接+DeepSeek对接+联网搜索MCP+公网域名配置 | 含DeepSeek对接+18步CCE流程 | 含DeepSeek对接+CCE流程 |

### 8.4 功能差异要点

1. **中国站详情页**提供三种部署方案（社区单机版、知识库搜索增强版、CCE容器高可用版）；**国际站**仅列出两种（单机部署和HA部署），未单独列出"知识库搜索增强版"

2. **中国站详情页**列出4大应用场景和3个关联解决方案；**国际站英文详情页**未包含此内容

3. **中国站文档**部署流程为17步表单填写；**国际站文档**为10步流程式，步骤更简洁但附带完整参数说明表

4. **中国站文档**"开始使用"包含完整的MaaS对接流程和联网搜索MCP服务开通；**国际站英文文档**主要聚焦DeepSeek对接和CCE工作流

5. **中国站详情页**费用标注为"2~5元/6~12元/35~70元"的小时级估算；**文档**提供精确的月预估费用

---

> **本文档为高保真爬取整理版本**，所有内容均来源于华为云官网实时页面。架构图、截图等图片资源因技术限制未纳入本文档，建议结合原始页面浏览。如需获取最新定价信息，请参考华为云官网价格详情页面。
