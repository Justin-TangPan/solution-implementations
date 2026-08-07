# SAC Codex 协作规则

本仓库是面向 Codex 等 AI 编程工具的解决方案实践工程包。Terraform 方案生产与验证是核心
价值；仓库不直接调用大模型，也不提供独立 Agent Runtime。正式范围与项目级配置以
`project.config.json` 为准，SAC 业务规则的唯一权威源是根目录 `skills/`。

Codex 从 `.agents/skills/` 发现这些 Skill；该入口映射根 `skills/`，不得维护
`.codex/skills/` 副本。`.codex/` 只保存 Codex 专用角色与 Task Flow 适配。

## 任务路由

按最小充分角色执行，不要求每项任务都启动多个 Agent：

| 任务 | 角色 / 流程 | Core Skill |
|---|---|---|
| 新 Practice、拓扑/云资源选择、数据库/存储/网络/高可用变化 | Architect → Builder → Reviewer → 必要时 Builder Fix | `sac-project`、`sac-architecture`、`sac-implementation`、`sac-quality` |
| 维护 Terraform、变量、output、初始化脚本 | Builder；中高风险时追加 Reviewer | `sac-project`、`sac-implementation` |
| 安全、质量、diff 或发布前审查 | Reviewer | `sac-project`、`sac-quality` |
| 部署文档和参数说明 | Builder 按需加载 Documentation | `sac-project`、`sac-documentation` |
| 本地交付物整理 | Builder → Reviewer | `sac-implementation`、`sac-quality` |

小范围修改由主 Agent 直接承担相应能力角色。只有独立研究、大范围实现或审查会显著污染
主上下文时，才调度 `.codex/agents/`；主 Agent 始终负责最终范围、架构判断和结果整合。
五个兼容 Workflow 保留在 `.codex/workflows/`，但仅使用 Architect、Builder、Reviewer。

## 工作原则

- 开始前运行 `git status --short`；保留用户和并行任务已有修改，写入范围不得重叠。
- 修改前搜索全部引用；优先最小变更，不改变未获授权的 Terraform 资源、变量默认值或部署行为。
- `reference/` 默认只读；不得把凭证、Token、私有地址写入产物或日志。
- Reviewer 默认只读。修复必须由主 Agent 明确交给 Builder，修复后重跑受影响检查。
- 静态检查不是云上验证；没有精确候选的真实云测证据时，不得宣称已部署或 production ready。
- 外部发布、Git commit/push、真实云资源操作均需用户逐项明确授权。
- 子 Agent 返回 `status`、`summary`、`files_changed`、`checks_run`、`issues`、`handoff`。

## 验证入口

按变更范围运行最小充分检查，并报告未运行项及原因：

- Node 与 Adapter/CLI：`npm test`
- Python 与 Practice：`.venv-sac/bin/python -m unittest discover -s scripts/tests -p 'test_*.py'`
- Terraform 静态门禁：`.venv-sac/bin/python -m scripts.tests.runner [--practice <project>]`
- Web 变更：在 `web/` 运行 `npm run lint`、`npm run build`
- 安装器或 npm 内容：`npm pack --dry-run`

Python 使用仓库根目录 `.venv-sac`。每批修改记录到不提交、不发布的
`.var/log/internal-changelog.md`。
