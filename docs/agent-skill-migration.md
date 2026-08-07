# Agent 与 Skill 迁移

阶段二把原先 Codex-centric 的六角色结构收敛为平台无关 SAC Core，再分别适配 Codex 与
Claude Code。兼容入口在本阶段保留；弃用不等于立即删除。

## Role Migration

| 旧角色 | 新能力角色 | 兼容状态 |
|---|---|---|
| Architect | Architect | 保留并收敛 |
| Developer | Builder | Deprecated compatibility |
| Documenter | Builder + Documentation | Deprecated compatibility |
| Tester | Reviewer | Deprecated compatibility |
| Security | Reviewer | Deprecated compatibility；安全规则保留在 Quality |
| Delivery | Builder + Reviewer | Deprecated compatibility |

Architect、Builder、Reviewer 是能力角色，不是每个任务必须启动的三个 Agent。最小充分 Flow
由 `project.config.json` 的 `agent_capabilities.task_flows` 定义。

## Skill Migration

| 旧 Skill | 新入口 | 分类 |
|---|---|---|
| `sac-project-rules` | `sac-project` | Compatibility |
| `sac-technical-evaluator` | `sac-architecture` | Compatibility |
| `sac-business-evaluator` | `sac-architecture` | Compatibility |
| `sac-rfs-practices` | `sac-implementation` | Compatibility |
| `sac-testing` | `sac-quality` | Compatibility |
| `sac-security` | `sac-quality` | Compatibility |
| `sac-delivery` | `sac-implementation` + `sac-quality` | Compatibility |
| `sac-documentation` | `sac-documentation` | Core |
| `sac-document-pipeline` | `sac-documentation` | Deprecated alias |
| `sac-deep-search` | 保持 | Optional |
| `sac-page-enhance` | 保持 | Optional / Extension |
| `query-huawei-cloud-prices` | 保持 | Optional |

旧 Skill 只转发到 Core，不再拥有独立业务规则。现有调用方仍可使用旧名称，但新 Agent、文档和
Workflow 必须使用 Core 名称。

## Runtime Migration

```text
Codex-centric
    ↓
SAC Core + Codex Adapter + Claude Code Adapter
```

- Codex 用户继续使用 `AGENTS.md`、`.agents/skills/`、`.codex/`；
- Claude Code 用户使用 `.claude/CLAUDE.md`、`.claude/skills/`、`.claude/agents/*.md`；
- 两端读取相同根 `skills/` 正文和 `project.config.json`；
- 用户修改保护、`.sac-new` 冲突和兼容入口在升级期间继续有效。
