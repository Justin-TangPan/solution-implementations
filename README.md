# Solution Practice Skills

**AI 编码代理的规范技能定义** — 面向华为云解决方案实践的工程规则、验证检查清单与架构合同。

[![npm version](https://img.shields.io/badge/version-0.17.2-blue)](https://github.com/Justin-TangPan/solution-practices)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **[English README](README_EN.md)**

---

## 概述

SAC（Solution Practice Skills）是一个 **skills-core** 项目。主要交付物是 `skills/` 目录下的规范 SKILL.md 文件，这些文件编码了 AI 编码代理在构建、审查和部署华为云解决方案实践时所需的工程规则、验证检查清单和架构设计合同。

项目本身**不调用语言模型**、**不提供 Agent Runtime**，也**不部署真实云资源**。技能文件是配置、提示词和工程规则，由宿主工具（如 Claude Code）读取和执行。

---

## 核心技能

| 技能 | 用途 |
|---|---|
| `sac-project` | 项目范围、目录布局、事实源与授权边界 |
| `sac-architecture` | 架构设计合同、拓扑、高可用方案与上游研究 |
| `sac-implementation` | Terraform 实现、变量、输出、user_data 与初始化脚本 |
| `sac-quality` | 静态验证、安全审查、一致性检查与发布门禁 |
| `sac-documentation` | 部署指南、参数表格与中英文双语文档生成 |

## 工作流引擎

多阶段 Practice 开发由 `workflows/engine.py` 编排，确保阶段间结构化数据传递与门控强制执行。

```bash
python workflows/engine.py start new-practice --inputs '{"project_name": "redis"}'
python workflows/engine.py next
python workflows/engine.py complete --phase architect --results '{"architecture_contract": {...}}'
python workflows/engine.py status
```

可用工作流：`new-practice`、`maintain-practice`、`architecture-change`、`small-change`、`review-practice`、`documentation-change`。

> **Plan B 入口**：`stages/README.md` — 将 Skills 重构为可执行 Pipeline Stage 的架构方向。

## 可选技能

| 技能 | 用途 |
|---|---|
| `sac-deep-search` | 争议性话题的跨领域、多来源深度研究 |
| `sac-page-enhance` | Web 呈现层增强 |
| `query-huawei-cloud-prices` | 华为云产品价格与规格实时查询 |

---

## 角色路由

项目定义三种核心 AI 角色，根据任务类型选择最简角色序列：

| 任务 | 推荐流程 | 所需技能 |
|---|---|---|
| 新方案 / 拓扑 / 高可用 / 数据库 / 存储 / 网络设计 | **架构师 → 实施者 → 审查者** | `sac-project` + `sac-architecture` + `sac-implementation` + `sac-quality` |
| Terraform 维护 / 变量 / 输出 / 初始化脚本变更 | **实施者**；中高风险加 **审查者** | `sac-project` + `sac-implementation` |
| 安全审查 / 质量门禁 / 差异分析 / 发布就绪度检查 | **审查者** | `sac-project` + `sac-quality` |
| 部署文档与参数描述更新 | **实施者**（按需加载文档技能） | `sac-project` + `sac-documentation` |

> 小型任务不需要三个子代理。始终选择足以完成任务的最简角色序列。

---

## 项目结构

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

## 使用方式

### 安装

```bash
# 通过 npm 安装
npm install solution-practices

# 或直接克隆仓库
git clone https://github.com/Justin-TangPan/solution-practices.git
cd solution-practices
npm ci
```

### 在 Claude Code 中使用

进入项目目录打开 Claude Code，用自然语言描述你的任务即可，系统会自动匹配技能。

```bash
cd solution-practices
claude
# 然后直接输入需求，例如：
# 「帮我设计一个跨可用区高可用的 Web 架构」
# 「审查一下当前目录的 Terraform 变更」
# 「更新 network 模块，新增加密配置」
```

Claude Code 会根据你的问题类型，自动选择最合适的 AI 角色（架构师 / 实施者 / 审查者），并加载对应的 SAC 技能规则来指导工作。**你不需要知道技能的具体名字，说清楚要做什么就行。**

#### 真实对话示例

**示例 1：设计一个新方案**

```
用户：请帮我设计一个跨可用区高可用 Web 架构，使用 ELB + ECS + RDS
Claude → 自动识别为架构设计任务
       → 加载 sac-project + sac-architecture 技能规则
       → 按技能要求输出架构图、拓扑约束、高可用方案
```

**示例 2：审查代码变更**

```
用户：帮我审查一下 infra/ 目录下的所有改动，看看有没有安全问题
Claude → 自动识别为审查任务
       → 加载 sac-project + sac-quality 技能规则
       → 输出安全检查结果、一致性差异、发布就绪度评估
```

**示例 3：实现基础设施**

```
用户：在现有 VPC 里新增一个子网和对应的安全组，用 Terraform 实现
Claude → 自动识别为实现任务
       → 加载 sac-project + sac-implementation 技能规则
       → 按技能约束生成 Terraform 代码（变量、输出、安全组规则等）
```

#### 自动匹配原理

项目在 `.claude/agents/` 中定义了三种 AI 角色（`architect`、`builder`、`reviewer`），每个角色绑定了一组 SAC 技能。Claude Code 根据你的自然语言判断任务类型，将请求路由到对应的角色，该角色自动加载绑定的技能规则来约束输出。

> 你也可以手动指定角色：在提示词前加 `/architect`、`/builder` 或 `/reviewer` 前缀，强制使用特定角色处理当前任务。

---

## 开发指南

### 前置要求

- Node.js >= 20
- Python 3.10+（质量门禁测试）
- Git

### 验证命令

```bash
# Skills 结构测试（Node）
npm test

# Python 质量门禁
.venv-sac/bin/python -m scripts.tests.runner

# 打包检查
npm run pack:check
```

### 提交规范

```
<type>: <简短描述>

- <具体改动 1>
- <具体改动 2>

Co-Authored-By: Claude <noreply@anthropic.com>
```

类型：`feat` / `fix` / `refactor` / `test` / `docs` / `chore`

### Terraform 约定

- 密码/密钥变量必须设置 `sensitive = true`
- 密码变量**不加** `validation` 块，由云 API 策略校验
- `validation` 块只能引用自身变量（不支持跨变量引用）
- 安全组规则必须限制源 IP，禁止 `0.0.0.0/0`
- 所有变量必须包含 `description` 字段
- 输出值使用独立 `output` 块，禁止 `|` 或逗号拼接
- 区域代码统一使用标准命名（`cn-north-4`、`ap-southeast-1` 等）

---

## 版本历程

| 版本 | 日期 | 概要 |
|---|---|---|
| v0.17.2 | 2026-08-13 | README 拆分为纯中文版 + 独立英文版 `README_EN.md`；使用方式新增自然语言调用说明 |
| v0.17.1 | 2026-08-13 | README 中英双语混排（后重构为拆分方案） |
| v0.17.0 | 2026-08-12 | Skills 极简重构：以成功部署为核心，删除过度限制，user_data 极简化 |
| v0.16.0 | 2026-08-11 | 最终清理：删除废弃工作流、悬空引用修复、61 个跟踪文件 |
| v0.15.0 | 2026-08-11 | Skills-core 重新定位：删除非核心资产，收敛为纯技能项目 |
| v0.14.0 | 2026-08-07 | SAC Core 双适配（Codex + Claude Code），五个核心技能收敛 |
| v0.13.0 | 2026-08-06 | 工作流与仓库结构收敛，华为云价格查询技能 |
| v0.12.0 | 2026-07-27 | 发布一致性修复，正式范围固化 |
| v0.11.0 | 2026-07-21 | Skills 精准路由与本地工具链 |
| v0.10.0 | 2026-07-20 | SAC Web 纳入 GitHub 发布 |
| v0.9.x | 2026-07 | 文档流水线、npm CLI、多 Practice 候选发布 |
| v0.6.x | 2026-07 | 区域重构、安全修复、Supabase 方案完善 |
| v0.5.x | 2026-06 | SAC Web 可视化平台、业务评估 Skill |
| v0.4.x–v0.0.x | 2026-05~06 | 初始版本与迭代演进 |

详细变更请参阅 [CHANGELOG.md](CHANGELOG.md)。

---

## 安全注意事项

- **不要** 在代码中提交真实 AK/SK、密码或令牌
- **不要** 提交 `.tfvars` 文件到仓库
- **不要** 提交 `.secrets/`、`.env` 或 OBS 凭证
- 敏感信息应通过环境变量或 RFS 参数传递
- 发现安全漏洞请联系维护者

---

## 许可

[MIT](LICENSE)

---

## 相关链接

- [GitHub 仓库](https://github.com/Justin-TangPan/solution-practices)
- [Issue 跟踪](https://github.com/Justin-TangPan/solution-practices/issues)
- [贡献指南](CONTRIBUTING.md)
- [所有权与资产归属](OWNERSHIP.md)
- [代理协作规则](AGENTS.md)
