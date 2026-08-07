# Coding Agent 适配

SAC Core 的业务能力位于根 `skills/`，不依赖模型厂商或 Agent Runtime。Codex 和 Claude Code Adapter
只负责发现、调用、上下文和角色配置；相同 SAC 能力在不同 Runtime 下不要求采用相同实现。

| 能力 | Codex | Claude Code | SAC 处理 |
|---|---|---|---|
| 项目指令 | `AGENTS.md` | `.claude/CLAUDE.md` | 仅保留项目简介、路由、检查和授权边界 |
| Skill | `.agents/skills/` 直接发现根 `skills/` | `.claude/skills/` 薄包装 | 正文只在根 `skills/` 维护 |
| 专用 Agent | `.codex/agents/*.toml` | `.claude/agents/*.md` Subagent | 都映射 Architect / Builder / Reviewer |
| Workflow | `.codex/workflows/*.md` 合同 | 主会话 + Skill + Subagent | Task Flow 由 `project.config.json` 定义 |
| Core Rules | 共享 | 共享 | `sac-project`、`sac-architecture`、`sac-implementation`、`sac-quality`、`sac-documentation` |

## 上下文策略

Codex 启动时读取适用层级的 `AGENTS.md`，并看到 `.agents/skills/` 中的 Skill 名称和描述；命中后
才读取完整 `SKILL.md`。Claude Code 启动时全文加载 `.claude/CLAUDE.md`，同时只加载 Skill
元数据；命中后再加载薄包装并读取对应 Core。Claude Subagent 只预加载两项核心 Skill：

- Architect：`sac-project`、`sac-architecture`；
- Builder：`sac-project`、`sac-implementation`，文档按需加载；
- Reviewer：`sac-project`、`sac-quality`。

小任务不要求启动 Subagent。只有会显著污染主上下文的架构研究、大范围实现或完整审查才适合
委派。`.claude/rules/`、`.claude/commands/`、Hooks 和 Plugins 本阶段没有独立使用场景，因此
未创建。

## Task Flow 映射

| 任务 | 平台无关 Flow | Codex | Claude Code |
|---|---|---|---|
| 小型实现修改 | Builder | 主 Agent 或 Builder | 主会话加载 Implementation；必要时 Builder |
| 维护 Practice | Builder → Reviewer | 对应 Workflow 合同 | Builder/Reviewer 按范围使用 |
| 架构变化 | Architect → Builder → Reviewer | 主 Agent 编排自定义 Agent | 主会话按需委派三个 Subagent |
| 新 Practice | Architect → Builder → Reviewer → Builder Fix | `full-pipeline` 合同 | Skill 与 Subagent 串联 |
| 只读审查 | Reviewer | Reviewer | Reviewer 或主会话加载 Quality |

旧 `.claude/agents/*.json` 和 `.claude/workflows/*.js` 不是当前 Claude Code 原生项目入口，只为旧
集成保留。新实现不得依赖它们。

## 官方机制依据

- [Codex 的 AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Codex Skills](https://learn.chatgpt.com/docs/build-skills)
- [Codex Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Claude Code 项目指令](https://code.claude.com/docs/en/memory)
- [Claude Code Skills](https://code.claude.com/docs/en/slash-commands)
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents)
