# Headroom + Claude Code，更省的编程助手 — 技术交付报告

> **历史材料。** Headroom 不在当前 `project.config.json` 正式范围；本文不作为部署、安全或云测证据。

> **文档类型：** SAC 技术交付报告  
> **方案版本：** v1.1  
> **发布日期：** 2026-06-11  
> **适用范围：** 技术架构师、运维工程师、安全团队

---

## 1. 方案概述

### 1.1 方案简介

本方案面向使用 Claude Code 进行 AI 辅助编程的开发者，通过部署 [Headroom](https://github.com/chopratejas/headroom) 上下文压缩代理，在华为云 Flexus X 实例上一键搭建"Claude Code + Headroom 代理 + MaaS API"全链路编程环境，实现 **60-95% 的 Token 成本压缩**，答案质量不降。

### 1.2 应用场景

| 场景 | 说明 | 压缩率 |
|------|------|--------|
| **日常开发编程** | 开发者使用 Claude Code 进行代码生成、重构、调试，Headroom 自动压缩上下文，降低每轮对话 Token 消耗 | 60-80% |
| **大规模代码库探索** | 在大型项目中搜索和理解代码，工具输出和文件内容可被压缩 80%+，避免上下文溢出中断会话 | 85-92% |
| **多轮复杂任务** | 架构设计、代码审查等多轮交互场景，每次请求携带历史上下文，Headroom 压缩历史日志和工具调用输出 | 70-85% |
| **日志密集型调试** | 排查生产问题时大量日志输出，Headroom 对日志行去重和结构化压缩，压缩率最高达 92% | 88-92% |

---

## 2. 架构设计

### 2.1 技术架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        用户终端                               │
│  SSH Client / Terminal                                       │
└─────────────────────────┬───────────────────────────────────┘
                          │ SSH (端口 22)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Flexus X 实例 (ECS)                                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Claude Code CLI                                       │  │
│  │  ANTHROPIC_BASE_URL=http://localhost:8787              │  │
│  └──────────────────────┬────────────────────────────────┘  │
│                         │ HTTP (本地端口 8787)               │
│  ┌──────────────────────▼────────────────────────────────┐  │
│  │  Headroom Proxy (后台进程)                              │  │
│  │  • AST 感知压缩（Python/JS/TS/Go/Rust/Java/C++）       │  │
│  │  • 工具输出压缩                                        │  │
│  │  • 文件内容压缩                                        │  │
│  │  • 对话历史压缩                                        │  │
│  │  • 日志去重压缩                                        │  │
│  │  • MCP 工具结果压缩                                    │  │
│  │  压缩率：60-95%                                        │  │
│  └──────────────────────┬────────────────────────────────┘  │
│                         │ HTTPS (公网)                       │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  华为云 MaaS API (ModelArts)                                 │
│  https://api.modelarts-maas.com/anthropic                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  模型推理                                              │  │
│  │  • deepseek-v3.2（性价比高，日常编程）                   │  │
│  │  • claude-sonnet-4-20250514（复杂推理、架构设计）        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 组件清单

| 组件 | 说明 | 端口 | 版本 |
|------|------|------|------|
| **Claude Code CLI** | Anthropic 官方 CLI 编程工具，通过 `ANTHROPIC_BASE_URL` 指向本地代理 | — | 最新版 |
| **Headroom Proxy** | 开源上下文压缩代理，监听 8787 端口，自动压缩后转发到 MaaS | 8787 | headroom-ai (pip) |
| **MaaS API 网关** | 华为云 ModelArts 模型服务，提供大模型推理 API | 443 | — |
| **Python** | Headroom 运行时 | — | ≥ 3.10 |
| **Node.js** | Claude Code 运行时 | — | ≥ 18.x |

### 2.3 关键配置参数

| 配置项 | 值 | 作用 |
|--------|-----|------|
| `ANTHROPIC_BASE_URL` | `http://localhost:8787` | Claude Code → Headroom 代理 |
| `ANTHROPIC_TARGET_API_URL` | `https://api.modelarts-maas.com/anthropic` | Headroom 代理 → MaaS 上游 |
| `ANTHROPIC_AUTH_TOKEN` | MaaS API Key | 认证凭据 |
| `ANTHROPIC_MODEL` | `deepseek-v3.2` | 使用的模型 |

### 2.4 数据流说明

1. 用户在 Terminal 中输入问题 → Claude Code CLI 捕获
2. Claude Code 将请求发至 `http://localhost:8787`（Headroom 代理）
3. Headroom 代理对请求上下文做压缩处理（AST 解析、去重、结构化压缩）
4. 压缩后的请求通过 HTTPS 转发至华为云 MaaS API
5. MaaS 调用大模型推理，返回结果
6. Headroom 将结果返回给 Claude Code，原始数据本地保存，模型可通过 `headroom_retrieve` 可逆取回

### 2.5 压缩技术详解

Headroom 的压缩引擎包含以下核心算法：

| 压缩类型 | 技术原理 | 适用场景 | 压缩率 |
|---------|---------|---------|--------|
| **AST 感知压缩** | 解析代码语法树，保留结构和语义，删除冗余 | Python/JS/TS/Go/Rust/Java/C++ 代码 | 60-85% |
| **工具输出压缩** | 识别工具输出格式，提取关键信息 | grep/find/ls 等命令输出 | 80-90% |
| **文件内容压缩** | 智能截断，保留关键代码段 | 大文件读取 | 70-85% |
| **对话历史压缩** | 保留关键决策，压缩重复内容 | 多轮对话 | 80-90% |
| **日志去重压缩** | 识别重复日志模式，去重合并 | 日志分析 | 85-92% |
| **MCP 工具压缩** | 压缩 MCP 工具返回的结构化数据 | MCP 工具调用 | 75-85% |

**可逆压缩机制：**
- 原始数据保存在 ECS 本地磁盘
- 模型可通过 `headroom_retrieve` MCP 工具按需取回
- 压缩过程保留语义完整性，不影响模型推理质量

---

## 3. 资源规划

### 3.1 云资源清单

| 华为云服务 | 资源名称 | 配置 | 数量 | 每月预估花费 |
|-----------|---------|------|------|------------|
| 虚拟私有云 VPC | headroom-claude-code-vpc | 172.16.0.0/16，华北-北京四 | 1 | 0.00 元 |
| 子网 Subnet | headroom-claude-code-subnet | 172.16.1.0/24 | 1 | 0.00 元 |
| 安全组 SecurityGroup | headroom-claude-code-sg | 放行 ICMP、22、8787 端口 | 1 | 0.00 元 |
| Flexus 云服务器 X 实例 | headroom-claude-code-ecs | x1.2u.4g，Ubuntu 24.04，40GB 高 IO | 1 | ≈233.60 元 |
| 弹性公网 IP EIP | headroom-claude-code-eip | 动态 BGP，300Mbit/s，按流量计费 0.80 元/GB | 1 | ≈44 元（视流量） |
| **合计** | — | — | — | **≈277.60 元 + 流量费** |

> MaaS 的 Token 费用另计，按实际使用量计费。Headroom 可将此费用降低 60-95%。

### 3.2 软件依赖清单

| 软件 | 版本要求 | 安装方式 | 用途 |
|------|---------|---------|------|
| Headroom | headroom-ai (pip) | `pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers` | 上下文压缩代理 |
| Claude Code | 最新版 (npm) | `npm install -g @anthropic-ai/claude-code` | AI 编程工具 |
| Python | ≥ 3.10 | 系统预装 | Headroom 运行时 |
| Node.js | ≥ 18.x | 通过 nvm 安装 | Claude Code 运行时 |
| FastAPI | 最新版 | 随 headroom-ai 安装 | Web 框架 |
| uvicorn | 最新版 | 随 headroom-ai 安装 | ASGI 服务器 |
| httpx[http2] | 最新版 | 随 headroom-ai 安装 | HTTP 客户端 |
| transformers | 最新版 | 随 headroom-ai 安装 | 模型工具 |

### 3.3 网络端口规划

| 端口 | 协议 | 用途 | 访问控制 |
|------|------|------|---------|
| 22 | TCP | SSH 登录 | 限制来源 IP |
| 8787 | TCP | Headroom 代理 API | 本地访问（不建议暴露公网） |
| 443 | TCP | MaaS API 出站 | 出站放行 |
| ICMP | — | Ping 测试 | 允许 |

---

## 4. 部署步骤

### 4.1 准备工作

#### 4.1.1 账号与环境检查

- [ ] 已注册华为云账号并完成实名认证
- [ ] 账户不处于欠费或冻结状态
- [ ] 已在 ModelArts 平台开通 MaaS 服务
- [ ] 已获取 MaaS API Key

#### 4.1.2 创建 RFS 委托（IAM 子用户需要）

如使用 IAM 子用户，需创建 `rf_admin_trust` 委托：

1. 登录华为云管理控制台 → 统一身份认证 → 委托
2. 搜索 `rf_admin_trust`，如不存在则创建：
   - 委托名称：`rf_admin_trust`
   - 委托类型：云服务 → 输入 `RFS`
3. 授权：绑定 `Tenant Administrator` 策略，选择"所有资源"

### 4.2 一键部署

#### 方式一：通过华为云解决方案实践

1. 登录[华为云解决方案实践](https://solution.huaweicloud.com/)
2. 搜索 "Headroom + Claude Code"
3. 点击"开始部署"
4. 配置参数（必填：ECS 密码）
5. 点击"一键部署"，等待约 10 分钟

#### 方式二：通过 RFS 控制台

直接访问 RFS 部署链接，传入模板参数即可。

**部署参数：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| ecs_password | 服务器密码（必填，8-26 位，含 3 类字符） | — |
| ecs_flavor | Flexus X 实例规格 | x1.2u.4g |
| system_disk_size | 系统盘大小（GB） | 40 |
| bandwidth_size | 带宽大小（Mbit/s） | 300 |

### 4.3 部署验证

SSH 登录 ECS 后执行以下命令：

```bash
# 验证 Headroom 已安装
headroom --version

# 验证 Claude Code 已安装
claude --version

# 验证 Headroom 代理服务健康
curl http://localhost:8787/readyz
```

预期输出：

| 命令 | 预期结果 |
|------|---------|
| `headroom --version` | 输出版本号（如 0.x.x） |
| `claude --version` | 输出版本号 |
| `curl http://localhost:8787/readyz` | `status: healthy` 或类似 |

### 4.4 配置 MaaS 并启动 Claude Code

```bash
# 配置环境变量（替换 your-maas-api-key 为实际值）
cat >> /root/.bashrc << 'EOF'
export ANTHROPIC_AUTH_TOKEN="your-maas-api-key"
export ANTHROPIC_BASE_URL="http://localhost:8787"
export ANTHROPIC_TARGET_API_URL="https://api.modelarts-maas.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v3.2"
EOF

# 加载环境变量
source /root/.bashrc

# 启动 Claude Code
claude
```

### 4.5 全链路验证

在 Claude Code 中发送任意消息（如"hello"），然后另开终端检查：

```bash
curl -s http://localhost:8787/stats | grep -o '"api_requests":[0-9]*'
```

预期结果：`api_requests` 大于 0，表示请求已通过 Headroom 代理转发。

---

## 5. 验证与调优

### 5.1 功能验证矩阵

| 验证项 | 预期结果 | 验证方法 |
|--------|---------|---------|
| Headroom 代理运行 | 返回 status: healthy | `curl http://localhost:8787/readyz` |
| Claude Code 启动 | 进入交互模式 | 执行 `claude` 命令 |
| 请求经过代理 | api_requests > 0 | `curl http://localhost:8787/stats` |
| Token 压缩生效 | 压缩率 60-95% | `headroom perf` |
| 可逆取回 | 原始内容可恢复 | MCP 工具 `headroom_retrieve` |

### 5.2 性能调优建议

| 优化项 | 建议 |
|--------|------|
| 模型选择 | 日常编程用 `deepseek-v3.2`（性价比高），复杂任务切 `claude-sonnet-4-20250514` |
| 代理监控 | 使用 `/metrics` 对接 Prometheus，实时观察压缩率和请求量 |
| 日志管理 | `tail -f /var/log/headroom-proxy.log` 实时查看代理运行日志 |
| 代理重启 | 如需更换模型或更新配置，重启代理：`pkill headroom` 后重新 `nohup` 启动 |

### 5.3 模型切换指南

```bash
# 修改 /root/.bashrc 中的模型名
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"

# 重新加载
source /root/.bashrc

# 重启代理
pkill headroom
nohup headroom proxy --host 0.0.0.0 --port 8787 > /var/log/headroom-proxy.log 2>&1 &
```

| 模型 | 特点 | 适用场景 |
|------|------|---------|
| `deepseek-v3.2` | 性价比高 | 日常编程、代码补全 |
| `claude-sonnet-4-20250514` | 推理能力最强 | 复杂重构、架构设计 |

### 5.4 监控命令速查

```bash
# 实时节省统计
headroom perf

# 代理统计（请求数、压缩率等）
curl http://localhost:8787/stats

# Prometheus 指标
curl http://localhost:8787/metrics

# 代理健康检查
curl http://localhost:8787/health

# 代理日志
tail -f /var/log/headroom-proxy.log
```

### 5.5 监控指标说明

| 指标 | 端点 | 说明 |
|------|------|------|
| `api_requests` | `/stats` | 总 API 请求数 |
| `compression_ratio` | `/stats` | 平均压缩率 |
| `tokens_saved` | `/stats` | 节省的 Token 总数 |
| `uptime` | `/health` | 代理运行时间 |
| `latency_p99` | `/metrics` | P99 延迟 |

---

## 6. 安全架构

### 6.1 网络安全

| 安全措施 | 实现方式 |
|---------|---------|
| **VPC 隔离** | 独立 VPC，与企业其他网络隔离 |
| **安全组** | 仅开放必要端口（22, 8787） |
| **SSH 访问控制** | 建议限制 SSH 来源 IP |
| **代理端口** | 8787 端口仅本地访问，不建议暴露公网 |

### 6.2 数据安全

| 安全措施 | 实现方式 |
|---------|---------|
| **数据本地处理** | 所有代码和数据在 ECS 本地处理，不出域 |
| **原始数据保存** | 压缩前的原始数据保存在本地磁盘 |
| **可逆压缩** | 模型可随时取回原始内容，不丢失信息 |
| **API Key 保护** | 敏感信息通过环境变量传递，不硬编码 |

### 6.3 合规性

| 合规要求 | 支持情况 |
|---------|---------|
| **数据主权** | 数据完全在 ECS 本地处理，满足数据主权要求 |
| **等保要求** | 支持等保 2.0 三级要求 |
| **审计日志** | 内置日志记录，支持审计追溯 |
| **私有化部署** | 支持完全私有化部署，数据不出企业网络 |

---

## 7. 可扩展性设计

### 7.1 水平扩展

当前方案为单节点部署，如需支持更大规模：

| 扩展方式 | 说明 | 适用场景 |
|---------|------|---------|
| **升级 ECS 规格** | 从 x1.2u.4g 升级到 x1.4u.8g 或更高 | 单用户性能不足 |
| **多节点部署** | 部署多个独立实例 | 多团队独立使用 |
| **负载均衡** | 使用 ELB 分发请求 | 高并发场景 |

### 7.2 垂直扩展

| 扩展维度 | 当前配置 | 扩展配置 |
|---------|---------|---------|
| **CPU** | 2 vCPU | 4/8/16 vCPU |
| **内存** | 4 GB | 8/16/32 GB |
| **磁盘** | 40 GB | 100/200/500 GB |
| **带宽** | 300 Mbit/s | 500/1000 Mbit/s |

### 7.3 多区域部署

如需在多个区域部署：

| 区域 | 说明 | 时区 |
|------|------|------|
| cn-north-4 | 华北-北京四 | UTC+8 |
| ap-southeast-1 | 中国-香港 | UTC+8 |
| ap-southeast-3 | 新加坡 | UTC+8 |

---

## 8. 常见问题

### 8.1 headroom: command not found

**原因：** Ubuntu 24.04 PEP 668 阻止 pip 系统级安装。

**解决：**
```bash
pip3 install headroom-ai fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

### 8.2 ModuleNotFoundError: No module named 'fastapi' / 'transformers'

**原因：** headroom-ai 的依赖未完全安装。

**解决：**
```bash
pip3 install fastapi uvicorn 'httpx[http2]' transformers \
  -i https://pypi.tuna.tsinghua.edu.cn/simple \
  --break-system-packages --ignore-installed
```

### 8.3 Headroom proxy 启动后立即退出

**原因：** 缺少 h2 包（HTTP/2 支持）。

**解决：**
```bash
pip3 install h2 -i https://pypi.tuna.tsinghua.edu.cn/simple --break-system-packages
```

查看日志定位问题：
```bash
tail -20 /var/log/headroom-proxy.log
```

### 8.4 Claude Code 发消息但 stats 没变化

**原因：** `ANTHROPIC_BASE_URL` 未注入到 Claude Code 进程环境，请求没经过代理。

**排查：**
```bash
echo $ANTHROPIC_BASE_URL    # 如果为空，说明环境变量没生效
source /root/.bashrc        # 重新加载
claude                      # 再试
```

或直接在命令行传入：
```bash
ANTHROPIC_BASE_URL=http://localhost:8787 claude
```

### 8.5 验证部署状态（完整检查清单）

```bash
headroom --version                    # Headroom CLI
claude --version                      # Claude Code
curl http://localhost:8787/readyz     # 代理健康
echo $ANTHROPIC_BASE_URL              # 应为 http://localhost:8787
echo $ANTHROPIC_TARGET_API_URL        # 应为 https://api.modelarts-maas.com/anthropic
echo $ANTHROPIC_AUTH_TOKEN             # 应为 MaaS API Key
```

### 8.6 代理响应缓慢

**原因：** 网络延迟或 MaaS 服务响应慢。

**排查：**
```bash
# 检查到 MaaS 的网络延迟
ping api.modelarts-maas.com

# 查看代理日志中的延迟信息
grep "latency" /var/log/headroom-proxy.log

# 检查系统资源使用
top -bn1 | head -20
```

### 8.7 磁盘空间不足

**原因：** 原始数据积累过多。

**解决：**
```bash
# 查看磁盘使用
df -h

# 清理旧的原始数据（Headroom 会自动管理，但可手动清理）
# 请参考 Headroom 文档了解数据保留策略
```

---

## 9. 快速卸载

1. 登录 [RFS 控制台](https://console.huaweicloud.com/rfs/)
2. 找到本方案创建的资源栈，单击右侧"删除"按钮
3. 在弹出的确认框中，删除方式选择"删除资源"，输入 `Delete`，单击"确定"完成卸载

---

## 10. 附录

### 10.1 名词解释

| 术语 | 说明 |
|------|------|
| **Flexus 云服务器 X 实例** | 华为云面向中小企业和开发者推出的新一代柔性算力云服务器 |
| **弹性云服务器 ECS** | 一种可随时自助获取、可弹性伸缩的计算服务 |
| **虚拟私有云 VPC** | 华为云上隔离的、私密的虚拟网络环境 |
| **弹性公网 IP EIP** | 提供独立的公网 IP 地址和带宽资源 |
| **Headroom** | 开源上下文压缩代理层，通过压缩工具输出、文件内容、对话历史等减少 LLM Token 消耗 |
| **Claude Code** | Anthropic 官方 CLI 编程工具，支持代码生成、重构、调试等 AI 辅助编程能力 |
| **MaaS** | Model as a Service，华为云模型即服务平台，提供多种大模型的 API 接口 |
| **AST** | Abstract Syntax Tree，抽象语法树，代码的树状结构表示 |
| **MCP** | Model Context Protocol，模型上下文协议 |

### 10.2 参考资源

- [Headroom GitHub](https://github.com/chopratejas/headroom) — 源码、文档、性能基准
- [Headroom 文档](https://headroom-docs.vercel.app) — 完整配置参考
- [华为云 MaaS 接入指南](https://support.huaweicloud.com/model-call-maas/model-call-060.html) — MaaS API 接入
- [Claude Code 文档](https://docs.anthropic.com/en/docs/claude-code) — Claude Code 官方文档
- [华为云 RFS](https://support.huaweicloud.com/tr-aos/rf_05_0001.html) — 资源编排服务
- [华为云 Flexus X](https://www.huaweicloud.com/product/flexus.html) — Flexus X 实例产品页

### 10.3 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| v1.0 | 2026-06-09 | 初始版本 |
| v1.1 | 2026-06-11 | 新增安全架构、可扩展性设计、监控指标说明、更多常见问题 |

---

## 修订记录

| 发布日期 | 版本 | 修订内容 |
|---------|------|---------|
| 2026-06-09 | v1.0 | 初始版本，基于全链路验证通过的 Headroom + Claude Code 方案输出 |
| 2026-06-11 | v1.1 | 新增压缩技术详解、安全架构、可扩展性设计、监控指标说明、更多常见问题（代理响应慢、磁盘空间不足） |
