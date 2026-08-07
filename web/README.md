# SAC Web 可视化

SAC 的辅助性只读展示层，用于浏览正式范围、仓库资产和构建时质量快照。它不定义正式
Practice，不执行 Agent，也不创建云资源。

## 技术栈

- **Next.js 16.2.9**（App Router，静态导出 `output: 'export'`）
- **React 19.2.4** + **TypeScript 5**
- **Tailwind CSS v4**（`@theme` token，无 config 文件）
- **recharts 3**（图表，client 组件）
- **lucide-react**（图标）

## 数据流

```
practices/ ─→ scripts/gen-practices-index.mjs ─→ web/src/lib/practices-index.json
                                                        │
web/src/lib/data.ts (编辑性字段) ─→ web/src/lib/catalog.ts (合并) ─→ pages
skills-index.json ─→ /skills
```

- **正式范围**来自 `project.config.json`。
- **结构化字段**（slug / regions / hasHA / sites）由生成器扫描正式 `practices/` 产出。
- **编辑性字段**（score / tier / cost / overview / tagline / category）由 `data.ts` 人工维护，
  不属于质量结果；缺失时页面明确显示待补充。
- `catalog.ts` 以生成索引为主表按 slug 合并，人工元数据不会决定正式范围。

### 重新生成索引

```bash
node scripts/gen-practices-index.mjs
```

`npm run build` 会通过 `prebuild` 自动重新生成；单独执行该命令用于检查索引变化。

## 开发

```bash
cd web
npm install
npm run dev      # http://localhost:3000
npm run lint
```

## 构建与静态导出

```bash
npm run build    # 产出 out/ 纯静态 HTML
npx serve out    # 本地预览
```

`out/` 可由任意静态主机托管。动态路由 `/practices/[slug]` 由 `generateStaticParams` 枚举，`dynamicParams = false`。

## Skills 页面

`/skills` 从根目录 `skills-index.json` 展示 Core、Optional、Compatibility、Deprecated 能力，以及
Architect/Builder/Reviewer 的必需/条件绑定。它只用于展示；分类和角色事实以
`project.config.json` 为准，实际加载由各 Runtime Adapter 决定。

## 目录结构

```
web/src/
  app/
    page.tsx                    # 架构师驾驶舱
    workspace/page.tsx          # 架构工作区与资源拓扑
    practices/page.tsx          # 方案目录
    practices/[slug]/page.tsx   # 方案详情
    evaluate/page.tsx           # 业务评估（四维雷达）
    deploy/page.tsx             # 交付准备度
    manage/{releases,audit}/page.tsx
    reports/page.tsx            # 报告洞察
    layout.tsx globals.css
  components/{sidebar,charts}.tsx
  lib/{data,catalog,workbench,architecture,utils}.ts practices-index.json
```

## 设计语言

瑞士杂志 / Claude 风格 — 暖纸底（#f5f4ee）+ 墨黑 + 单一陶土 accent（#c96442，克制使用）。衬线大标题 + Geist 无衬正文，圆角卡片 + 柔阴影，暗色模式跟随系统。

## 注意

- Next.js 16 有 breaking changes，动手前先翻 `node_modules/next/dist/docs/`（见 `AGENTS.md`）。
- 静态导出禁用 `cookies()/headers()/searchParams`；所有数据 build 时烘焙。
