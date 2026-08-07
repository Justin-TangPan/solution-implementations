"use client"

import { useMemo, useState } from "react"
import Link from "next/link"
import { AlertTriangle, ArrowRight, Check, Circle, FileCheck2, FileCode2, LockKeyhole, ShieldCheck } from "lucide-react"
import type { WorkbenchSnapshot } from "@/lib/workbench"
import { cn } from "@/lib/utils"

type Stage = { name: string; status: "ready" | "warning" | "blocked" | "unknown"; summary: string; details: string[] }

export function DeliveryReadiness({ snapshot }: { snapshot: WorkbenchSnapshot }) {
  const [slug, setSlug] = useState(snapshot.practices[0]?.slug ?? "litellm")
  const [selected, setSelected] = useState(0)
  const deployable = snapshot.deployable.find(item => item.slug === slug)
  const audit = snapshot.audit.results.filter(item => item.practice.startsWith(`${slug}/`))
  const errors = audit.reduce((sum, item) => sum + item.errors, 0)
  const warnings = audit.reduce((sum, item) => sum + item.warnings, 0)
  const release = snapshot.releases.find(item => item.name === slug && item.status === "本地已打包")
  const stages: Stage[] = useMemo(() => [
    { name: "需求与合同", status: "unknown", summary: "等待用户确认架构合同", details: ["目标 Region、Variant、文档语言尚未形成持久任务", "当前页面只提供规划入口，不执行 Agent"] },
    { name: "架构", status: deployable ? "ready" : "blocked", summary: deployable ? "已发现部署实例与架构基线" : "未发现部署实例", details: ["进入架构工作区查看资源拓扑、变量和风险", "拓扑是规则推导视图，不是实时云状态"] },
    { name: "实现", status: deployable?.tfFiles.length ? "ready" : "blocked", summary: deployable?.tfFiles.length ? `${deployable.tfFiles.length} 个 Terraform 文件已发现` : "缺少 Terraform 入口", details: deployable?.tfFiles.map(file => file.path) ?? [] },
    { name: "测试与安全", status: !audit.length ? "unknown" : errors ? "blocked" : warnings ? "warning" : "ready", summary: !audit.length ? "未发现该方案的质量门禁结果" : errors ? `${errors} 个错误阻断交付` : warnings ? `${warnings} 个警告待审阅` : "静态质量门禁无错误", details: audit.slice(0, 6).flatMap(item => item.items.filter(check => check.severity !== "INFO").slice(0, 1).map(check => `${item.practice}: ${check.message}`)) },
    { name: "文档", status: deployable?.hasDocs ? "ready" : "blocked", summary: deployable?.hasDocs ? "已发现正式 Markdown 文档" : "缺少站点级文档", details: ["部署指南与方案详情必须按站点/语言规则归档", "文档来源可从方案详情页下钻"] },
    { name: "交付", status: release ? "ready" : "unknown", summary: release ? "已发现本地交付包" : "等待生成本地交付包", details: ["正式交付止于本地 release 归档与 SHA-256 校验和", "外部发布不属于本项目交付流程"] },
  ], [deployable, errors, warnings, audit, release])
  const stage = stages[selected]

  return <div className="px-5 md:px-10 py-8 md:py-12 max-w-[1500px] mx-auto space-y-7"><header className="flex flex-wrap items-end justify-between gap-5 border-b border-border pb-7"><div><div className="eyebrow">Delivery Center · Readiness</div><h1 className="heading-lg text-ink mt-3">交付准备度</h1><p className="text-sm text-ink-faded mt-3 max-w-3xl leading-6">这里展示当前快照能证明什么、还缺什么，不伪装实时 Agent 运行状态。任何生产发布动作都需要独立授权。</p></div><div className="flex items-center gap-2"><label className="eyebrow">方案</label><select value={slug} onChange={event => { setSlug(event.target.value); setSelected(0) }} className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink">{snapshot.practices.map(item => <option key={item.slug} value={item.slug}>{item.name}</option>)}</select></div></header>
    <section className="grid gap-3 md:grid-cols-3"><Readiness label="可部署实例" value={deployable?.regions.length ?? 0} note="目录扫描" icon={FileCode2} /><Readiness label="质量错误" value={errors} note={errors ? "阻断" : "无错误"} icon={ShieldCheck} tone={errors ? "danger" : "ok"} /><Readiness label="未决状态" value={stages.filter(item => item.status === "unknown").length} note="需用户确认或外部证据" icon={LockKeyhole} tone="warn" /></section>
    <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_22rem]"><div className="space-y-3">{stages.map((item, index) => <button key={item.name} onClick={() => setSelected(index)} className={cn("w-full rounded-2xl border p-5 text-left transition", selected === index ? "border-ink bg-surface shadow-soft-lg" : "border-border bg-surface hover:border-ink/30")}><div className="flex items-start gap-4"><span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-full", item.status === "ready" ? "bg-emerald-100 text-emerald-700" : item.status === "warning" ? "bg-amber-100 text-amber-800" : item.status === "blocked" ? "bg-red-100 text-red-700" : "bg-cream text-ink-muted")}>{item.status === "ready" ? <Check className="h-4 w-4" /> : item.status === "warning" ? <AlertTriangle className="h-4 w-4" /> : item.status === "blocked" ? <ShieldCheck className="h-4 w-4" /> : <Circle className="h-4 w-4" />}</span><span className="min-w-0 flex-1"><span className="flex flex-wrap items-center gap-2"><span className="serif text-lg font-bold text-ink">{item.name}</span><span className={cn("rounded-full px-2 py-1 text-[0.62rem] font-bold", item.status === "ready" ? "bg-emerald-50 text-emerald-800" : item.status === "warning" ? "bg-amber-50 text-amber-800" : item.status === "blocked" ? "bg-red-50 text-red-700" : "bg-cream text-ink-muted")}>{statusText(item.status)}</span></span><span className="block text-sm text-ink-faded mt-2">{item.summary}</span></span><ArrowRight className="h-4 w-4 text-ink-muted mt-2" /></div></button>)}</div><aside className="rounded-2xl border border-border bg-surface p-6 shadow-soft h-fit"><div className="eyebrow">Stage Evidence</div><h2 className="serif text-xl font-bold text-ink mt-2">{stage.name}</h2><p className="text-sm text-ink-faded mt-2 leading-6">{stage.summary}</p><div className="mt-5 space-y-2">{stage.details.length ? stage.details.map(item => <div key={item} className="rounded-lg bg-cream px-3 py-2.5 text-xs text-ink-faded leading-5">{item}</div>) : <div className="text-xs text-ink-muted">当前没有更多证据。</div>}</div>{stage.name === "架构" && <Link href={`/workspace?solution=${slug}`} className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-ink hover:text-accent">打开架构工作区 <ArrowRight className="h-4 w-4" /></Link>}{stage.name === "文档" && <Link href={`/practices/${slug}`} className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-ink hover:text-accent"><FileCheck2 className="h-4 w-4" />查看文档与交付 <ArrowRight className="h-4 w-4" /></Link>}</aside></section>
  </div>
}

function statusText(status: Stage["status"]) { return status === "ready" ? "已具备证据" : status === "warning" ? "有警告" : status === "blocked" ? "阻断" : "未知 / 待确认" }
function Readiness({ label, value, note, icon: Icon, tone }: { label: string; value: number; note: string; icon: typeof FileCode2; tone?: "danger" | "warn" | "ok" }) { return <div className="rounded-xl border border-border bg-surface p-5 shadow-soft"><div className="flex items-center justify-between"><Icon className={cn("h-4 w-4", tone === "danger" ? "text-red-600" : tone === "warn" ? "text-amber-600" : tone === "ok" ? "text-emerald-600" : "text-accent")} /><span className="eyebrow">{label}</span></div><div className="serif text-3xl font-bold text-ink mt-3">{value}</div><div className="text-xs text-ink-muted mt-1">{note}</div></div> }
