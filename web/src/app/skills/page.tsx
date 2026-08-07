import { readFileSync } from "node:fs"
import { join } from "node:path"
import { Blocks, Bot, Braces, GitBranch, type LucideIcon } from "lucide-react"

type Skill = { id: string; name: string; status: string; category: string; agents: string[]; requires: string[]; compressed_description: string }
type Index = { updated: string; maintenance: string; skills: Skill[]; skill_tree: { categories: { id: string; name: string }[] }; agent_skill_bindings: Record<string, { mandatory: string[]; conditional: string[] }> }

export default function SkillsPage() {
  const index = JSON.parse(readFileSync(join(process.cwd(), "..", "skills-index.json"), "utf8")) as Index
  const categories = new Map(index.skill_tree.categories.map(category => [category.id, category.name]))
  const agentCount = new Set(index.skills.flatMap(skill => skill.agents)).size
  const mandatory = new Set(Object.values(index.agent_skill_bindings).flatMap(binding => binding.mandatory))
  const conditional = new Set(Object.values(index.agent_skill_bindings).flatMap(binding => binding.conditional))
  const stats: [string, string | number, LucideIcon][] = [["核心能力", index.skills.filter(skill => skill.status === "core").length, Braces], ["可选能力", index.skills.filter(skill => skill.status === "optional").length, Blocks], ["迁移入口", index.skills.filter(skill => ["compatibility", "deprecated"].includes(skill.status)).length, GitBranch], ["能力角色", agentCount, Bot]]
  const statusLabel = (status: string) => status === "core" ? "核心" : status === "optional" ? "可选" : status === "compatibility" ? "兼容" : status === "deprecated" ? "弃用" : status
  const loadMode = (id: string) => mandatory.has(id) ? "必需" : conditional.has(id) ? "条件" : "不进入默认链路"

  return <div className="px-5 md:px-10 py-10 md:py-14 max-w-7xl mx-auto space-y-8">
    <header className="border-b border-border pb-8">
      <div className="flex flex-wrap items-center gap-3"><span className="eyebrow">Skills</span><span className="rounded-full border border-border bg-surface px-2 py-1 text-[0.65rem] text-ink-muted">人工目录 · {index.updated}</span></div>
      <h1 className="heading-lg text-ink mt-3">Skills</h1>
      <p className="text-sm text-ink-faded mt-3 max-w-3xl leading-relaxed">Core、Optional、Compatibility、Deprecated 来自项目能力模型；必需、条件表示角色加载方式。这里是展示层，不控制 Runtime，正式定义以 <code>project.config.json</code> 为准。</p>
    </header>

    <section className="grid grid-cols-2 gap-3 md:grid-cols-4">{stats.map(([label, value, Icon]) => <div key={label} className="rounded-xl border border-border bg-surface p-5 shadow-soft"><Icon className="h-4 w-4 text-accent" /><div className="eyebrow mt-4">{label}</div><div className="serif mt-2 text-3xl font-bold text-ink">{value}</div></div>)}</section>

    <section className="grid gap-4 lg:grid-cols-2">{index.skills.map(skill => <article key={skill.id} className="rounded-2xl border border-border bg-surface p-6 shadow-soft">
      <div className="flex items-start justify-between gap-4"><div><div className="eyebrow">{categories.get(skill.category) ?? skill.category}</div><h2 className="serif mt-2 text-xl font-bold text-ink">{skill.name}</h2><code className="mt-1 block text-[0.65rem] text-ink-muted">{skill.id}</code></div><span className={skill.status === "core" ? "rounded-full bg-emerald-50 px-2.5 py-1 text-[0.65rem] font-bold text-emerald-700" : "rounded-full bg-cream px-2.5 py-1 text-[0.65rem] font-bold text-ink-muted"}>{statusLabel(skill.status)}</span></div>
      <p className="mt-4 line-clamp-3 text-sm leading-6 text-ink-faded">{skill.compressed_description}</p>
      <dl className="mt-5 grid gap-3 border-t border-border pt-4 text-xs sm:grid-cols-3"><div><dt className="text-ink-muted">加载方式</dt><dd className="mt-1 font-bold text-ink">{loadMode(skill.id)}</dd></div><div><dt className="text-ink-muted">Agent</dt><dd className="mt-1 font-bold text-ink">{skill.agents.length || "—"}</dd></div><div><dt className="text-ink-muted">前置依赖</dt><dd className="mt-1 truncate font-bold text-ink">{skill.requires.join(", ") || "无"}</dd></div></dl>
    </article>)}</section>

    <section className="rounded-2xl border border-border bg-ink p-6 text-cream md:p-7"><div className="eyebrow text-cream/55">Agent Bindings</div><h2 className="serif mt-2 text-xl font-bold">Agent 与 Skill 关系</h2><div className="mt-6 grid gap-3 md:grid-cols-2">{Object.entries(index.agent_skill_bindings).map(([agent, binding]) => <div key={agent} className="rounded-xl border border-white/10 bg-white/5 p-4"><div className="text-sm font-bold">{agent}</div><div className="mt-2 text-xs leading-5 text-cream/60">必需：{binding.mandatory.join(" · ") || "无"}<br />条件：{binding.conditional.join(" · ") || "无"}</div></div>)}</div></section>
  </div>
}
