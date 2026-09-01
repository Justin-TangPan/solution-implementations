# Plan B: Stage-Based Execution Model

> **入口点** — 当前已实施 Plan A（`workflows/`）。Plan B 在此预留架构方向。

## 愿景

将 Skills 从文本规则库重构为可执行的 Pipeline Stage，每个 Stage 具备：

- 结构化输入/输出 schema
- 可独立测试的 runner
- 明确的依赖声明
- 可组合的编排接口

## 架构对比

```
当前（Plan A — workflows/）          Plan B（stages/）
┌─────────────────────┐              ┌─────────────────────┐
│  workflow engine    │              │  workflow engine    │
│  (编排 + 状态 + 门控)│              │  (编排 + 状态 + 门控)│
└──────────┬──────────┘              └──────────┬──────────┘
           │                                    │
           ▼                                    ▼
┌─────────────────────┐              ┌─────────────────────┐
│  SKILL.md (文本)    │              │  stage/             │
│  - 业务规则         │              │  ├── schema.json    │
│  - 执行指令         │              │  ├── runner.py      │
│  - 依赖说明         │              │  └── SKILL.md       │
└─────────────────────┘              │    (降级参考)       │
                                     └─────────────────────┘
```

## 目标目录结构

```
stages/
├── sac-architecture/
│   ├── schema.json          # 输入/输出契约
│   ├── runner.py            # 可执行 Stage
│   └── SKILL.md             # 业务规则（降级为参考）
├── sac-implementation/
│   ├── schema.json
│   ├── runner.py
│   └── SKILL.md
├── sac-quality/
│   ├── schema.json
│   ├── runner.py
│   └── SKILL.md
├── sac-documentation/
│   ├── schema.json
│   ├── runner.py
│   └── SKILL.md
└── _templates/
    └── stage-template/      # 新建 Stage 的模板
```

## 收益

| 维度 | Plan A | Plan B |
|------|--------|--------|
| 类型安全 | 弱（文本规则） | 强（JSON Schema） |
| 可测试性 | 低（需人工审查） | 高（单元测试） |
| 可组合性 | 中（YAML 编排） | 高（Stage 即函数） |
| 可观测性 | 中（状态文件） | 高（结构化输出） |
| 迁移成本 | — | 中（需重写 Skills） |
| 向后兼容 | 完全兼容 | 需过渡期 |

## 迁移路径

1. **Phase 1** — Plan A 验证（当前）
   - 用 `workflows/` 验证编排模型
   - 收集 2-3 个 Practice 的运行数据

2. **Phase 2** — 试点 Stage 化
   - 选择 1 个 Skill（如 `sac-quality`）转换为 Stage
   - 保持 SKILL.md 作为降级参考

3. **Phase 3** — 渐进迁移
   - 逐个 Skill 转换为 Stage
   - 维护双向兼容（workflows/ 和 stages/ 并行）

4. **Phase 4** — 切换默认
   - 当所有 Stage 验证通过，切换默认执行路径
   - workflows/ 保留为兼容层

## 状态

⚠️ **Plan B 尚未实施。** 当前使用 `workflows/`（Plan A）进行工作流编排。

## 参考

- `workflows/` — 当前实施的工作流引擎
- `skills/` — 原始 Skills 库（业务规则来源）
- `project.config.json` — 技能注册和任务流定义
