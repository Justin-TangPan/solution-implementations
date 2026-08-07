#!/usr/bin/env node
// 遍历 practices/ 目录，生成 practices-index.json 供 web 消费。
// 结构：practices/<slug>/<site>/<region>[/<variant>]/，单一标准版直接位于 region
// 输出：web/src/lib/practices-index.json
//
// 编辑性字段（score/tier/cost/overview/tagline/category/stars/color）仍由 web/src/lib/data.ts 维护；
// 本脚本只产结构化字段（slug/title/sites/regions/hasHA/docsPath），由 catalog.ts 合并。

import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const PRACTICES_DIR = join(ROOT, "practices");
const OUT = join(ROOT, "web", "src", "lib", "practices-index.json");
const FORMAL = new Set(JSON.parse(readFileSync(join(ROOT, "project.config.json"), "utf8")).formal.practices);

function dirs(p) {
  if (!existsSync(p)) return [];
  return readdirSync(p).filter(n => statSync(join(p, n)).isDirectory());
}

function hasTerraform(p) {
  return existsSync(p) && readdirSync(p).some(n => n.endsWith(".tf") || n.endsWith(".tf.json"));
}

function readH1(filePath) {
  if (!existsSync(filePath)) return null;
  const text = readFileSync(filePath, "utf8");
  const m = text.match(/^#\s+(.+)$/m);
  if (!m) return null;
  return m[1].replace(/\s*Solution Details\s*$/i, "").trim();
}

function findDocFile(slug) {
  // 支持两种命名：Solution-Details.md（旧）和 *-方案详情_zh.md（新标准）
  const patterns = [
    "Solution-Details.md",
    "Solution-Details_en.md",
  ];
  const baseDirs = [
    join(PRACTICES_DIR, slug, "cn", "docs"),
    join(PRACTICES_DIR, slug, "intl", "docs", "zh-cn"),
    join(PRACTICES_DIR, slug, "intl", "docs", "en-us"),
    join(PRACTICES_DIR, slug, "intl", "docs"),
  ];
  for (const dir of baseDirs) {
    if (!existsSync(dir)) continue;
    const files = readdirSync(dir);
    // 先尝试精确匹配
    for (const p of patterns) {
      if (files.includes(p)) return join(dir, p);
    }
    // 再尝试通配匹配：*-方案详情_zh.md
    const zhMatch = files.find(f => /方案详情_zh\.md$/.test(f));
    if (zhMatch) return join(dir, zhMatch);
    // 最后尝试 Solution-Details*.md 变体
    const sdMatch = files.find(f => /^Solution-Details/i.test(f));
    if (sdMatch) return join(dir, sdMatch);
  }
  return null;
}

function firstDocH1(slug) {
  const docFile = findDocFile(slug);
  if (!docFile) return { title: null, docsPath: null };
  const h1 = readH1(docFile);
  return { title: h1 ?? null, docsPath: relative(ROOT, docFile) };
}

const slugs = dirs(PRACTICES_DIR).filter(slug => FORMAL.has(slug)).sort();
const practices = slugs.map(slug => {
  const sites = dirs(join(PRACTICES_DIR, slug));
  const regions = new Set();
  let hasHA = false;
  for (const site of sites) {
    const sitePath = join(PRACTICES_DIR, slug, site);
    const siteEntries = dirs(sitePath).filter(r => r !== "docs");
    for (const entry of siteEntries) {
      // intl 站点有 locale 层 (en-us/zh-cn)，需要再下一层才是真实 region
      const entryPath = join(sitePath, entry);
      const isLocale = entry === "en-us" || entry === "zh-cn";
      if (isLocale) {
        const localeRegions = dirs(entryPath).filter(r => r !== "docs");
        for (const r of localeRegions) {
          regions.add(r);
          if (hasTerraform(join(entryPath, r, "ha"))) hasHA = true;
        }
      } else {
        regions.add(entry);
        if (hasTerraform(join(entryPath, "ha"))) hasHA = true;
      }
    }
  }
  const { title, docsPath } = firstDocH1(slug);
  return {
    slug,
    title,
    sites,
    regions: [...regions].sort(),
    hasHA,
    docsPath,
  };
});

const index = {
  count: practices.length,
  practices,
};

writeFileSync(OUT, JSON.stringify(index, null, 2), "utf8");
console.log(`✓ generated ${OUT.replace(ROOT + "/", "")} — ${practices.length} practices`);
for (const p of practices) {
  console.log(`  ${p.slug.padEnd(22)} regions=${p.regions.length} hasHA=${p.hasHA} title=${p.title ?? "—"}`);
}
