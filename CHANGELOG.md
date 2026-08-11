# Changelog

## v0.16.0 (2026-08-11) — Final cleanup and workflow removal

### Breaking changes

- Removed deprecated `.claude/workflows/*.js` (sac-architect-develop, sac-audit, sac-delivery-only,
  sac-document-only, sac-full-pipeline) — all referenced removed agent types and paths.
- Removed `.claude/workflows/*.js` from npm `files` in package.json.
- Removed untracked stale files from disk: `reference-architecture.html`, `skills-embeddings.json`.

### Improvements

- Fixed dangling references in CONTRIBUTING.md, OWNERSHIP.md, skills/sac-documentation/SKILL.md,
  skills/sac-implementation/SKILL.md, docs/contracts/practice-layout.md — all now skills-core clean.
- 61 tracked files, 0 dangling references, npm test 3/3 pass.

## v0.15.0 (2026-08-11) — Skills-core repositioning

### Breaking changes

- Repositioned project as **skills-core**. The primary deliverable is `skills/` — canonical SKILL.md files.
- Removed from git tracking: `practices/`, `release/`, `web/`, `assets/`, `reference/`, `src/`, `bin/`, `.codex/`,
  `scripts/archive/`, `scripts/document_pipeline/`, `scripts/obs/`, `docs/ppt/`, `docs/headroom-*/`,
  `skills-index.json`, and all compatibility/deprecated skills and agents.
- Removed `codex` from `supported_runtimes` in `project.config.json`.
- Removed `skills.compatibility` and `skills.deprecated` from `project.config.json`.
- Removed CLI entry point (`bin/sac.js`, `src/`).

### Improvements

- Added Terraform validation conventions to `sac-implementation/SKILL.md`:
  validation self-reference only, no password validation, flavor format check only.
- Added validation review checks to `sac-quality/SKILL.md`.
- Strengthened output convention: no decorative separators, each value is its own `output` block.
- Rewrote `README.md`, `AGENTS.md`, `.claude/CLAUDE.md` for skills-core positioning.
- Slimmed `package.json` (v0.15.0), `project.config.json`, `.github/workflows/ci.yml`, `.gitignore`, `.npmignore`.
- Rewrote `test/skills.test.js` to work without `skills-index.json` and `.codex/`.

## v0.14.0 (2026-08-07) — SAC Core 与 Codex / Claude Code 双适配

### 改进

- 将平台无关能力收敛为 Project、Architecture、Implementation、Quality、Documentation 五个 Core Skill。
- 将核心能力角色收敛为 Architect、Builder、Reviewer，并分别提供 Codex 与 Claude Code 原生适配。
- CLI 支持安装 Codex、Claude Code 或双平台资产，延续 merge block、`.sac-new` 和 Dry Run 保护。
- PR、main 与 Tag 复用同一基础质量门禁；正式范围、能力模型和 Adapter 继续由结构化事实源约束。

### 兼容性与验证

- 旧 Agent、Skill 和 Workflow 入口保留为 Deprecated/Compatibility，不改变已有用户安装入口。
- Node 31 项、Python 19 项及 38 个 Practice 实例的 536 项静态检查通过；Web lint/build 与 npm pack dry-run 通过。
- 本版本的静态验证不代表所有 Terraform 已在真实云环境完成部署验证。

## v0.13.0 (2026-08-06) — SAC 工作流与仓库结构收敛

### 改进

- 统一 Codex 与 Claude Code 的 Agent、工作流和 Skill 分发入口。
- 收敛 Practice 目录、质量门禁、正式方案清单与 Web 索引。
- 重塑 README，并补充华为云实时价格查询能力。

## v0.12.0 (2026-07-27) — SAC 核心交付与发布一致性修复

### 修复

- 将 Hermes 内联 Terraform 基线纳入 npm 包，移除 bootstrap 中对 ECS 密码的敏感插值。
- 同步正式 practice 范围、CLI 测试、项目状态与 npm 打包清单。
- 固化 Terraform、部署指南和方案详情为核心 SAC 交付，并恢复测试、安全和文档发布门禁。
- 用户确认 AstrBot 中国站标准版云测通过；候选模板已晋升，并生成仅本地的 v0.12.0 release 包。
- OmniRoute 暂不纳入仓库或对外发布，已从正式范围、npm 包和工作台索引移除。

