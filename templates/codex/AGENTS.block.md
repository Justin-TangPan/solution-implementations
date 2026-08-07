# SAC Solution Practices

SAC is an engineering package for architecture analysis, Terraform implementation, static validation,
documentation, and local delivery artifacts. It does not provide an independent agent runtime or deploy
cloud resources by itself. Read formal scope from `project.config.json`, or from
`.sac/project.config.json` in an npm-installed host.

Discover the canonical SAC Core Skills through `.agents/skills/`; do not create a `.codex/skills/` copy.
Use only the smallest sufficient capability role:

- Architecture or HA/topology changes: Architect → Builder → Reviewer → Builder Fix when needed.
- Terraform maintenance: Builder; add Reviewer for material risk.
- Quality, security, diff, or release review: Reviewer.
- Documentation: Builder with `sac-documentation` loaded on demand.
- Local packaging: Builder → Reviewer.

Codex-specific role and flow contracts live under `.codex/agents/` and `.codex/workflows/`. Preserve
existing work, keep concurrent write scopes disjoint, and keep Reviewer read-only. Static validation is
not live-cloud proof. Never infer permission to deploy resources, publish, commit, or push. Every
subagent returns `status`, `summary`, `files_changed`, `checks_run`, `issues`, and `handoff`.
