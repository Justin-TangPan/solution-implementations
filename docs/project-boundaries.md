# 项目能力边界

SAC 是面向 Codex、Claude Code 等 AI 编程工具的解决方案实践工程包。它提供共享 SAC Core、
Runtime Adapter、工程资产和可复现的本地检查，
不提供独立 AI Runtime。

## 核心正式能力

- 管理 `project.config.json` 所列正式 Practice；
- 开发和维护华为云 Terraform/RFS 方案；
- 执行 Terraform 语法、目录、网络、文档和项目策略的静态质量检查；
- 生成或维护部署文档、本地归档和校验和；
- 安装 Codex 或 Claude Code Adapter 以及共享 Core Skill；
- 通过 CLI 执行安装、更新、清单查询和诊断。

## 辅助能力

- Web 静态展示和项目状态浏览；
- 架构、质量、release 与 Skill 元数据的构建时快照；
- 文档转换、索引生成、OBS 兼容包装等本地开发工具。

辅助能力不定义正式 Practice 范围，也不覆盖 Terraform 与质量门禁事实。

## 当前不具备的能力

- 独立大模型 Runtime；
- 独立多 Agent 调度引擎；
- 由本仓库自行调用大模型；
- 自动创建或修改真实云资源；
- 自动证明 Terraform 已在真实云环境部署成功；
- 无人工参与的完整生产交付；
- 根据静态检查自动批准公网、成本、安全例外或外部发布。

Codex、Claude Code 等宿主可以依据仓库配置调度角色，但执行能力属于宿主。真实云验证由用户
在目标账号、Region 和模板版本上完成；结果需要作为单独证据记录，不能由本地静态门禁推断。
