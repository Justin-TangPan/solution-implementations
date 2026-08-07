# 决策点框架（公共参考文档）

> 本文档是 SAC 项目决策点框架的权威来源。主 Agent 完成系统评估和初版方案后，继承用户已明确的信息，只确认仍会改变交付范围或运行行为的决策。

| # | 决策点 | 选项 | 默认 |
|---|--------|------|------|
| 1 | 模板格式 | `.tf` (HCL) / `.tf.json` (JSON) | 推荐 `.tf`；按用户或 RFS 约束确认 |
| 2 | 安装策略 | 全内联 `user_data` | SAC 标准且唯一默认；模板自包含 |
| 3 | 站点与 Region | `cn` / `intl` + 该站点有效 Region | 问用户；已明确则继承 |
| 4 | 文档与扩展语言 | 中国站中文；国际站中英双语 | 跟随站点 |
| 5 | 部署架构 | `standard` / `ha` | 推荐最小充分架构；问用户确认 |
| 6 | 运行方式 | Docker Compose / 直接安装 | 按上游官方部署单元推荐并确认 |

## Decision 1: 模板格式

- `.tf`：可读性好，适合 heredoc 和内联 `user_data`，默认推荐。
- `.tf.json`：仅在用户或目标 RFS 接口明确要求 JSON 时使用。
- 同一 deployable instance 只能存在一种格式和一个可加载模板。

## Decision 2: 安装策略

Terraform 模板必须通过内联 `user_data` 完成依赖安装、配置生成、服务启动、健康检查和结果输出，保持单文件、自包含、可审计。`scripts/` 不属于标准安装链路。

## Decision 3: 站点与 Region

先确认站点，再从 `skills/reference/region-mapping.md` 选择该站点有效 Region。目录固定为：

```text
practices/<practice>/<site>/<region>/
```

只有同一 Region 需要多个部署形态时才增加 `<variant>/`；单一标准版的 Region 目录本身就是 deployable instance。

Region 不决定语言目录，也不得把香港等 Region 当作站点。

## Decision 4: 文档与扩展语言

- `cn`：中文 `.extension` 文案和 `cn/docs/` 中文文档。
- `intl`：一份共享 Terraform；`.extension` 同时提供 `zh-cn`、`en-us`，文档同时提供 `intl/docs/zh-cn/` 和 `intl/docs/en-us/`。
- 禁止用 `intl/<locale>/<region>/<variant>/` 复制 Terraform。

## Decision 5: 部署架构

- `standard`：满足目标负载的最小可运维拓扑；作为唯一形态时不建同名目录。
- `ha`：仅在用户明确需要高可用，且上游组件和华为云资源具备可验证的高可用设计时选择。

## Decision 6: 运行方式

- Docker Compose：上游提供可靠容器镜像，或应用由多个协同服务组成时优先。
- 直接安装：上游正式支持且单进程部署更简单时使用。
- 选择必须写入架构方案，不在实现阶段临时切换。