### 验证

- npm 测试、SAC 静态门禁和 npm 打包清单检查通过；新增候选仍需用户确认云测后才能晋升正式 release。

## v0.11.0 (2026-07-21) — Skills 精准路由与本地工具链

### 新功能

- 将 11 个 SAC Skills 收敛为最小角色路由，新增主 Agent 的系统评估、初版方案、用户确认和架构合同门禁。
- npm 安装新增 Skill 索引、隔离的文档/测试工具链、二进制 DOCX 模板无损更新和更完整的 `sac doctor`。
- Web 新增架构工作区和交付准备度视图，下载资产仅从正式 Practice 生成。

### 治理与边界

- 正式交付统一为本地确定性归档与 `SHA256SUMS`，移除 OBS 上传、托管 URL 和 Web OBS 管理入口。
- 同步 Codex、Claude、项目合同和 README；业务评估、深度搜索及页面增强保持按需加载。

### 验证

- 14 个 npm 测试、11 个文档流水线测试和 11 个 Skill 验证通过。
- 22 个正式实例共 307 项门禁检查无错误；Web lint/build 和 npm pack 检查通过。

## v0.10.0 (2026-07-20) — SAC Web 正式纳入 GitHub 发布

### 新功能

- 将现有 `web/` 可视化工作台源码纳入 GitHub 正式版本，保留 Next.js 静态导出能力。
- 工作台覆盖交付任务、方案目录、业务评估、质量门禁、资产、发布记录、报告和只读 Terraform/文档预览。
- 新增基于 Git 标签的 GitHub Actions 发布流程；推送 `v*` 标签后自动生成发布说明并标记为 Latest Release。

### 治理与边界

- `web/` 成为正式 GitHub 源码资产，但继续保持只读展示层定位，不作为 practice、质量或发布状态的事实源。
- 构建缓存、依赖和静态导出目录继续排除，仅发布可复现的 Web 源码与锁文件。
- 方案索引严格按正式范围生成，修正国际站文档目录读取，并在质量报告缺失或损坏时阻断构建，避免假绿灯。
- 发布页将本地 `release/` 资产明确标记为“本地已打包”，不再推断为已经外部发布。
- 固定正式质量门禁使用的 HCL2 解析依赖，确保 GitHub 的干净环境与本地验证一致。

### 验证

- Web 执行 ESLint 与 Next.js 静态构建。
- 仓库执行 Node 测试、SAC 正式质量门禁和 npm 打包清单检查。

## v0.9.2 (2026-07-17) — 三方案正式释放包

### 正式晋级

- 用户确认 LiteLLM、OpenJiuwen、Supabase 全部现有部署实例云测通过。
- LiteLLM 9 个高可用候选、OpenJiuwen Agent Studio 候选和 Supabase 国际站候选晋级为唯一无版本正式入口。
- 保留 LiteLLM 已上线高可用架构及其 `huaweicloud` + `kubernetes` Provider 组合，不修改部署逻辑。

### 结构与命名

- 国际站 Terraform 实现收敛为 `intl/<region>/<variant>/`，删除多余的 `en-us/zh-cn` 实现层；语言仅保留在站点级文档中。
- 每个部署实例只保留一个 `deploying-<project>.tf`；交付文件名按站点、Region 和部署类型区分。
- 三个方案的正式文档统一为部署指南与方案详情，中国站中文、国际站中英文最多六份。

### 验证

- 正式释放前执行全量 Terraform、Shell、结构、文档和安全门禁。
- 仅生成本地释放包；未执行 OBS 上传、外部发布、真实云资源变更或 Git 提交。

## v0.9.1 (2026-07-16) — 文档流水线与 Practice 候选更新

### 新功能

