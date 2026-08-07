import { getReleases } from "@/lib/releases"

export default function ReleasesPage() {
  const releases = getReleases()

  const statusColor: Record<string, string> = {
    "本地已打包": "text-amber-600",
    "开发中": "text-ink-muted",
  }

  return (
    <div className="px-10 py-14 max-w-none space-y-10">
      <header className="border-b border-border pb-8">
        <div className="eyebrow mb-3">Manage · Releases</div>
        <h1 className="heading-lg text-ink">发布</h1>
        <p className="text-sm text-ink-faded mt-3 max-w-2xl leading-relaxed">
          从 <code className="bg-cream rounded px-1 py-0.5 text-xs">release/</code> 目录实时读取的发布包状态。
        </p>
      </header>

      {/* 统计卡片 */}
      <section className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {[
          { label: "方案总数", value: releases.length },
          { label: "本地包", value: releases.filter(r => r.status === "本地已打包").length },
          { label: "开发中", value: releases.filter(r => r.status === "开发中").length },
          { label: "Region 数", value: [...new Set(releases.flatMap(r => r.regions.map(rr => rr.code)))].length },
        ].map(s => (
          <div key={s.label} className="bg-surface rounded-xl border border-border p-6 shadow-soft">
            <div className="eyebrow mb-3">{s.label}</div>
            <div className="serif text-4xl font-bold text-ink tabular-nums leading-none">{s.value}</div>
          </div>
        ))}
      </section>

      {/* 发布列表 */}
      {releases.length > 0 ? (
        <section className="bg-surface rounded-xl border border-border shadow-soft overflow-hidden">
          <div className="grid grid-cols-6 px-7 py-4 border-b border-border eyebrow text-xs">
            <span className="col-span-1">方案</span>
            <span className="col-span-1">版本</span>
            <span className="col-span-1">站点</span>
            <span className="col-span-1">Region</span>
            <span className="col-span-1">架构</span>
            <span className="col-span-1">状态</span>
          </div>
          {releases.map(r => (
            <div key={r.name} className="grid grid-cols-6 px-7 py-5 border-b border-border-light last:border-0 items-center hover:bg-cream/50 transition-colors">
              <span className="serif text-base font-bold text-ink col-span-1">{r.name}</span>
              <span className="text-sm text-ink-faded col-span-1">
                {r.version ? (
                  <span className="inline-flex items-center gap-1.5 bg-cream rounded-md px-2 py-1 text-xs font-mono">
                    v{r.version}
                  </span>
                ) : (
                  <span className="text-xs text-ink-muted">—</span>
                )}
              </span>
              <span className="text-sm text-ink-faded col-span-1">
                {r.sites.length > 0 ? r.sites.map(s => s === "cn" ? "中国站" : "国际站").join(" · ") : "—"}
              </span>
              <span className="text-sm col-span-1">
                <div className="flex flex-wrap gap-1">
                  {r.regions.slice(0, 3).map(rr => (
                    <span key={rr.code} className="text-[0.65rem] bg-cream rounded px-1.5 py-0.5 text-ink-faded">{rr.code}</span>
                  ))}
                  {r.regions.length > 3 && (
                    <span className="text-[0.65rem] text-ink-muted">+{r.regions.length - 3}</span>
                  )}
                </div>
              </span>
              <span className="text-sm text-ink-faded col-span-1">
                {r.hasHA ? (
                  <span className="inline-flex items-center gap-1">
                    <span className="h-1.5 w-1.5 rounded-full bg-ink/60" />
                    standard + ha
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1">
                    <span className="h-1.5 w-1.5 rounded-full bg-ink/30" />
                    standard
                  </span>
                )}
              </span>
              <span className={`text-sm font-medium col-span-1 ${statusColor[r.status] || ""}`}>
                {r.status}
              </span>
            </div>
          ))}
        </section>
      ) : (
        <div className="bg-surface rounded-xl border border-border p-10 shadow-soft text-center">
          <div className="serif text-xl font-bold text-ink">暂无发布包</div>
          <p className="text-sm text-ink-faded mt-2">
            <code className="bg-cream rounded px-1 py-0.5">release/</code> 目录为空或尚未生成发布包。
            完成本地交付流程并生成归档与 <code className="bg-cream rounded px-1 py-0.5">SHA256SUMS</code> 后刷新。
          </p>
        </div>
      )}
    </div>
  )
}
