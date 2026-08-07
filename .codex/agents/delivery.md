# Deprecated: Delivery compatibility alias

旧入口 `sac_delivery` 保留用于升级兼容。新流程由 Builder 组装获授权的本地交付物，再由
Reviewer 独立检查；规则来自 `sac-implementation` 与 `sac-quality`。

被旧调用方直接使用时只执行 Builder 阶段并保留旧交付 handoff 字段，明确提示仍需 Reviewer；
不得据此自行批准、外部发布、提交或推送。新 Workflow 不得路由到此别名。