- **文档生产流水线** — 新增可追溯标准稿、翻译保护、双语 Markdown、IDP Word 渲染、质量检查和文档专用工作流。
- **OpenJiuwen 双候选** — 将 Agent Studio 与 JiuwenSwarm 拆分为独立候选变体，补齐 JiuwenSwarm 部署指南和方案详情。
- **Practice 候选升级** — 新增 Supabase `v6` 三站点候选和 LiteLLM 多区域 HA 候选。

### 质量与治理

- 新增 RFS Practice 策略检查，并扩展 Terraform、网络、文档及双语一致性门禁。
- 同步 Codex/Claude Agent 契约、工作流、Skill 索引与 npm 分发范围。
- 用户确认 Supabase CN `v6` 与 JiuwenSwarm `v4` 云测通过，两个候选已保留并字节级晋升为无版本正式入口；Agent Studio 与 Supabase INTL 仍未晋升。

### 修复

- **国际站路径隔离** — OBS 对象前缀和归档名加入 `site/locale`，避免同一区域的 `en-us` 与 `zh-cn` 测试产物互相覆盖。
- **OBS SDK 兼容** — 回读优先使用当前 SDK 的 `loadStreamInMemory`，并兼容旧 SDK 的 `loadStreamInMS` 参数。
- **上传后校验** — zip 和 manifest 上传后立即回读并比较 SHA-256，校验失败时不再宣告上传完成。

### 验证

- 新增 locale 路径、归档命名及新旧 OBS SDK 回读的单元测试。
- 保持凭证仅从环境变量读取，不写入 manifest、归档或日志。

### 关键文件

- `scripts/obs/upload.py`
- `scripts/obs/test_upload.py`
- `scripts/obs/spec.md`
- `scripts/README.md`
- `.gitignore`

## v0.9.0 (2026-07-10) — npm CLI 与 Codex 原生多 Agent 分发

### 新功能

- **npm CLI** — 新增 `solution-practices` 包和 `sac` 命令，支持 `init`、组件/方案安装、更新预览、健康检查和内容列表。
- **安全升级** — 使用 `.sac/manifest.json` 跟踪 schema、版本和文件哈希；用户修改的受管文件输出 `.sac-new`，不静默覆盖。
- **Codex 原生编排** — 新增项目级 `AGENTS.md`、六个 TOML 自定义 Agent 和四个 Codex 工作流，并保留 Claude Code 兼容层。
- **正式工作流 Skills** — 新增测试、安全、文档和交付四个 Skill，并绑定对应 Codex Agent。

### 治理与验证

- 新增 npm 分发契约、公共接口稳定性、manifest migration、文件所有权和发布授权边界。
- npm tarball 仅包含 `litellm`、`supabase`、`openjiuwen` 三个正式 practice，排除历史方案、缓存和内部产物。
- Node CLI 测试、四个 Skill 格式验证、SAC 全量质量门禁和真实 tarball 安装链均通过。
- 本版本仅完成本地可发布包；未执行 npm 发布、OBS 上传、Git 提交或云资源变更。

## v0.8.5 (2026-07-10) — Supabase 部署修复验证发布

### 修复验证
- **cloud-init 脚本修复** — 修正 Terraform 内联 `user_data` 的外层缩进，确保 shebang 位于首字节且所有内层 heredoc 正确闭合
- **实际云测通过** — `0.8.4.1` Supabase 整体测试包经用户确认部署测试通过
- **完整归档** — CN、INTL 中英文模板、`.extension` 和文档已组成整体包并完成远端大小与 SHA-256 校验

### 发布信息
- **测试版本**：`0.8.4.1`
- **正式版本**：`0.8.5`
- **发布范围**：Supabase CN + INTL zh-cn/en-us

### 关键文件
- `practices/supabase/cn/cn-north-4/standard/terraform/deploying-supabase.tf`
- `practices/supabase/intl/zh-cn/ap-southeast-1/standard/terraform/deploying-supabase-ap-southeast-1.tf`
- `practices/supabase/intl/en-us/ap-southeast-1/standard/terraform/deploying-supabase-ap-southeast-1.tf`

## v0.8.4 (2026-07-10) — 模板版本治理与发布门禁

