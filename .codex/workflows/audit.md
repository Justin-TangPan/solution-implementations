# audit — Review Practice

兼容原工作流名；默认 Task Flow 为只读 Reviewer：

```text
Reviewer → Builder Fix（仅用户要求修复时）→ Reviewer
```

Reviewer 按用户范围统一执行 Terraform 质量、安全、架构/文档一致性、diff 或交付物检查，保留
命令、退出码、文件位置和证据，并区分阻断、非阻断、Accepted Risk 与云测边界。

未明确要求修复时不得写文件。获得修复授权后，主 Agent 把精确范围交给 Builder，随后只重跑
受影响的 Reviewer 门禁。审计不生成 release，也不把静态结果表述为真实部署成功。
