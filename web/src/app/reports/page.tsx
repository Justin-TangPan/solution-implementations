import { practices } from "@/lib/catalog"
import { regions } from "@/lib/regions"
import { HBarChart, ScoreBarChart } from "@/components/charts"

export default function ReportsPage() {
  // 分类分布
  const catMap = new Map<string, number>()
  for (const p of practices) catMap.set(p.category, (catMap.get(p.category) ?? 0) + 1)
  const catData = [...catMap.entries()].map(([label, value]) => ({ label, value })).sort((a, b) => b.value - a.value)

  // 区域分布
  const regionMap = new Map<string, number>()
  for (const p of practices) for (const r of p.regions) regionMap.set(r, (regionMap.get(r) ?? 0) + 1)
  const regionData = [...regionMap.entries()]
    .map(([code, value]) => ({ label: regions.find(r => r.code === code)?.name ?? code, value }))
    .sort((a, b) => b.value - a.value)

  // 评分分布
  const scoreData = practices
    .filter((p): p is typeof p & { score: number } => p.score !== null)
    .sort((a, b) => b.score - a.score)
    .map(p => ({ name: p.name, score: p.score }))

  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Reports</div>
        <h1 className="heading-lg text-ink">报告</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          方案目录的分类、区域与人工维护评分分布；评分不是质量门禁结果。
        </p>
      </header>

      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-6">
            <h2 className="serif text-xl font-bold text-ink">分类分布</h2>
            <span className="eyebrow">Category</span>
          </div>
          <HBarChart data={catData} />
        </div>
        <div className="bg-surface rounded-xl border border-border p-7 shadow-soft">
          <div className="flex items-baseline justify-between mb-6">
            <h2 className="serif text-xl font-bold text-ink">区域分布</h2>
            <span className="eyebrow">Region</span>
          </div>
          <HBarChart data={regionData} />
        </div>
      </section>

      <section className="bg-surface rounded-xl border border-border p-7 shadow-soft">
        <div className="flex items-baseline justify-between mb-6">
          <h2 className="serif text-xl font-bold text-ink">评分分布</h2>
          <span className="eyebrow">Score</span>
        </div>
        <ScoreBarChart data={scoreData} />
      </section>
    </div>
  )
}
