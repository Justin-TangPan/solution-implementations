# architect-develop — Architecture-changing Maintenance

兼容原工作流名；用于原型或会改变拓扑、网络、数据库、存储、云资源或高可用的维护任务：

```text
Architect → Builder → Reviewer
```

Architect 只读形成架构合同；主 Agent 确认关键输入后交给 Builder 做最小实现；Reviewer 运行
静态质量、安全和合同一致性检查。发现阻断问题时回到 Builder 修复并复核。

本流程不自动打包、发布或创建云资源。原型必须列出文档、完整门禁和真实云测中未执行的项，
不得表述为正式发布或云上验证完成。
