# delivery-only — Local Packaging

兼容原工作流名；Task Flow 为：

```text
Builder → Reviewer
```

仅在用户明确授权本地打包且实现、文档和适用门禁已有证据时，Builder 整理现有正式文件、生成
确定性归档和 SHA-256；Reviewer 只读核对来源、内容、路径、校验和和未满足门禁。任何阻断项
均停止交付声明。

本地打包不授权外部发布、Git commit/push 或真实云资源操作。缺少精确候选云测证据时仍可
生成本地包，但必须明确“待云测”，不得声明 production ready。
