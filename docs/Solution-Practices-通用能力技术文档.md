# Solution Practices 通用能力技术文档

本文说明 SAC 当前有效的 Skill 架构。业务规则以 `skills/sac-project-rules/SKILL.md`、
`skills/sac-rfs-practices/SKILL.md`、`project.config.json` 和 `docs/project-state.md` 为准。

## 1. 设计原则

- 主 Agent 是唯一编排者，也是解决方案实践架构师。
- 新项目必须先完成系统评估和初版方案，再确认站点、Region、部署形式及产品特有输入。
- 用户确认后冻结架构合同，子 Agent 只在合同和文件所有权范围内工作。
- 正式流程以本地、可校验的交付包结束，不包含外部发布或真实云资源变更。
- 国际站的语言差异只存在于 `docs/zh-cn` 与 `docs/en-us`，不改变实现目录层级。

## 2. Skill 分层

| 层 | Skill | 职责 |
|---|---|---|
| 规则 | `sac-project-rules` | 真值优先级、架构门、目录、版本和本地交付合同 |
| 实现 | `sac-rfs-practices` | Terraform/RFS、内联 `user_data`、区域与安全约束 |
| 评估 | `sac-business-evaluator` | 业务价值与继续评估阈值 |
| 评估 | `sac-technical-evaluator` | 只读技术可行性、资源和风险评估 |
| 研究 | `sac-deep-search` | 仅在需要外部证据时补充研究 |
| 验证 | `sac-testing` | 静态检查、策略检查和测试门禁 |
| 验证 | `sac-security` | 凭证、暴露面、供应链和交付包审计 |
| 文档 | `sac-documentation` | 维护或生成 Markdown、翻译、可选 DOCX 与文档门禁 |
| 文档 | `query-huawei-cloud-prices` | 按需查询实时价格，不维护本地价格表 |
| 兼容 | `sac-document-pipeline` | 旧名称入口，仅转交 `sac-documentation` |
| 文档 | `sac-page-enhance` | 已有页面的窄范围内容增强 |
| 交付 | `sac-delivery` | 本地 release 目录、归档、SHA-256 和一致性验证 |

Agent 实际加载以 `.codex/agents/` 角色合同为准；`skills-index.json` 只用于发现、展示和审计。

## 3. 主流程

```text
用户需求
  -> 主 Agent 系统评估与初版方案
  -> 用户确认站点 / Region / standard|ha / 关键输入
  -> 冻结架构合同
  -> Developer 实现
  -> Tester 静态验证（Security 按需）
  -> Documenter 生成站点文档
  -> Delivery 生成本地 ZIP + SHA256SUMS
  -> 主 Agent 最终门禁与汇报
```

快速原型可在架构合同冻结后停止于实现阶段；审计流程默认只读。用户在目标云环境验证候选
版本是独立步骤，静态门禁和本地交付不能替代该证据。

## 4. 目录与语言

```text
practices/{project}/
├── cn/{region}[/variant]/deploying-{project}_vN.tf
├── cn/docs/
├── intl/{region}[/variant]/deploying-{project}_vN.tf
└── intl/docs/{zh-cn,en-us}/
```

- `site` 是 `cn` 或 `intl`。
- `region` 使用真实云区域代码。
- `variant` 仅在同一 Region 有多个部署形态时出现，名称由产品合同决定。
- 安装、配置、Docker Compose 和健康检查逻辑内联在 Terraform `user_data` 中。
- 不创建依赖外部托管位置的安装脚本。

## 5. 架构合同

主 Agent 冻结的合同至少包括：

- `system_assessment`、`initial_solution`、`user_inputs_required`；
- 站点、Region、variant、模板格式和容器化方式；
- 资源拓扑、依赖、容量、可用性、安全、成本、运维和恢复设计；
- 客户变量、固定值、公开入口、允许文件、偏差和风险；
- 适用规则和精确参考模板路径。

任何改变成本、暴露面、官方默认、交付范围或外部依赖的偏差，都必须重新获得用户确认。

## 6. 质量门禁

交付前至少满足：

1. Terraform/HCL、JSON 和内联脚本语法通过。
2. `rfs_policy`、变量验证、依赖链和区域约束通过。
3. 文档只使用可追溯事实；估算值明确标记依据和假设。
4. 国际站中英文语义一致。
5. 本地归档内容与源资产一致，SHA-256 可复核。

安全审计和用户云测按任务需要单独执行；没有对应证据时不得声称已经通过。

## 7. Agent 边界

- Architect 只读评估并回交主 Agent，不直接派发开发。
- Developer 只修改被分配的实现目录。
- Tester 和 Security 默认只读。
- Documenter 只修改被分配语言的 `docs/`。
- Delivery 只整理本地 `release/`、归档和校验和。
- 主 Agent 负责共享文件、冲突处理、最终门禁和本地内部变更记录。

外部发布、Git 操作和真实云资源变更不属于上述正式交付流程，必须作为独立请求处理。
