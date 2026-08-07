# 项目事实源

本仓库不使用数据库或配置中心。正式范围和项目级策略统一放在 `project.config.json`；其他
结构化文件只负责其所属工具必须拥有的数据，并通过测试防止重复字段独立漂移。

## 信息归属

| 信息 | 唯一负责人 | 维护方式 | 展示或消费方 |
|---|---|---|---|
| 正式 Practice、质量策略、Core Role/Skill、Task Flow、支持的 Runtime/Adapter | `project.config.json` | 人工维护策略；Python/Node 检查消费 | CLI、质量门禁、Adapter 测试、Web 索引 |
| Terraform、`.extension`、站点/Region/Variant、方案文档 | `practices/` | 人工开发；静态门禁验证 | CLI 安装、Web 构建、release 流程 |
| 项目/npm 版本、Node.js 下限、包内容和 CLI 入口 | `package.json` | npm 原生人工元数据；根锁文件和私有 Web 包版本由测试约束同步 | npm、CI、CLI、Web |
| Skill 行为 | `skills/*/SKILL.md` | 人工维护 | Codex/Claude Code 宿主工具 |
| Skill 展示名称、关键词和说明 | `skills-index.json` | 人工维护展示字段；分类和绑定受 `project.config.json` 约束 | Web Skills 页面、CLI 安装 |
| Codex 执行适配 | `AGENTS.md`、`.codex/agents/`、`.codex/workflows/` | 人工维护薄适配 | Codex Runtime |
| Claude Code 执行适配 | `.claude/CLAUDE.md`、`.claude/skills/`、`.claude/agents/*.md` | 人工维护薄适配 | Claude Code Runtime |
| 静态质量结果 | `scripts/tests/` 的当次执行输出 | 自动生成，不提交为长期状态 | CI、Web 构建快照、交付门禁 |
| Web Practice 结构索引 | `web/src/lib/practices-index.json` | `scripts/gen-practices-index.mjs` 自动生成 | Web 展示 |
| Web 文案、评分、架构示意 | `web/src/lib/data.ts`、`web/src/lib/architecture.ts` | 人工维护展示字段 | Web 展示 |
| Skill 向量缓存 | `skills-embeddings.json` | 可重建派生文件；当前 Runtime/CLI 不消费，不作为分类或路由证据 | 后续 Evals/检索实验 |
| 本地归档和校验和 | `release/` | 交付流程生成；不代表外部发布或云测成功 | 本地交付、Web 辅助展示 |

`package-lock.json` 对 npm 元数据的重复是包管理器生成的锁定结果，不是独立事实源。

## 展示层边界

README、`docs/project-state.md` 和 Web 只解释或展示事实，不维护正式 Practice 名单。Web 构建前
会从 `project.config.json` 与 `practices/` 重新生成索引；缺少人工文案的正式 Practice 仍必须
显示，并明确标为待补充，不能从正式范围中消失。

Web 中的 `score`、`tier`、`cost`、业务描述和手工架构示意都是人工维护字段，不是自动测试
结果。质量页只展示当次静态检查证据；它不证明 Terraform 已在真实云环境部署成功。

`docs/ppt/`、Headroom 报告、Dify 网页快照和旧业务分析是历史或演示材料，不定义当前范围、
价格、质量状态或产品能力。

## 修改规则

修改正式 Practice 范围时，只编辑 `project.config.json` 的 `formal.practices`，并确保对应
`practices/<name>/` 存在。随后运行：

```bash
node scripts/gen-practices-index.mjs
npm test
.venv-sac/bin/python -m scripts.tests.runner
npm run build --prefix web
npm run pack:check
```

CI 会验证生成索引没有漂移、Web 可构建且 npm 包包含全部 `practices/`。不得在 README、Web
组件或测试中再写一份正式名单。

## 后续去重

本阶段保留以下兼容重复，不做大规模重写：

- `skills-index.json` 保留 Core 分类和绑定镜像供展示；测试校验其与 `project.config.json` 一致，
  后续可评估从配置生成该部分。
- 旧六角色 Agent 和旧 Skill 名称：仅为升级兼容保留，替代关系见
  `docs/agent-skill-migration.md`。
- `skills-embeddings.json`：当前缓存包含旧索引且无正式消费方；后续在 Skills Evals 阶段从
  canonical Skill 重新生成或移除，阶段二不把它伪装为有效路由证据。
- 历史 PPT、业务报告和网页快照中的旧名称与指标：已降级为历史材料，后续统一归档。
- `project.config.json` 中尚未被全部检查器消费的人工策略字段：保留为明确策略，不把它们描述
  为已自动验证；后续按实际门禁逐项接入或移除。
