# Solution Practice Skills

**AI 编码代理的规范技能定义** | **Canonical Skill Definitions for AI Coding Agents**

面向华为云解决方案实践的工程规则、验证检查清单与架构合同。
Engineering rules, validation checklists, and architecture contracts for Huawei Cloud solution practices.

[![npm version](https://img.shields.io/badge/version-0.17.1-blue)](https://github.com/Justin-TangPan/solution-practices)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 概述 / Overview

**中文** — SAC（Solution Practice Skills）是一个 **skills-core** 项目。主要交付物是 `skills/` 目录下的规范 SKILL.md 文件，这些文件编码了 AI 编码代理在构建、审查和部署华为云解决方案实践时所需的工程规则、验证检查清单和架构设计合同。

项目本身**不调用语言模型**、**不提供 Agent Runtime**，也**不部署真实云资源**。技能文件是配置、提示词和工程规则，由宿主工具（如 Claude Code）读取和执行。

**English** — SAC (Solution Practice Skills) is a **skills-core** project. Its primary deliverable is a set of canonical SKILL.md files under the `skills/` directory, encoding the engineering rules, validation checklists, and architecture contracts that AI coding agents need when building, reviewing, and deploying Huawei Cloud solution practices.

The project itself **does not invoke language models**, **does not provide an Agent Runtime**, and **does not deploy real cloud resources**. The skill files are configuration, prompts, and engineering rules that host tools (such as Claude Code) read and execute.

---

## 核心技能 / Core Skills

| 技能 | 用途 | Purpose |
|---|---|---|
| `sac-project` | 项目范围、目录布局、事实源与授权边界 | Project scope, directory layout, source of truth, authorization boundaries |
| `sac-architecture` | 架构设计合同、拓扑、高可用方案与上游研究 | Architecture contracts, topology, HA design, upstream research |
| `sac-implementation` | Terraform 实现、变量、输出、user_data 与初始化脚本 | Terraform implementation, variables, outputs, user_data, init scripts |
| `sac-quality` | 静态验证、安全审查、一致性检查与发布门禁 | Static validation, security review, consistency checks, release gates |
| `sac-documentation` | 部署指南、参数表格与中英文双语文档生成 | Deployment guides, parameter tables, bilingual doc generation |

## 可选技能 / Optional Skills

| 技能 | 用途 | Purpose |
|---|---|---|
| `sac-deep-search` | 争议性话题的跨领域、多来源深度研究 | Cross-domain, multi-source deep research on controversial topics |
| `sac-page-enhance` | Web 呈现层增强 | Web presentation layer enhancement |
| `query-huawei-cloud-prices` | 华为云产品价格与规格实时查询 | Real-time Huawei Cloud product pricing & specs query |

---

## 角色路由 / Agent Role Routing

**中文** — 项目定义三种核心 AI 角色，根据任务类型选择最简角色序列：

**English** — The project defines three core AI agent roles. Select the simplest role sequence based on the task type:

| 任务 Task | 推荐流程 Recommended Flow | 所需技能 Required Skills |
|---|---|---|
| 新方案 / 拓扑 / 高可用 / 数据库 / 存储 / 网络设计<br>New architecture / topology / HA / DB / storage / network design | **架构师 → 实施者 → 审查者**<br>**Architect → Builder → Reviewer** | `sac-project` + `sac-architecture` + `sac-implementation` + `sac-quality` |
| Terraform 维护 / 变量 / 输出 / 初始化脚本变更<br>Terraform maintenance / variables / outputs / init script changes | **实施者**；中高风险加**审查者**<br>**Builder**; add **Reviewer** for med/high risk | `sac-project` + `sac-implementation` |
| 安全审查 / 质量门禁 / 差异分析 / 发布就绪度检查<br>Security review / quality gates / diff analysis / release readiness | **审查者**<br>**Reviewer** | `sac-project` + `sac-quality` |
| 部署文档与参数描述更新<br>Deployment docs & parameter description updates | **实施者**（按需加载文档技能）<br>**Builder** (load documentation skill as needed) | `sac-project` + `sac-documentation` |

> **中文** — 小型任务不需要三个子代理。始终选择足以完成任务的最简角色序列。
>
> **English** — Small tasks do not require three sub-agents. Always choose the simplest role sequence sufficient to complete the task.

---

## 项目结构 / Project Structure

```
skills/                                          # 规范技能定义（核心交付物）
├── sac-project/SKILL.md                         # 项目范围与配置规则
├── sac-architecture/SKILL.md                    # 架构设计规则
├── sac-implementation/SKILL.md                  # 实现与 Terraform 规则
├── sac-quality/SKILL.md                         # 质量审查与验证规则
├── sac-documentation/SKILL.md                   # 文档生成规则
├── sac-deep-search/SKILL.md                     # 可选：深度搜索
├── sac-page-enhance/SKILL.md                    # 可选：页面增强
├── query-huawei-cloud-prices/                   # 可选：华为云价格查询技能
│   ├── SKILL.md
│   ├── scripts/                                 # 价格查询脚本
│   └── references/
└── reference/                                   # 共享参考文档
    ├── validation-checklist.md                  # 验证检查清单
    ├── security-check-rules.md                  # 安全检查规则
    ├── decision-framework.md                    # 决策框架
    ├── doc-templates.md                         # 文档模板规范
    ├── region-mapping.md                        # 区域代码映射表
    ├── docker-registry.md                       # 镜像加速与仓库规范
    └── skill-zone-rules.md                      # 技能上下文分区规则

.claude/                                         # Claude Code 适配层
├── CLAUDE.md                                    # 项目指令（事实源）
├── skills/                                      # 技能发现包装器 → 指向规范技能
├── agents/                                      # 角色定义（architect, builder, reviewer）
└── workflows/                                   # 工作流脚本

scripts/tests/                                   # 质量门禁测试运行器
├── runner.py                                    # Python 质量门禁入口
└── checks/                                      # 各维度检查实现

docs/contracts/                                  # 分发契约
├── npm-distribution.md                          # npm 包分发契约
├── practice-layout.md                           # 实践目录布局契约
├── release-contract.md                          # 发布契约
├── script-policy.md                             # 脚本策略契约
└── skill-status.md                              # 技能状态契约

project.config.json                              # 技能注册表与代理能力定义
package.json                                     # npm 包元数据
```

---

## 使用方式 / Usage

### 作为 npm 包安装 / Install as npm Package

```bash
npm install solution-practices
```

### 直接克隆仓库 / Clone the Repository

```bash
git clone https://github.com/Justin-TangPan/solution-practices.git
cd solution-practices
npm ci
npm test
```

### 在 Claude Code 中调用技能 / Using Skills in Claude Code

**一句话：进入项目目录打开 Claude Code，用自然语言描述你的任务即可，系统会自动匹配技能。**

**In short: open Claude Code in the project directory and describe your task in natural language — the system automatically routes to the right skills.**

---

#### 快速开始 / Quick Start

```bash
cd solution-practices
claude
# 然后直接输入你的需求，例如：
# 「帮我设计一个跨可用区高可用的 Web 架构」
# 「审查一下当前目录的 Terraform 变更」
# 「更新 network 模块，新增加密配置」
```

Claude Code 会根据你的问题类型，自动选择最合适的 AI 角色（架构师/实施者/审查者），并加载对应的 SAC 技能规则来指导工作。你不需要知道技能的具体名字，说清楚要做什么就行。

Claude Code automatically selects the best-fit AI role (Architect / Builder / Reviewer) based on your request and loads the matching SAC skills to guide the work. You don't need to know the skill names — just describe what you need.

---

#### 真实对话示例 / Real Conversation Examples

**示例 1：设计一个新方案**
```
用户：请帮我设计一个跨可用区高可用 Web 架构，使用 ELB + ECS + RDS
Claude → 自动识别为架构设计任务
       → 加载 sac-project + sac-architecture 技能规则
       → 按技能要求输出架构图、拓扑约束、高可用方案
```

**Example 1: Design a new solution**
```
User: Design a cross-AZ HA web architecture using ELB + ECS + RDS
Claude → auto-detects as architecture task
       → loads sac-project + sac-architecture rules
       → outputs topology, HA plan, architecture constraints per skill requirements
```

**示例 2：审查代码变更**
```
用户：帮我审查一下 infra/ 目录下的所有改动，看看有没有安全问题
Claude → 自动识别为审查任务
       → 加载 sac-project + sac-quality 技能规则
       → 按技能要求输出安全检查结果、一致性差异、发布就绪度评估
```

**Example 2: Review changes**
```
User: Review all changes under infra/ for security issues
Claude → auto-detects as review task
       → loads sac-project + sac-quality rules
       → outputs security findings, consistency diffs, release readiness
```

**示例 3：实现基础设施**
```
用户：在现有 VPC 里新增一个子网和对应的安全组，用 Terraform 实现
Claude → 自动识别为实现任务
       → 加载 sac-project + sac-implementation 技能规则
       → 按技能约束生成 Terraform 代码（变量、输出、安全组规则等）
```

**Example 3: Implement infrastructure**
```
User: Add a new subnet and security group in the existing VPC using Terraform
Claude → auto-detects as implementation task
       → loads sac-project + sac-implementation rules
       → generates Terraform code following skill constraints (variables, outputs, SG rules, etc.)
```

---

#### 为什么会自动匹配？ / How Does Auto-routing Work?

项目在 `.claude/agents/` 中定义了三种 AI 角色（`architect`、`builder`、`reviewer`），每个角色绑定了一组 SAC 技能。Claude Code 根据你的自然语言判断任务类型，将请求路由到对应的角色，该角色自动加载绑定的技能规则来约束输出。

The project defines three AI agent roles in `.claude/agents/` (`architect`, `builder`, `reviewer`), each bound to a set of SAC skills. Claude Code infers the task type from your natural language, routes your request to the matching role, and the role auto-loads the bound skill rules to govern its output.

> **你也可以手动指定角色**：输入 `/architect`、`/builder` 或 `/reviewer` 前缀，强制使用特定角色处理当前任务。
>
> **You can also specify a role manually**: prefix your request with `/architect`, `/builder`, or `/reviewer` to force a specific role.

---

## 开发指南 / Development Guide

### 前置要求 / Prerequisites

- Node.js >= 20
- Python 3.10+（quality gate tests）
- Git

### 验证命令 / Validation Commands

```bash
# Skills 结构测试（Node）/ Skills structure tests
npm test

# Python 质量门禁 / Python quality gate
.venv-sac/bin/python -m scripts.tests.runner

# 打包检查 / Package check
npm run pack:check
```

### 提交规范 / Commit Convention

```
<type>: <简短描述 / short description>

- <具体改动 1 / change 1>
- <具体改动 2 / change 2>

Co-Authored-By: Claude <noreply@anthropic.com>
```

类型 / Types: `feat` / `fix` / `refactor` / `test` / `docs` / `chore`

### Terraform 约定 / Terraform Conventions

**中文**
- 密码/密钥变量必须设置 `sensitive = true`
- 密码变量**不加** `validation` 块，由云 API 策略校验
- `validation` 块只能引用自身变量（不支持跨变量引用）
- 安全组规则必须限制源 IP，禁止 `0.0.0.0/0`
- 所有变量必须包含 `description` 字段
- 输出值使用独立 `output` 块，禁止 `|` 或逗号拼接
- 区域代码统一使用标准命名（`cn-north-4`、`ap-southeast-1` 等）

**English**
- Password/secret variables **must** set `sensitive = true`
- Password variables **do not** add a `validation` block — the cloud API enforces policy
- `validation` blocks can only reference their own variable (cross-variable refs unsupported)
- Security group rules must restrict source IP; `0.0.0.0/0` is prohibited
- All variables must include a `description` field
- Use standalone `output` blocks; no `|` or comma concatenation
- Region codes use standard naming (`cn-north-4`, `ap-southeast-1`, etc.)

---

## 版本历程 / Version History

| 版本 Version | 日期 Date | 概要 Summary |
|---|---|---|
| v0.17.1 | 2026-08-13 | README 中英双语重构；使用方式新增自然语言调用说明<br>Bilingual README restructuring; added natural language usage guide |
| v0.17.0 | 2026-08-12 | Skills 极简重构：以成功部署为核心<br>Minimalist Skills refactor: centered on successful deployment |
| v0.16.0 | 2026-08-11 | 最终清理：删除废弃工作流、悬空引用修复<br>Final cleanup: removed deprecated workflows, dangling ref fixes |
| v0.15.0 | 2026-08-11 | Skills-core 重新定位：收敛为纯技能项目<br>Skills-core repositioning: converged to pure skills project |
| v0.14.0 | 2026-08-07 | SAC Core 双适配（Codex + Claude Code），五个核心技能收敛<br>Dual adapter (Codex + Claude Code), 5 core skills convergence |
| v0.13.0 | 2026-08-06 | 工作流与仓库结构收敛，华为云价格查询技能<br>Workflow & repo structure convergence, Huawei Cloud price query skill |
| v0.12.0 | 2026-07-27 | 发布一致性修复，正式范围固化<br>Release consistency fixes, scope solidification |
| v0.11.0 | 2026-07-21 | Skills 精准路由与本地工具链<br>Precision routing & local toolchain |
| v0.10.0 | 2026-07-20 | SAC Web 纳入 GitHub 发布<br>SAC Web added to GitHub release |
| v0.9.x | 2026-07 | 文档流水线、npm CLI、多 Practice 候选发布<br>Doc pipeline, npm CLI, multi-Practice candidate release |
| v0.6.x | 2026-07 | 区域重构、安全修复、Supabase 方案完善<br>Region refactor, security fixes, Supabase completion |
| v0.5.x | 2026-06 | SAC Web 可视化平台、业务评估 Skill<br>SAC Web visualization platform, business assessment Skill |
| v0.4.x–v0.0.x | 2026-05~06 | 初始版本与迭代演进<br>Initial releases and iterative evolution |

详细变更请参阅 [CHANGELOG.md](CHANGELOG.md)。 See [CHANGELOG.md](CHANGELOG.md) for detailed changes.

---

## 安全注意事项 / Security Notes

- **不要** 在代码中提交真实 AK/SK、密码或令牌<br>  **Do not** commit real AK/SK, passwords, or tokens in code
- **不要** 提交 `.tfvars` 文件到仓库<br>  **Do not** commit `.tfvars` files to the repository
- **不要** 提交 `.secrets/`、`.env` 或 OBS 凭证<br>  **Do not** commit `.secrets/`, `.env`, or OBS credentials
- 敏感信息应通过环境变量或 RFS 参数传递<br>  Pass sensitive information via environment variables or RFS parameters
- 发现安全漏洞请联系维护者<br>  Report security vulnerabilities to the maintainers

---

## 许可 / License

[MIT](LICENSE)

---

## 相关链接 / Related Links

- [GitHub 仓库 / Repository](https://github.com/Justin-TangPan/solution-practices)
- [Issue 跟踪 / Issue Tracker](https://github.com/Justin-TangPan/solution-practices/issues)
- [贡献指南 / Contributing Guide](CONTRIBUTING.md)
- [所有权与资产归属 / Ownership](OWNERSHIP.md)
- [代理协作规则 / Agent Collaboration Rules](AGENTS.md)
