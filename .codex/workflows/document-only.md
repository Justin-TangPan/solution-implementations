# document-only — Maintain Documentation

兼容原工作流名；默认由 Builder 加载 `sac-documentation`：

```text
Builder + Documentation → Reviewer（正式质量检查或发布前）
```

Builder 从已验证 Terraform、架构合同和现有文档提取事实，按请求生成、维护、翻译、转换或检查
部署指南与方案详情。只做小型参数说明时不启动额外 Agent；正式生成、跨语言更新或发布前检查
再由 Reviewer 核对实现和文档一致性。

`sac-document-pipeline` 仅是旧名兼容，页面营销任务另行使用 Optional `sac-page-enhance`。
不得臆造参数、价格、功能、URL 或云测结论，也不得为迁就文档修改 Terraform 行为。
