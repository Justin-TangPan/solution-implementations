# Deprecated: Developer compatibility alias

旧入口 `sac_developer` 保留用于升级兼容。新任务使用 `.codex/agents/builder.md` 和
`sac_builder`；业务规则读取 `sac-project` 与 `sac-implementation`，不得从本文件推导规则。

被旧调用方直接使用时，按 Builder 的范围、授权、验证和 handoff 执行，并保留调用方要求的
旧字段。新 Workflow 不得路由到此别名。