### 规则更新
- **Terraform 候选版本化** — 新建或修改模板使用 `deploying-{solution}_vN.tf` 不可变候选，用户确认测试通过后再提升无版本正式入口
- **测试与正式版本分离** — 正式发布使用三级版本，待验证修改使用 SAC 四级测试版本，并明确四级版本不是 SemVer
- **发布门禁** — 增加用户测试确认、候选与正式入口一致性、云上运行验证、文档和安全一致性要求

### 项目治理
- **渐进迁移** — 保留历史模板和既有 RFS/OBS 链接，现有无版本模板在下一次修改时进入 `_v1` 候选流程
- **范围校准** — 项目状态同步正式 practice `litellm`、`supabase`、`openjiuwen`
- **职责边界** — 通用治理进入项目规则，RFS 模板执行流程进入 `sac-rfs-practices`
- **凭证治理** — Supabase OBS 上传兼容入口改为参数化包装器，移除硬编码测试凭证和本机绝对路径
- **Skill 结构标准化** — 清除正式 skill 的 BOM，并将项目分类字段归入受支持的 `metadata`

### 关键文件
- `skills/sac-project-rules/SKILL.md`
- `skills/sac-rfs-practices/SKILL.md`
- `docs/contracts/practice-layout.md`
- `docs/contracts/release-contract.md`
- `docs/project-state.md`

## v0.8.3 (2026-07-10) — 新增 openJiuwen Agent Studio 首版实践

### 新功能
- **openJiuwen 单机标准版** — 新增 `cn-north-4` 标准版 Terraform 模板，自动创建 VPC、ECS、安全组、EIP，并通过内联 `user_data` 部署 openJiuwen Agent Studio 官方 Docker 版本包
- **官方部署路径适配** — 模板使用官方 `deployTool_0.1.5_amd64.zip`，生成 `.env.custom` 后执行 `service.sh up -n`
- **文档交付** — 新增中文部署指南与中文方案详情，文件名遵循 `_zh` 新标准

### 关键文件
- `practices/openjiuwen/cn/cn-north-4/standard/terraform/deploying-openjiuwen.tf`
- `practices/openjiuwen/cn/cn-north-4/standard/.extension`
- `practices/openjiuwen/cn/docs/openJiuwen-部署指南_zh.md`
- `practices/openjiuwen/cn/docs/openJiuwen-方案详情_zh.md`
- `project.config.json`

## v0.8.2 (2026-07-09) — SAC 文档命名与版本规则收敛

### 规则更新
- **文档命名标准化** — 中文内容文件统一使用中文文档类型名并追加 `_zh`，英文内容文件统一使用英文文档类型名并追加 `_en`
- **方案详情命名修正** — 中文方案详情标准名改为 `{Name}-方案详情_zh.md`，英文方案详情标准名为 `{Name}-Solution-Details_en.md`
- **部署指南命名修正** — 中文部署指南标准名为 `{Name}-部署指南_zh.md`，英文部署指南标准名为 `{Name}-Deployment-Guide_en.md`
- **版本规则统一** — 项目版本号统一使用三级语义化版本；非大版本变更递增修订号

### 关键文件
- `skills/sac-project-rules/SKILL.md` — 文档命名、版本管理规则
- `skills/sac-rfs-practices/SKILL.md` — RFS 交付文档命名规则
- `skills/reference/doc-templates.md` — 部署指南与方案详情标准文件名
- `.claude/agents/sac-documenter.json` — 文档 Agent 输出文件名
- `.claude/CLAUDE.md` — 高频版本规则摘要

## v0.8.1 (2026-07-08) — 项目范围治理与质量门禁修复

### 改进
- **正式范围配置** — 新增 `project.config.json`，集中声明当前可用 practice、质量门禁策略和资产状态
- **项目治理文档** — 新增 `OWNERSHIP.md`、`docs/project-state.md` 和 `docs/contracts/`，明确项目状态、资产归属、目录契约、脚本策略和发布契约
- **README 可用入口** — README 改为面向使用者展示当前可用实践和常用入口，并同步版本号到 v0.8.1
- **脚本分级说明** — 新增 `scripts/README.md`，区分正式脚本、可选脚本、实验脚本和归档候选

