import practicesIndex from "./practices-index.json" with { type: "json" }
import { practices as editorial, evaluations } from "./data"

export type Practice = {
  slug: string
  name: string
  tagline: string
  desc: string
  overview: string
  stars: string
  category: string
  score: number | null
  tier: string | null
  cost: string
  color: string
  regions: string[]
  sites: string[]
  hasHA: boolean
}

const editorialBySlug = new Map(editorial.map(item => [item.slug, item]))

// 正式范围来自生成索引；人工元数据缺失时保留方案并明确标记，不静默隐藏。
export const practices: Practice[] = practicesIndex.practices.map(item => {
  const copy = editorialBySlug.get(item.slug)
  return {
    slug: item.slug,
    name: copy?.name ?? item.title ?? item.slug,
    tagline: copy?.tagline ?? "人工展示信息待补充",
    desc: copy?.desc ?? "该正式 Practice 尚未补充人工展示说明。",
    overview: copy?.overview ?? "正式范围和部署事实以 project.config.json 与 practices/ 为准。",
    stars: copy?.stars ?? "—",
    category: copy?.category ?? "待维护",
    score: copy?.score ?? null,
    tier: copy?.tier ?? null,
    cost: copy?.cost ?? "人工维护字段待补充",
    color: copy?.color ?? "stone",
    regions: item.regions,
    sites: item.sites,
    hasHA: item.hasHA,
  }
})

export function getPractices() { return practices }
export function getPractice(slug: string) { return practices.find(item => item.slug === slug) }
export function getPracticeSlugs() { return practices.map(item => item.slug) }

export { evaluations }

export const uncatalogued = practicesIndex.practices
  .filter(item => !editorialBySlug.has(item.slug))
  .map(item => item.slug)
