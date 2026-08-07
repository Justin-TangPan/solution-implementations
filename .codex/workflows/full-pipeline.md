# full-pipeline — New Practice

兼容原工作流名；对应平台无关 Task Flow：

```text
Architect → Builder → Reviewer → Builder Fix（仅有问题时）→ Reviewer
```

1. 主 Agent 收集上游地址、目标 `site/region[/variant]` 与用户约束，派发只读 Architect。
2. 主 Agent 审核架构候选，确认会改变拓扑、成本或公开入口的事项，并冻结
   `architecture_contract`；合同未完成时不得实现。
3. Builder 在不重叠的精确范围内实现 Terraform，并按需加载 Documentation 更新文档。
4. Reviewer 只读检查 Terraform、安全、架构/文档一致性和变更影响。
5. 阻断问题交回 Builder 最小修复，再由 Reviewer 复核。
6. 用户明确授权本地打包时，Builder 生成交付物，Reviewer 校验来源、归档和校验和。

缺少云测不阻止本地交付，但不得声明云上验证或 production ready。外部发布、Git 操作和真实
云资源变更始终需要独立授权。各阶段返回 AGENTS.md 规定的通用 handoff。
