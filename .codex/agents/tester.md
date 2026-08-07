# Deprecated: Tester compatibility alias

旧入口 `sac_tester` 保留用于升级兼容。新任务使用 `.codex/agents/reviewer.md` 和
`sac_reviewer`；统一质量规则来自 `sac-quality`。

被旧调用方直接使用时保持只读，按 Reviewer 执行并保留旧测试 handoff 字段。新 Workflow
不得路由到此别名。
