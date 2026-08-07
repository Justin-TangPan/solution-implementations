// build 时从 practices/ 目录读取可部署方案列表
import { readdirSync, readFileSync, existsSync, statSync } from "node:fs"
import { join, relative } from "node:path"

const ROOT = join(process.cwd(), "..")
const PRACTICES_DIR = join(ROOT, "practices")
const FORMAL = new Set<string>(JSON.parse(readFileSync(join(ROOT, "project.config.json"), "utf8")).formal.practices)

function dirs(p: string): string[] {
  if (!existsSync(p)) return []
  return readdirSync(p).filter(n => statSync(join(p, n)).isDirectory())
}

function hasTerraform(p: string): boolean {
  return existsSync(p) && readdirSync(p).some(name => name.endsWith(".tf") || name.endsWith(".tf.json"))
}

export type DeployablePractice = {
  slug: string
  sites: string[]
  regions: { code: string; site: string; locale: string }[]
  variants: string[]
  tfFiles: { path: string; name: string; content: string; size: number }[]
  hasDocs: boolean
}

function scanRegions(slug: string): DeployablePractice["regions"] {
  const result: DeployablePractice["regions"] = []
  const sites = dirs(join(PRACTICES_DIR, slug))
  for (const site of sites) {
    if (site === "docs" || site.startsWith(".")) continue
    const sitePath = join(PRACTICES_DIR, slug, site)
    for (const entry of dirs(sitePath)) {
      if (entry === "docs") continue
      if (entry === "en-us" || entry === "zh-cn") {
        // intl locale 层
        for (const r of dirs(join(sitePath, entry))) {
          if (r !== "docs") result.push({ code: r, site, locale: entry })
        }
      } else {
        result.push({ code: entry, site, locale: "" })
      }
    }
  }
  return result
}

function scanTfFiles(slug: string): DeployablePractice["tfFiles"] {
  const result: DeployablePractice["tfFiles"] = []
  const root = join(PRACTICES_DIR, slug)
  const walk = (directory: string) => readdirSync(directory, { withFileTypes: true }).forEach(entry => {
    const file = join(directory, entry.name)
    if (entry.isDirectory()) walk(file)
    else if (entry.name.endsWith(".tf") || entry.name.endsWith(".tf.json")) {
      const content = readFileSync(file, "utf8")
      result.push({
        path: relative(root, file),
        name: entry.name,
        content,
        size: Buffer.byteLength(content, "utf8"),
      })
    }
  })
  walk(root)
  return result.sort((a, b) => a.path.localeCompare(b.path))
}

function hasMarkdown(directory: string): boolean {
  return readdirSync(directory, { withFileTypes: true }).some(entry => entry.isDirectory() ? hasMarkdown(join(directory, entry.name)) : entry.name.endsWith(".md"))
}

export function getDeployablePractices(): DeployablePractice[] {
  const slugs = dirs(PRACTICES_DIR).filter(slug => FORMAL.has(slug)).sort()
  return slugs.map(slug => {
    const regions = scanRegions(slug)
    const sites = [...new Set(regions.map(r => r.site))]

    // 收集所有变体
    const variants = new Set<string>()
    for (const r of regions) {
      let baseDir: string
      if (r.locale) {
        baseDir = join(PRACTICES_DIR, slug, r.site, r.locale, r.code)
      } else {
        baseDir = join(PRACTICES_DIR, slug, r.site, r.code)
      }
      if (existsSync(baseDir)) {
        if (hasTerraform(baseDir)) variants.add("standard")
        for (const v of dirs(baseDir)) if (hasTerraform(join(baseDir, v))) variants.add(v)
      }
    }

    const tfFiles = scanTfFiles(slug)

    const hasDocs = hasMarkdown(join(PRACTICES_DIR, slug))

    return { slug, sites, regions, variants: [...variants].sort(), tfFiles, hasDocs }
  })
}