### 修复
- **测试发现逻辑** — `scripts.tests.runner` 改为递归发现部署实例，并按 `project.config.json` 过滤正式 practice，覆盖 `intl/<locale>/<region>/<variant>` 结构
- **一致性检查策略** — `scripts/` 目录改为按配置可选，兼容全内联 `user_data` 部署模式
- **OBS 上传定位** — `scripts.obs.upload` 适配结构化 practice 字段，并支持 `--locale` 指定国际站语言版本
- **OBS 工具纳入版本管理** — `.gitignore` 继续忽略 OBS 运行产物，同时允许 `scripts/obs/__init__.py`、`scripts/obs/upload.py`、`scripts/obs/spec.md`

### 验证
- `python -m scripts.tests.runner`：20 个 practice 实例，560 项检查，0 ERROR
- `python -m scripts.obs.upload --dry-run`：CN 与 INTL 指定 locale 实例定位、扫描、打包预览通过

## v0.8.0 (2026-07-07) — Supabase 全内联 + INTL 香港双语言 + 规则完善

### 新功能
- **Supabase 全内联 user_data（模式 B）** — cn-north-4 删除 `scripts/` 目录，`deploying-supabase.tf` 改为 HCL heredoc 全内联部署逻辑（Docker Compose + 配置 + 健康检查），不再依赖 OBS 脚本分发
- **Supabase INTL ap-southeast-1 双语言** — 新增 `intl/en-us/ap-southeast-1/` + `intl/zh-cn/ap-southeast-1/`，含 standard 版 Terraform 模板 + .extension
- **Supabase INTL 文档** — 新增英文 `Supabase-Deployment-Guide.md` + 中文 `Supabase-部署指南.md`

### 规则更新
- **sac-project-rules SKILL.md** — 补充版本管理规则：版本号变更时必须同步更新 README.md 中的版本徽章和显示文本

### 关键文件
- `practices/supabase/cn/cn-north-4/standard/terraform/deploying-supabase.tf` — 全内联 user_data
- `practices/supabase/cn/cn-north-4/standard/.extension` — 参数分组更新
- `practices/supabase/intl/en-us/ap-southeast-1/standard/` — 香港英文标准版
- `practices/supabase/intl/zh-cn/ap-southeast-1/standard/` — 香港中文标准版
- `practices/supabase/intl/en-us/docs/Supabase-Deployment-Guide.md` — 英文部署指南
- `practices/supabase/intl/zh-cn/docs/Supabase-部署指南.md` — 中文部署指南
- `practices/supabase/url.txt` — URL 清单
- `skills/sac-project-rules/SKILL.md` — 版本管理规则完善

## v0.6.2 (2026-07-03) — 区域重构与安全修复

### 新功能
- **新加坡区域 LiteLLM 部署** — 新增 `ap-southeast-1` 区域的 LiteLLM 标准部署和高可用部署配置文件
- **中英文双语变量分组** — 所有 Terraform 变量添加中英文双语描述和分组信息
- **香港区域迁移完成** — 自 2026-07-03 起，香港区域正式从 `cn` 站点迁移到 `intl` 国际站

### 安全修复
- **脚本调试信息移除** — 移除 `dify_search_css.sh`、`dify_search.sh`、`hermesagent_install.sh` 中的 `set -x` 调试输出，防止生产环境敏感信息泄露
- **Python 脚本规范化** — 为所有 Python 脚本添加正确的 shebang (`#!/usr/bin/env python3`)
- **文件权限修复** — 为所有 shell 脚本添加执行权限
- **敏感变量检查** — 检查所有 Terraform 文件中的敏感变量标记

### 文档更新
- **README 升级** — 采用 mem0 风格，添加徽章、能力矩阵和引用
- **SKILL 文档完善** — 修复 `sac-business-evaluator/SKILL.md` 中的占位符问题
- **gitignore 更新** — 添加 `.next/`、`node_modules/` 等构建产物目录

### 关键文件
- `practices/litellm/intl/ap-southeast-1/ha/.extension` — 新加坡高可用配置
- `practices/litellm/intl/en-us/ap-southeast-1/standard/.extension` — 新加坡标准配置
- `scripts/fix_security_issues.sh` — 安全修复脚本
- `.gitignore` — 新增构建产物排除规则
- `skills/sac-business-evaluator/SKILL.md` — 修复占位符

