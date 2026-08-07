# Claude Code adapter

The Claude Code adapter maps the shared SAC capability model to Claude-native project instructions, Skills,
and subagents. SAC business rules stay canonical under `skills/`; this directory contains runtime-specific
discovery and routing only.

## Native entry points

| Purpose | Claude Code entry | Default Skill preload |
|---|---|---|
| Project instructions | `.claude/CLAUDE.md` | none |
| Architecture capability | `.claude/agents/architect.md` | `sac-project`, `sac-architecture` |
| Build capability | `.claude/agents/builder.md` | `sac-project`, `sac-implementation` |
| Review capability | `.claude/agents/reviewer.md` | `sac-project`, `sac-quality` |
| Skill discovery | `.claude/skills/<name>/SKILL.md` | task-dependent |

`sac-documentation` is deliberately not preloaded into Builder. Builder loads it only for deployment guides,
parameter documentation, README changes, translation, or delivery-document work. Optional Skills such as deep
search and page enhancement are not part of the default Terraform path.

## Task flows

These are capability flows, not a requirement to start three subagents for every task.

| Task | Flow |
|---|---|
| Small Terraform or text-only change | Builder |
| Maintain an existing Practice | Builder -> Reviewer |
| Architecture-changing maintenance | Architect -> Builder -> Reviewer |
| New Practice | Architect -> Builder -> Reviewer -> Builder fix if needed |
| Read-only audit | Reviewer |
| Documentation-only maintenance | Builder + `sac-documentation` |

Subagents are useful for independent research, broad implementation, or a review that would pollute the main
context. The main Claude session may perform a small task directly while loading the same relevant Skill.

## Context strategy

At startup Claude Code receives the lightweight `.claude/CLAUDE.md` plus Skill metadata. Canonical Skill bodies
are loaded only after routing. A native subagent gets only its two preloaded core Skills; it does not preload all
five core Skills, optional extensions, compatibility aliases, workflows, or legacy Agent definitions.

The distinct Skill descriptions support automatic selection. Users may also invoke a core Skill explicitly as
`/sac-project`, `/sac-architecture`, `/sac-implementation`, `/sac-quality`, or `/sac-documentation`. Skills run
in the current context; native subagents provide isolated context only when the task warrants it.

No `.claude/rules/` or `.claude/commands/` layer is added because it would repeat the same routing rules. Hooks
and plugins remain user/runtime concerns and are not required for SAC correctness.

## Legacy compatibility

The six `sac-*.json` files under `.claude/agents/` and five JavaScript files under `.claude/workflows/` describe
the repository's previous custom Workflow DSL. They are retained for existing integrations but are deprecated
and are not Claude Code's native subagent or workflow format.

| Legacy role | Native replacement |
|---|---|
| `sac-architect` | `architect` |
| `sac-developer` | `builder` |
| `sac-documenter` | `builder` + `sac-documentation` |
| `sac-tester` | `reviewer` |
| `sac-security` | `reviewer` |
| `sac-delivery` | `builder` + `reviewer` |

Do not use legacy workflow files as evidence that Claude Code supplies a JavaScript Workflow runtime. New work
should use the native Skill/subagent flows above; remove compatibility files only in a separately announced
breaking release.
