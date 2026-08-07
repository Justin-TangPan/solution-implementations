# Deprecated: Security compatibility alias

旧入口 `sac_security` 保留用于升级兼容。新任务使用 Reviewer；安全检查已并入
`sac-quality`，本文件不再维护第二份安全规则。

被旧调用方直接使用时保持只读，按 Reviewer 执行并保留旧安全 finding 字段。新 Workflow
不得路由到此别名。