## v0.6.1 (2026-07-02) — supabase 方案完善

### 修复
- **JWT 密钥一致性（critical）** — `install_supabase.sh` 原现场随机生成 `JWT_SECRET`，但 `.env` 里 `ANON_KEY`/`SERVICE_ROLE_KEY` 用的是 supabase 官方 demo JWT（与随机 secret 不匹配），导致部署后 PostgREST 拒绝 anon key、Studio 无法登录管理。改为用 openssl HS256 现场签发与 `JWT_SECRET` 配套的 `ANON_KEY`/`SERVICE_ROLE_KEY`，开箱即用。
- **imgproxy 接线** — `storage` 服务补 `IMGPROXY_URL: http://imgproxy:5001`，图片变换功能不再悬空。
- **meta 健康检查** — `postgres-meta` 加 healthcheck，`docker ps` 状态可见、依赖链更准。
- **Terraform 密码校验** — `ecs_password`/`db_password` 去掉空默认值并加 8-26 长度校验，避免空密码部署出装不出 Supabase 的 ECS。

### 文档
- 三份部署指南（cn / intl-zh / intl-en）同步：1.3 镜像加速表述改为 `docker.wangzhou3.top`；3.3.2/3.3.3 改写密钥说明（JWT_SECRET 随机生成、key 派生关系、轮换步骤）；修订记录加条目。

### 关键文件
- `practices/supabase/{cn/cn-north-4,intl/ap-southeast-3}/standard/scripts/install_supabase.sh` — gen_jwt 函数
- `practices/supabase/{cn/cn-north-4,intl/ap-southeast-3}/standard/scripts/docker-compose.yaml` — imgproxy/healthcheck
- `practices/supabase/{cn/cn-north-4,intl/ap-southeast-3}/standard/terraform/deploying-supabase*.tf` — 密码校验
- `practices/supabase/cn/docs/Supabase-部署指南.md` + `practices/supabase/intl/docs/{zh-cn,en-us}/Supabase-*.md`

## v0.6.0 (2026-07-01) — SAC Web 可视化重构（静态导出 + 瑞士/Claude 设计）

