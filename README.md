<div align="center">

<img src="assets/branding/sac-logo.png" alt="SAC — Solution Practices" width="720">

### 面向 AI 编程工具的解决方案实践工程包

**Terraform / RFS · Codex / Claude Code**

</div>

SAC 可以配合 Codex、Claude Code 等 AI Coding Agent，辅助完成开源项目评估、云架构设计、
Terraform 模板开发、静态验证和交付物生成。
核心业务价值是生产、维护和验证 Solution Practice 的 Terraform 与配套交付物。

本仓库不直接调用大模型，也不提供独立 Agent Runtime 或多 Agent 调度引擎。Agent、Skill 和
Workflow 是供 Codex、Claude Code 等宿主工具读取的配置、提示词和工程规则；CLI 负责安装、
更新、检查和管理这些工程资产。

| 输入 | 处理过程 | 输出 |
|---|---|---|
| 开源项目仓库地址；已有解决方案需求；待开发或维护的 Terraform 方案 | 项目与依赖分析 → 云架构设计 → Terraform 开发 → 静态验证 → 文档与交付物生成 → 用户侧云环境验证 | 架构分析；Terraform 模板；部署文档；静态测试结果；待云测说明；本地交付包 |

默认只操作本地文件。静态检查不等于真实云部署验证；真实云资源变更、Git 提交、外部发布和
npm 发布均需单独授权。

## Quick Start（不超过 3 分钟）

需要 Node.js 20+。从源码安装当前 CLI：

```bash
git clone https://github.com/Justin-TangPan/solution-practices.git
cd solution-practices
npm ci
npm test
npm link
```

在需要接入 SAC 工程资产的目标仓库中执行：

```bash
cd /path/to/your-project
sac init
sac doctor
sac list
```

不使用全局链接时，可直接调用源码入口：

```bash
node /path/to/solution-practices/bin/sac.js init
```

`sac init` 安装 Codex Adapter、Claude Code Adapter、共享 SAC Core 和隔离工具链；不会通过 `postinstall`
修改项目，也不会静默覆盖用户文件。更新冲突会写为相邻的 `.sac-new` 文件供人工检查。
初始化或更新后，请重新启动 Agent 会话以重新发现工程资产。

当前公开命令：

```bash
sac init
sac install codex|claude|all|skills
sac install practice <name>
sac update [--dry-run]
sac list [--json]
sac doctor [--json]
```

## SAC Core 与 Coding Agent Adapter

根 `skills/` 维护平台无关的五类能力：Project、Architecture、Implementation、Quality 和
Documentation。Codex Adapter 负责 `AGENTS.md`、`.agents/skills/` 和 `.codex/`；Claude Code
Adapter 负责 `.claude/CLAUDE.md`、`.claude/skills/` 和原生 Subagent。两端共享业务规则，
但不共享 Agent 文件、frontmatter 或上下文加载方式。

| 使用方式 | 安装命令 | 原生入口 |
|---|---|---|
| Codex | `sac install codex` | `AGENTS.md`、`.agents/skills/`、`.codex/agents/` |
| Claude Code | `sac install claude` | `.claude/CLAUDE.md`、`.claude/skills/`、`.claude/agents/*.md` |
| 两者 | `sac init` 或 `sac install all` | 两套 Adapter 并存，共享根 `skills/` |

安装或更新后重启对应 Agent 会话。平台差异与迁移关系见
[Coding Agent 适配](docs/coding-agent-adapters.md)和
[Agent/Skill 迁移](docs/agent-skill-migration.md)。

## 使用方式

向已加载这些工程资产的 Codex 或 Claude Code 描述目标，例如：

```text
评估 https://github.com/<owner>/<project>，给出华为云架构方案；
确认部署决策后开发 Terraform，执行静态验证并生成本地交付物。
```

工程流程为：

```text
系统评估 → 初版方案 → 用户确认 → 架构合同 → Terraform 实现 → 静态测试 → 文档 → 本地交付
```

架构合同冻结前不开始实现。用户侧云测是单独阶段，其证据必须绑定到精确模板版本。

## 正式范围与交付物

正式 Practice 范围只由 [`project.config.json`](project.config.json) 的 `formal.practices` 定义；
`sac list` 和 Web 目录均从该范围读取。README 不再维护第二份项目清单。

每个正式 Practice 的核心交付物是：

- 每个 `site/region[/variant]` 的 Terraform；
- 每个站点的 Deployment Guide；
- 每个站点的 Solution Details。

`.extension`、DOCX、ZIP 和校验和按配置或明确请求生成。

## 仓库结构

```text
practices/                 # 正式 Terraform 与站点文档
project.config.json        # 正式范围与项目级策略的唯一事实源
skills/                    # 平台无关 SAC Core 与兼容入口的唯一权威源
.agents/skills/            # Codex 原生 Skill 发现入口
.codex/                    # Codex Adapter
.claude/                   # Claude Code Adapter 与旧入口兼容层
src/ bin/                  # CLI 安装、更新与诊断
scripts/tests/             # Practice 静态质量门禁
scripts/document_pipeline/ # 文档生成、转换与检查
scripts/archive/           # 禁止正式流程调用的历史脚本
release/                   # 本地交付产物
web/                       # 辅助性只读展示层
```

## 开发与验证

```bash
npm ci
npm test
.venv-sac/bin/python -m unittest discover -s scripts/tests -p 'test_*.py'
.venv-sac/bin/python -m scripts.tests.runner
npm ci --prefix web
npm run lint --prefix web
npm run build --prefix web
npm run pack:check
```

Python 门禁使用 HCL 解析和 `bash -n` 做离线静态检查，不执行 `terraform init`、`plan` 或
`apply`，不创建云资源，也不证明模板已在真实云环境成功部署。

## 项目事实与边界

- [事实源说明](docs/source-of-truth.md)
- [项目能力边界](docs/project-boundaries.md)
- [项目状态](docs/project-state.md)
- [Practice 目录合同](docs/contracts/practice-layout.md)
- [npm 分发合同](docs/contracts/npm-distribution.md)
- [SAC 项目规则](skills/sac-project/SKILL.md)
- [版本记录](CHANGELOG.md)

License: [MIT](LICENSE)
