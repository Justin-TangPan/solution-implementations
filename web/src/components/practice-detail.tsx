"use client"

import { useState } from "react"
import Link from "next/link"
import { ArrowLeft, ArrowRight, CheckCircle2, Cloud, Code2, FileText, Layers3, Network, Server, ShieldCheck } from "lucide-react"
import { DeployGuidePreview } from "@/components/deploy-guide-preview"
import type { PracticeDocument } from "@/lib/deploy-guide"
import type { DeployablePractice } from "@/lib/deployable"
import { cn } from "@/lib/utils"
import { getArchitectureProfile } from "@/lib/architecture"

type Practice = { slug: string; name: string; tagline: string; overview: string; regions: string[]; hasHA: boolean; category: string }
const tabs = ["方案概览", "架构拓扑", "部署配置", "代码", "质量报告", "文档与交付"]

export function PracticeDetail({ practice, documents, terraformFiles }: { practice: Practice; documents: PracticeDocument[]; terraformFiles: DeployablePractice["tfFiles"] }) {
  const [tab, setTab] = useState(0)
  const [variant, setVariant] = useState<"Standard" | "HA">(practice.hasHA ? "HA" : "Standard")
  const [documentIndex, setDocumentIndex] = useState(0)
  const [terraformIndex, setTerraformIndex] = useState(0)
  const isLiteLLM = practice.slug === "litellm"
  const profile = getArchitectureProfile(practice.slug, variant.toLowerCase())

  return (
    <div className="px-5 md:px-10 py-10 md:py-14 max-w-7xl mx-auto space-y-7">
      <Link href="/practices" className="inline-flex items-center gap-2 text-sm text-ink-faded hover:text-ink"><ArrowLeft className="h-4 w-4" />解决方案库</Link>
      <header className="border-b border-border pb-7 flex flex-wrap items-start justify-between gap-5">
        <div><div className="flex items-center gap-3"><span className="eyebrow">{practice.category}</span><span className="rounded-full border border-border bg-surface px-2 py-1 text-[0.65rem] text-ink-muted">静态原型 · 演示数据</span></div><h1 className="heading-lg text-ink mt-3">{practice.name}</h1><p className="text-base text-ink-faded mt-2">{practice.tagline}</p></div>
        <Link href="/" className="inline-flex items-center gap-2 rounded-lg bg-ink px-4 py-2.5 text-sm font-medium text-cream">规划交付 <ArrowRight className="h-4 w-4" /></Link>
      </header>

      <nav aria-label="方案详情" className="flex gap-1 overflow-x-auto border-b border-border">
        {tabs.map((item, index) => <button key={item} onClick={() => setTab(index)} className={cn("shrink-0 px-4 py-3 text-sm border-b-2 transition", tab === index ? "border-accent text-ink font-bold" : "border-transparent text-ink-muted hover:text-ink")}>{item}</button>)}
      </nav>

      {tab === 0 && <div className="grid lg:grid-cols-[1.4fr_1fr] gap-6">
        <section className="rounded-2xl border border-border bg-surface p-7 shadow-soft"><div className="eyebrow">Solution Overview</div><h2 className="serif text-2xl font-bold text-ink mt-2">{practice.tagline}</h2><p className="text-sm leading-7 text-ink-faded mt-4">{practice.overview}</p><div className="grid sm:grid-cols-3 gap-3 mt-7">{[["部署形态", practice.hasHA ? "Standard / HA" : "Standard"], ["覆盖区域", `${practice.regions.length} 个`], ["文档", practice.slug === "openjiuwen" ? "中文" : "中文 / English"]].map(([label, value]) => <div key={label} className="rounded-xl bg-cream p-4"><div className="eyebrow">{label}</div><div className="text-sm font-bold text-ink mt-2">{value}</div></div>)}</div></section>
        <aside className="rounded-2xl bg-ink p-7 text-cream"><div className="eyebrow text-cream/60">Deployment Conditions</div><h2 className="serif text-xl font-bold mt-2">部署前确认</h2><ul className="mt-5 space-y-4 text-sm">{["目标区域与可用区", "RDS PostgreSQL 规格", "域名与 TLS 证书", "公网或私网入口"].map(item => <li key={item} className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-accent shrink-0" />{item}</li>)}</ul></aside>
      </div>}

      {tab === 1 && <section className="rounded-2xl border border-border bg-surface p-6 md:p-8 shadow-soft">
        <div className="flex flex-wrap items-center justify-between gap-4"><div><div className="eyebrow">Structured Topology · 演示</div><h2 className="serif text-2xl font-bold text-ink mt-2">{isLiteLLM ? "LiteLLM 资源拓扑" : `${practice.name} 概念拓扑`}</h2></div><div className="rounded-lg bg-cream p-1">{(practice.hasHA ? ["Standard", "HA"] as const : ["Standard"] as const).map(item => <button key={item} onClick={() => setVariant(item)} className={cn("rounded-md px-4 py-2 text-xs font-bold", variant === item ? "bg-ink text-cream" : "text-ink-muted")}>{item}</button>)}</div></div>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">{profile.nodes.map((node, index) => <div key={node.id} className="contents"><button className="min-w-40 rounded-xl border border-border bg-cream p-4 text-left hover:border-accent"><Server className="h-4 w-4 text-accent" /><div className="text-sm font-bold text-ink mt-3">{node.title}</div><div className="text-[0.65rem] text-ink-muted mt-1">{node.kind} · {node.note}</div></button>{index < profile.nodes.length - 1 && <ArrowRight className="h-4 w-4 text-ink-muted" />}</div>)}</div>
        <div className="mt-6 rounded-xl border border-blue-200 bg-blue-50 p-4 text-xs leading-5 text-blue-900"><Network className="inline h-4 w-4 mr-2" />{profile.summary} 节点与链路是架构基线推导，点击架构工作区查看变量合同和证据。</div>
      </section>}

      {tab === 2 && <Panel icon={Layers3} title="部署配置" items={[`区域：${practice.regions.join("、")}`, `部署形态：${variant}`, `客户可见变量：${profile.variables.join("、")}`, "网络：VPC / 子网 / 安全组（以模板事实为准）"]} />}
      {tab === 3 && <section className="rounded-2xl border border-border bg-surface p-5 md:p-7 shadow-soft">
        <div className="flex items-center gap-2"><Code2 className="h-5 w-5 text-accent" /><h2 className="serif text-2xl font-bold text-ink">Terraform 代码</h2><span className="ml-auto text-xs text-ink-muted">{terraformFiles.length} 个脚本</span></div>
        <select aria-label="选择 Terraform 脚本" value={terraformIndex} onChange={event => setTerraformIndex(Number(event.target.value))} className="mt-5 w-full rounded-lg border border-border bg-cream px-3 py-2.5 text-sm text-ink">
          {terraformFiles.map((file, index) => <option key={file.path} value={index}>{file.path}</option>)}
        </select>
        <div className="mt-4 overflow-hidden rounded-xl border border-border bg-ink">
          <div className="border-b border-white/10 px-4 py-2 text-xs text-cream/60">{terraformFiles[terraformIndex].path}</div>
          <pre className="max-h-[42rem] overflow-auto p-5 text-xs leading-6 text-cream"><code>{terraformFiles[terraformIndex].content}</code></pre>
        </div>
      </section>}
      {tab === 4 && <Panel icon={ShieldCheck} title="质量报告" items={["质量结果在构建时由 SAC runner 采集", "错误会阻断交付，警告需要架构师审阅", "当前方案的区域实例可在质量中心下钻", "外部发布状态不会从本地目录推断"]} note="打开质量中心查看当前快照和具体检查证据。" />}
      {tab === 5 && <section className="grid lg:grid-cols-[17rem_minmax(0,1fr)] gap-5">
        <aside className="rounded-2xl border border-border bg-surface p-4 shadow-soft h-fit">
          <div className="flex items-center gap-2 px-2 pb-3"><FileText className="h-4 w-4 text-accent" /><h2 className="text-sm font-bold text-ink">方案文档</h2><span className="ml-auto text-xs text-ink-muted">{documents.length}</span></div>
          <div className="space-y-1">{documents.map((document, index) => <button key={document.path} onClick={() => setDocumentIndex(index)} className={cn("w-full rounded-lg px-3 py-3 text-left transition", documentIndex === index ? "bg-ink text-cream" : "hover:bg-cream text-ink")}><span className="block text-xs font-bold break-words">{document.filename}</span><span className={cn("block mt-1 text-[0.65rem]", documentIndex === index ? "text-cream/60" : "text-ink-muted")}>{document.language} · {document.path}</span></button>)}</div>
        </aside>
        <DeployGuidePreview content={documents[documentIndex].content} filename={documents[documentIndex].filename} downloadUrl={`/downloads/${practice.slug}/docs/${documents[documentIndex].path.split("/").map(encodeURIComponent).join("/")}`} />
      </section>}
    </div>
  )
}

function Panel({ icon: Icon, title, items, note }: { icon: typeof Cloud; title: string; items: string[]; note?: string }) {
  return <section className="rounded-2xl border border-border bg-surface p-7 shadow-soft"><Icon className="h-5 w-5 text-accent" /><h2 className="serif text-2xl font-bold text-ink mt-3">{title}</h2><div className="mt-6 grid sm:grid-cols-2 gap-3">{items.map(item => <div key={item} className="rounded-xl bg-cream p-4 text-sm text-ink-faded">{item}</div>)}</div>{note && <p className="mt-5 text-xs text-ink-muted">{note}</p>}</section>
}