### 重构 Web UI
- **静态导出架构** — Next.js 16.2.9 + Tailwind v4 + recharts，`output: 'export'` 产 `out/` 纯静态站点，可托管到 OBS（无 FastAPI 后端，所有数据 build 时烘焙）
- **瑞士杂志 / Claude 设计语言** — 暖纸底 (#f5f4ee) + 墨黑 + 单一陶土 accent (#c96442)，衬线大标题 + Geist 正文，圆角卡片 + 柔阴影，暗色跟随系统，移动端抽屉
- **数据生成器** — `scripts/gen-practices-index.mjs` 扫描 `practices/` 真实目录树 → `web/src/lib/practices-index.json`；`catalog.ts` 按 slug 合并 FS 结构（regions/hasHA）与 `data.ts` 编辑字段（score/tier/overview）
- **部署指南 Word 预览** — 方案详情页右半分栏，build 时读取 `practices/<slug>/cn/docs/*-部署指南.md`，react-markdown 渲染成文档纸面（顶栏 + 粘性滚动 + 表格/引用/代码）

### 全路由
- `/` 总览仪表盘（统计卡 + 推荐方案 + 评分分布柱图 + 评估雷达）
- `/practices` 方案目录（4 列响应式，2K 铺满 / 1K 自适应）
- `/practices/[slug]` 方案详情（左元信息 + 右部署指南预览）
- `/evaluate` 业务评估（四维雷达 + 维度评语 + 结论）
- `/deploy` 部署向导（六步流程 + RFS 模板）
- `/manage/{releases,obs,audit}` 发布 / OBS / 审计
- `/reports` 报告（分类/区域/评分分布图）

### 数据一致性
- 收录 `cli-anything-dify`（Agent-Native 工厂，CLI-Anything + Dify 融合）到 `data.ts`
- `dify` 详情页部署指南空状态友好提示（FS 目录待补充）

### 关键文件
- `web/src/app/{page,practices,evaluate,deploy,manage,reports}/` — 全部页面
- `web/src/components/{sidebar,charts,deploy-guide-preview}.tsx`
- `web/src/lib/{data,catalog,deploy-guide,utils}.ts` + `practices-index.json`
- `scripts/gen-practices-index.mjs` — 数据生成器
- `skills/sac-technical-evaluator/SKILL.md` — 从全局镜像到项目仓库

## v0.5.0 (2026-06-30) — 新增 SAC Web 管理平台

### 新增 Web UI
- **SAC Web** — 解决方案实践管理平台（Next.js 16 + Tailwind CSS 4 + FastAPI）
  - 复用 InsightPro 设计体系（Mona Sans + Cormorant 字体、暖色编辑风格）
  - 总览仪表盘：方案统计、快速操作、方案卡片
  - 方案目录 `/practices`：搜索/筛选/排序，按类别和评分组织
  - 方案详情 `/practices/[name]`：架构、优势、场景、区域、技术栈
  - 业务评估 `/evaluate`：四维模型可视化（D1~D4 评分条 + 详情展开）
  - 部署向导 `/deploy`：4 步向导（选方案→选区域→配置参数→确认部署）
  - 华为云品牌色（#c7000b）替代 InsightPro 蓝色
  - FastAPI 后端：practices 目录扫描、区域列表、评估 API、Terraform 读取

### 关键文件
- `web/package.json` — Next.js 16.2.6 前端
- `web/src/app/layout.tsx` — 全局布局（Sidebar + Header）
- `web/src/app/page.tsx` — 总览仪表盘
- `web/src/app/practices/page.tsx` — 方案目录
- `web/src/app/practices/[name]/page.tsx` — 方案详情
- `web/src/app/evaluate/page.tsx` — 业务评估
- `web/src/app/deploy/page.tsx` — 部署向导
- `web/src/components/sidebar.tsx` — 导航侧边栏
- `web/backend/main.py` — FastAPI 后端

---

## v0.4.0 (2026-06-29) — 新增业务评估 Skill + Agent-Native AI 应用工厂实践

### 新增 Skill
- **sac-business-evaluator** — 解决方案实践业务评估
  - 四维评估模型：服务端属性(D1) / 营销价值(D2) / 场景价值(D3) / 云上部署价值(D4)
  - 每维 0-10 分，加权 25%，总分决定推荐等级（🟢🟡🟠🔴）
  - 含伪需求信号检测、云上增量价值清单、典型项目评估参考表
  - 在 sac-full-pipeline 工作流中作为架构师前置预筛

### 新增实践

### 新增实践
- **cli-anything-dify** — Agent-Native AI 应用工厂（CLI-Anything + Dify）
  - Dify（AI 应用开发平台）+ CLI-Anything（Agent-Native CLI 工厂）深度融合
  - 精选 6 个云原生 harness：Ollama、n8n、ComfyUI、Dify Workflow、ChromaDB、WireMock
  - Terraform 模板：基于华为云官方 Dify 模板扩展，增加 CLI-Anything 安装 + harness 部署
  - 安装脚本：4 阶段自动化（Dify → CLI-Anything → 集成配置 → 健康检查）
  - MVP 最佳实践：5 个实操场景（Ollama 本地推理、n8n 工作流操控、ComfyUI 图像生成、全自动化流水线、结构化输出集成）
  - 文档：方案详情 + 部署指南（中英双语结构）

### 关键文件
- `practices/cli-anything-dify/cn/cn-north-4/standard/terraform/deploying-cli-anything-dify.tf`
- `practices/cli-anything-dify/cn/cn-north-4/standard/scripts/install_cli-anything-dify.sh`
- `practices/cli-anything-dify/cn/cn-north-4/standard/.extension`
- `practices/cli-anything-dify/cn/docs/Solution-Details.md`
- `practices/cli-anything-dify/cn/docs/Agent-Native-AIFactory-部署指南.md`

---

## v0.3.1 (2026-06-29) — Practice 迁移完成 & 技术债务清理

### 实践迁移
- 完成 v0.3.0 中 6 个 practice 的 `standard/` 子目录结构迁移（aitoearn、codewhale、headroom-claude-code、headroom-opencode、openhands、supabase）
- .docx → .md 文档格式迁移（部署指南）
- 删除遗留的 .extension 旧文件和空目录

### 清理
- 移除 `skills/sac-project-rules/SKILL.md` 中 sac-solution-extractor 残留引用（已合并到 sac-page-enhance）
- sac-documenter.json 描述文本精简
- `skills-vector-index.py` 增强：无依赖关键词兜底匹配 + embedding_hash 校验

---

## v0.3.0 (2026-06-26) — Skills 四层调度架构 & README 重构

### 核心架构变更

采用 **元调度层 → 技能索引层 → 动态加载层 → 执行校验层** 四层架构重构 Skills 系统，实现大 Skills 集下上下文无损、精准调度。

#### 元调度层（新增）
- 6 个 Agent JSON 统一新增 `meta_rules` 数组，包含 4 条规则：
  - **意图预检** — 查询不匹配 skill_binding 范围时跳过技能加载
  - **冲突抑制** — 多技能命中时选最高分，conflicts_with 技能不得共存
  - **递归限制** — 技能加载深度 ≤ 1 层，跨技能引用走 reference/*.md
  - **技能区生命周期** — 执行后清空技能上下文，仅保留系统指令+用户查询+滑动历史

#### 技能索引层（新增）
- **`skills-index.json`** — 集中注册 5 个技能、5 个分类、6 个 Agent 绑定，含关键词、依赖/冲突关系、merge_map
- **`skills-embeddings.json`** — 5 个 384 维向量嵌入（all-MiniLM-L6-v2 模型），支持语义相似度排序
- **`scripts/skills-vector-index.py`** — 嵌入生成脚本（支持 local/openai 双模式）

#### 动态加载层（Agent 改造）
- 6 个 Agent JSON 统一新增：`skill_index_mode: true`、`skill_binding`（primary/requires 两级绑定）、`skill_zone_config`（上下文分区参数）

### 内容去重与精简

| 文件 | 改动 | 节省 |
|------|------|------|
| `skills/sac-rfs-practices/SKILL.md` | OBS 规范→引用；区域表→引用；决策点 1-6→引用 | 1167→943 行 |
| `skills/sac-project-rules/SKILL.md` | OBS 规范→引用；区域表→引用；Agent 映射→引用 | 464→396 行 |
| `skills/sac-solution-extractor/SKILL.md` | 降级为 sac-page-enhance 薄别名，保持向后兼容 | 165→23 行 |
| `scripts/gen_xlsx.py` | 从两个 skill 子目录合并到项目根目录 | 去重 |

### 新建参考文档（跨技能共享）

- `skills/reference/obs-conventions.md` — OBS 存储规范
- `skills/reference/decision-framework.md` — 决策点框架
- `skills/reference/region-mapping.md` — 区域代码映射表

---

## v0.2.0 (2026-06-16) — 私有配置参数化 & 安全加固

- refactor: parameterize private config, fix security issues

## v0.1.9 (2026-06-16) — Headroom OpenCode & SAC 报告

- Add Headroom OpenCode practice, SAC reports, competition PPTs, and technical docs

## v0.1.6 (2026-06-11) — 架构概览更新

- Update README.md with new architecture overview

## v0.1.5 (2026-06-11) — 发布系统 & 自动化

- Major architecture refactor: add release system, automation scripts, and new practice modules

## v0.1.1 (2026-06-05) — LiteLLM & Headroom & RFS 优化

- Optimize LiteLLM structure, add Headroom practice, and refine RFS skills

## v0.1.0 (2026-06-04) — 区域重构 & LiteLLM

- Major update: Renamed demo regions, added LiteLLM practices, and enhanced RFS skills

## v0.0.3 (2026-06-02) — CodeWhale & Supabase

- Update CodeWhale practices, add Supabase support, and enhance RFS skills

## v0.0.1 (2026-05-29) — 初始版本

- Initial commit from Trae AI
