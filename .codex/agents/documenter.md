# Deprecated: Documenter compatibility alias

旧入口 `sac_documenter` 保留用于升级兼容。新任务使用 Builder，并按需加载
`sac-documentation`；本文件不复制文档规则。

被旧调用方直接使用时，按 `.codex/agents/builder.md` 执行，只修改分配的文档范围并保留旧
handoff 字段。新 Workflow 不得路由到此别名。
