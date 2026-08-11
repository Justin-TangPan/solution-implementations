# Skill 加载规则

## 运行时真相

`project.config.json` 定义能力角色和 Skill 分类。`AGENTS.md` 与
`.claude/` 分别实现 Runtime 适配。

## 最小加载

每个角色默认只加载项目总纲和一个角色 Skill：

| 角色 | 必需 Skill | 条件 Skill |
|---|---|---|
| Architect | `sac-project`、`sac-architecture` | 复杂多源研究时加载 `sac-deep-search` |
| Builder | `sac-project`、`sac-implementation` | 文档任务加载 `sac-documentation`；实时成本再加载价格 Skill |
| Reviewer | `sac-project`、`sac-quality` | 无 |

所有旧名仅为兼容入口，不再加载。
任务结束后清空本次 Skill 上下文。不得为了“可能有用”加载条件 Skill。
