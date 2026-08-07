// build 时从 release/ 目录扫描发布包状态
import { readdirSync, readFileSync, statSync, existsSync } from "node:fs"
import { join } from "node:path"

export type ReleaseInfo = {
  name: string
  sites: string[]
  regions: { code: string; site: string }[]
  hasHA: boolean
  version: string | null
  status: "本地已打包" | "开发中"
}

const ROOT = join(process.cwd(), "..")
const RELEASES_DIR = join(ROOT, "release")
const PRACTICES_DIR = join(ROOT, "practices")
const FORMAL = new Set<string>(JSON.parse(readFileSync(join(ROOT, "project.config.json"), "utf8")).formal.practices)

function subdirs(p: string): string[] {
  if (!existsSync(p)) return []
  return readdirSync(p).filter(n => statSync(join(p, n)).isDirectory())
}

/** 从 release/ 目录读取 practices 的区域结构 */
function scanReleaseRegions(releasePath: string): { code: string; site: string }[] {
  const result: { code: string; site: string }[] = []
  for (const site of subdirs(releasePath)) {
    if (site === "docs") continue
    const sitePath = join(releasePath, site)
    for (const entry of subdirs(sitePath)) {
      if (entry === "docs") continue
      if ((entry === "en-us" || entry === "zh-cn") && site === "intl") {
        // intl locale 层 (en-us/zh-cn) — 再下一层才是真实 region
        for (const r of subdirs(join(sitePath, entry))) {
          if (r !== "docs") result.push({ code: r, site })
        }
      } else {
        result.push({ code: entry, site })
      }
    }
  }
  return result
}

function detectVersion(practicePath: string): string | null {
  const tfDir = join(practicePath, "terraform")
  if (!existsSync(tfDir)) return null
  const files = readdirSync(tfDir).filter(f => f.endsWith(".tf") || f.endsWith(".tf.json"))
  for (const f of files) {
    const content = readFileSync(join(tfDir, f), "utf8")
    const m = content.match(/version\s*=\s*["']([^"']+)["']/)
    if (m) return m[1]
  }
  return null
}

export function getReleases(): ReleaseInfo[] {
  const slugs = subdirs(RELEASES_DIR).filter(slug => FORMAL.has(slug)).sort()
  return slugs.map(slug => {
    const releasePath = join(RELEASES_DIR, slug)
    const sites = subdirs(releasePath).filter(s => s !== "docs")
    const regions = scanReleaseRegions(releasePath)

    // 从 practices 获取 HA 和版本信息
    const cnPath = join(PRACTICES_DIR, slug, "cn", "cn-north-4")
    const version = detectVersion(cnPath)
    const hA = existsSync(join(cnPath, "ha"))

    // 从 CHANGELOG 获取仓库版本
    let repoVersion: string | null = null
    try {
      const changelog = readFileSync(join(ROOT, "CHANGELOG.md"), "utf8")
      const vm = changelog.match(/## v([\d.]+)/)
      if (vm) repoVersion = vm[1]
    } catch { /* ignore */ }

    const packaged = existsSync(join(releasePath, "SHA256SUMS"))
      && readdirSync(releasePath).some(name => name.endsWith(".zip"))
    return {
      name: slug,
      sites: sites.length > 0 ? sites : [],
      regions,
      hasHA: hA,
      version: repoVersion || version,
      status: packaged ? "本地已打包" : "开发中",
    }
  })
}
