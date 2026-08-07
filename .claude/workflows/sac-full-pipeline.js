export const meta = {
  name: 'sac-full-pipeline',
  status: 'deprecated',
  runtime: 'legacy-custom-workflow-dsl',
  replacement: 'Claude native architect -> builder -> reviewer -> builder-fix flow',
  description: 'SAC 全流程：架构→开发→测试与按需安全审计→文档→本地交付',
  phases: [
    { title: 'Architect', detail: '方案设计与技术评估' },
    { title: 'Develop', detail: '模板与内联部署逻辑开发' },
    { title: 'Test & Security', detail: '验证与安全审查' },
    { title: 'Document', detail: '标准稿→双语 Markdown→IDP Word→文档质量门禁' },
    { title: 'Deliver', detail: '本地打包与校验' },
  ],
}
// ============================================================================
// SAC 全流程工作流
// 6 个 Agent 依次协同：架构师 → 开发 → 测试 → 安全 → 文档 → 交付
// 各 Agent 角色定义和规则在 .claude/agents/ 中，通过 agentType 引用
// 本文件仅传递项目上下文，不重复 Agent 定义内容
// ============================================================================

const PROJECT = args.project          // e.g. "litellm"
const TARGETS = args.regions || []    // confirmed site/region values, e.g. cn/cn-north-4
const VARIANTS = args.variants || []
const DESCRIPTION = args.description  // e.g. "Multi-model API Gateway"
const GENERATE_DOCX = args.generate_docx === true
const CLOUD_TEST = args.cloud_test || {}
const RUN_SECURITY = args.security === true
const LOCAL_DELIVERY_AUTHORIZED = args.local_delivery_authorized === true
const CONFIRMED_INPUTS = args.confirmed_inputs || null

if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(PROJECT || '')) {
  throw new Error('Full pipeline requires a lowercase hyphenated project id')
}

log(`🚀 SAC 全流程启动：${PROJECT}`)
log(`   目标：${TARGETS.length ? TARGETS.join(', ') : '待评估后确认'}`)
log(`   描述：${DESCRIPTION}`)

// ============================================================================
// Phase 1: 架构师 — 方案设计与技术评估
// ============================================================================
phase('Architect')
log('🧠 架构师开始工作...')

const architectResult = await agent({
  label: 'architect',
  agentType: 'sac-architect',
  prompt: `## 项目上下文
项目：${PROJECT}
站点/区域：${TARGETS.length ? TARGETS.join(', ') : '尚未确认，请在初版方案中列为用户输入'}
描述：${DESCRIPTION}

## 任务
1. 技术可行性分析
2. 方案架构设计（单机标准版 vs 高可用版）
3. 决策点确认（模板格式、安装策略、语言、容器化、部署类型）
4. 冻结参数合同：只保留规则、官方或用户明确要求的客户变量；官方固定接口不得参数化
5. 资源清单
6. 依赖清单
7. 返回已读规则、精确参考模板、固定值、公网入口、允许文件和偏差；偏差需标记是否已获用户确认`,
  schema: {
    type: 'object',
    properties: {
      status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
      feasibility: { type: 'string' },
      system_assessment: { type: 'string' },
      initial_solution: { type: 'string' },
      user_inputs_required: { type: 'array', items: { type: 'string' } },
      architecture: { type: 'string' },
      decisions: {
        type: 'object',
        properties: {
          template_format: { type: 'string', enum: ['hcl', 'json'] },
          install_strategy: { type: 'string', enum: ['inline'] },
          language: { type: 'string', enum: ['zh', 'en'] },
          containerization: { type: 'string', enum: ['docker_compose', 'direct_install'] },
          deployment_type: { type: 'string', enum: ['standard', 'ha'] },
        },
        required: ['template_format', 'install_strategy', 'language', 'containerization', 'deployment_type'],
      },
      variables: { type: 'array', items: { type: 'object' } },
      rules_read: { type: 'array', items: { type: 'string' } },
      reference_templates: { type: 'array', items: { type: 'string' } },
      fixed_values: { type: 'object' },
      public_endpoints: { type: 'array', items: { type: 'object' } },
      allowed_artifacts: { type: 'array', items: { type: 'string' } },
      deviations: { type: 'array', items: { type: 'object' } },
      resources: { type: 'array', items: { type: 'object' } },
      dependencies: { type: 'array', items: { type: 'string' } },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'feasibility', 'system_assessment', 'initial_solution', 'user_inputs_required', 'architecture', 'decisions', 'variables', 'rules_read', 'reference_templates', 'fixed_values', 'public_endpoints', 'allowed_artifacts', 'deviations', 'resources', 'dependencies'],
  },
})

log(`✅ 架构设计完成`)
log(`   格式：${architectResult.decisions.template_format}`)
log(`   安装：${architectResult.decisions.install_strategy}`)
log(`   语言：${architectResult.decisions.language}`)

if (!CONFIRMED_INPUTS || !TARGETS.length) {
  return {
    status: 'needs_user_input',
    system_assessment: architectResult.system_assessment,
    initial_solution: architectResult.initial_solution,
    user_inputs_required: architectResult.user_inputs_required,
  }
}

const targetDetails = TARGETS.flatMap((target) => {
  const match = /^(cn|intl)\/([^/]+)$/.exec(target)
  if (!match) throw new Error(`Invalid target "${target}"; expected site/region, for example cn/cn-north-4`)
  const variants = VARIANTS.length ? VARIANTS : [null]
  return variants.map(variant => ({ target: variant ? `${target}/${variant}` : target, site: match[1], region: match[2], variant }))
})

const unapprovedDeviations = architectResult.deviations.filter(item => item.requires_user_confirmation && !item.confirmed_by_user)
if (unapprovedDeviations.length) {
  throw new Error(`Architecture has ${unapprovedDeviations.length} unapproved deviations`)
}

// ============================================================================
// Phase 2: 开发 — 模板与内联部署逻辑开发（按目标并行）
// ============================================================================
phase('Develop')
log('💻 开发 Agent 开始工作...')

const devResults = await pipeline(
  targetDetails,
  async ({ target, site, region, variant }) => {
    const is_cn = site === 'cn'

    const result = await agent({
      label: `dev:${target}`,
      agentType: 'sac-developer',
      prompt: `## 项目上下文
项目：${PROJECT}
站点：${site}
Region：${region}
Variant：${variant || 'none'}
${is_cn ? '源类型：国内（华为云镜像、PyPI镜像）' : '源类型：海外（官方源）'}

## 架构决策
${JSON.stringify(architectResult.decisions, null, 2)}

## 变量设计
${JSON.stringify(architectResult.variables, null, 2)}

## 固定合同
固定值：${JSON.stringify(architectResult.fixed_values, null, 2)}
公网入口：${JSON.stringify(architectResult.public_endpoints, null, 2)}
允许文件：${JSON.stringify(architectResult.allowed_artifacts, null, 2)}
禁止增加合同外变量、端口、代理层、requirements/lock 或外部下载。

## 任务
		从 assets/templates/hermes_agent_inline.tf 基线开始，按 sac-project-rules 的 site/region[/variant] 目录模型创建 deploying-${PROJECT}.tf 和可选 .extension；不创建 terraform/ 包装目录。
	安装逻辑、Docker Compose 和健康检查均内联到 Terraform user_data，不创建外部安装脚本。

输出创建的文件列表及路径`,
      schema: {
        type: 'object',
        properties: {
          status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
          site: { type: 'string' }, region: { type: 'string' }, variant: { type: ['string', 'null'] }, files_created: { type: 'array', items: { type: 'string' } }, validation_notes: { type: 'array' },
          install_strategy: { type: 'string' },
          docker_image_source: { type: 'string' },
        },
        required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'site', 'region', 'variant', 'files_created', 'validation_notes'],
      },
    })

    return { target, site, region, variant, ...result }
  },
)

log(`✅ 开发完成：${TARGETS.length} 个目标`)
devResults.forEach(r => log(`   ${r.target}: ${r.files_created.length} 个文件`))

// ============================================================================
// Phase 3: 测试 + 可选安全审查（并行）
// ============================================================================
phase('Test & Optional Security')
log(`🧪 测试 Agent${RUN_SECURITY ? ' + 安全审查 Agent 并行' : ''}工作...`)

const [testResult, securityResult] = await parallel([
  async () => {
    const result = await agent({
      label: 'tester',
      agentType: 'sac-tester',
      prompt: `## 项目上下文
项目：${PROJECT}
站点/区域：${TARGETS.join(', ')}

	请检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/validation-checklist.md 逐项验证。

输出验证结果。`,
      schema: {
        type: 'object',
        properties: {
          status: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, handoff: { type: 'object' }, commands: { type: 'array' },
          passed: { type: 'boolean' },
          issues: { type: 'array', items: { type: 'object', properties: { severity: { type: 'string', enum: ['error', 'warning', 'info'] }, file: { type: 'string' }, line: { type: 'number' }, message: { type: 'string' }, evidence: { type: 'string' } }, required: ['severity', 'file', 'message', 'evidence'] } },
          summary: { type: 'string' },
        },
        required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'commands', 'passed'],
      },
    })
    return result
  },
  async () => {
    if (!RUN_SECURITY) return { status: 'skipped', passed: true, findings: [], summary: 'Security review not requested', files_changed: [], checks_run: [], issues: [], handoff: {}, scanned_scope: [] }
    const result = await agent({
      label: 'security',
      agentType: 'sac-security',
      prompt: `## 项目上下文
项目：${PROJECT}
站点/区域：${TARGETS.join(', ')}

	请检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/security-check-rules.md（SEC-001 至 SEC-008）逐条审计。

输出审计结果。`,
      schema: {
        type: 'object',
        properties: {
          status: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' }, scanned_scope: { type: 'array' },
          passed: { type: 'boolean' },
          findings: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] }, file: { type: 'string' }, line: { type: 'number' }, message: { type: 'string' }, evidence: { type: 'string' }, remediation: { type: 'string' } }, required: ['id', 'severity', 'file', 'message', 'evidence', 'remediation'] } },
          summary: { type: 'string' },
        },
        required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'scanned_scope', 'passed', 'findings'],
      },
    })
    return result
  },
])

if (!testResult.passed) {
  log(`⚠️ 测试发现问题：${testResult.issues.length} 个`)
  testResult.issues.filter(i => i.severity === 'error').forEach(i => log(`   ❌ ${i.file}: ${i.message}`))
} else {
  log('✅ 测试全部通过')
}

if (!securityResult.passed) {
  log(`⚠️ 安全审查发现问题：${securityResult.findings.length} 个`)
  securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high').forEach(f => log(`   🔴 ${f.id} [${f.severity}] ${f.file}: ${f.message}`))
} else {
  log(RUN_SECURITY ? '✅ 安全审查全部通过' : 'ℹ️ 未请求安全审查')
}

const testErrors = testResult.issues.filter(item => item.severity === 'error')
const securityBlockers = securityResult.findings.filter(item => item.severity === 'critical' || item.severity === 'high')
if (!testResult.passed || testErrors.length || !securityResult.passed || securityBlockers.length) {
  throw new Error(`Test/security gate failed: ${testErrors.length} errors, ${securityBlockers.length} critical/high findings`)
}

// ============================================================================
// Phase 4: 文档 — 标准稿 + 双语 Markdown + IDP Word + 质量门禁
// ============================================================================
phase('Document')
log('📝 文档 Agent 开始工作...')

const docResults = await pipeline(
  [...new Set(targetDetails.map(item => item.site))],
  async (site) => {
    const is_cn = site === 'cn'

    const result = await agent({
      label: `doc:${site}`,
      agentType: 'sac-documenter',
      prompt: `## 项目上下文
项目：${PROJECT}
站点代码：${site}
站点：${is_cn ? '中国站' : '国际站（中文 + 英文）'}

## 已验证上游结果
架构：${JSON.stringify(architectResult, null, 2)}
开发产物：${JSON.stringify(devResults.filter(item => item.site === site), null, 2)}
测试：${JSON.stringify(testResult, null, 2)}
安全：${JSON.stringify(securityResult, null, 2)}

## 任务
	使用 sac-documentation，从 practices/${PROJECT} 的实际代码和已验证上游结果执行：
	1. 提取事实并构建统一标准稿，记录来源、AI 推断和待人工确认项；
	2. 生成部署指南和方案详情；
	3. 中国站输出中文，国际站同时输出 zh-cn 与 en-us；
	4. 文件名严格使用中文 _zh、英文 _en 后缀；
	5. 从同一标准稿渲染 Markdown${GENERATE_DOCX ? ' 和 IDP DOCX' : '；本次不生成 DOCX'}；
	6. 运行内容、Markdown、Word、敏感信息和双语一致性检查；
	7. 输出结构化质量报告和人工审核清单。

不得把参考项目内容当成当前事实，不得在质量报告存在阻断错误时声明可上架。`,
      schema: {
        type: 'object',
        properties: {
          status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
          standard_document: { type: 'string' },
          markdown_files: { type: 'array', items: { type: 'string' } },
          docx_files: { type: 'array', items: { type: 'string' } },
          languages: { type: 'array', items: { type: 'string', enum: ['zh-cn', 'en-us'] } },
          quality_report: { type: 'string' },
          quality_status: { type: 'string', enum: ['pass', 'warning', 'fail'] },
          errors: { type: 'array', items: { type: 'object' } },
          warnings: { type: 'array', items: { type: 'object' } },
          manual_review_items: { type: 'array', items: { type: 'object', properties: { blocking: { type: 'boolean' } }, required: ['blocking'] } },
        },
        required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'standard_document', 'markdown_files', 'docx_files', 'languages', 'quality_report', 'quality_status', 'errors', 'warnings', 'manual_review_items'],
      },
    })

    return { site, ...result }
  },
)

log(`✅ 文档完成：${new Set(targetDetails.map(item => item.site)).size} 个站点`)

const documentBlockingErrors = docResults.flatMap(result =>
  result.errors.filter(error => error.blocks_export !== false),
)
const blockingManualReviews = docResults.flatMap(result => result.manual_review_items.filter(item => item.blocking === true))
const documentGatePassed = docResults.every(result => result.quality_status !== 'fail') && documentBlockingErrors.length === 0 && blockingManualReviews.length === 0

if (!documentGatePassed) {
  log(`❌ 文档质量门禁失败：${documentBlockingErrors.length} 个阻断错误，${blockingManualReviews.length} 个阻断人工确认项`)
  documentBlockingErrors.forEach(error => log(`   ${error.document || '(unknown)'}: ${error.message || JSON.stringify(error)}`))
  throw new Error('Document quality gate failed; release and IDP listing are prohibited')
}

log(`   Markdown：${docResults.reduce((count, result) => count + result.markdown_files.length, 0)} 个`)
log(`   DOCX：${docResults.reduce((count, result) => count + result.docx_files.length, 0)} 个`)
log(`   人工审核项：${docResults.reduce((count, result) => count + result.manual_review_items.length, 0)} 个`)

// ============================================================================
// Phase 5: 交付 — 本地打包与校验
// ============================================================================
phase('Deliver')
log('📦 交付 Agent 开始工作...')

if (!LOCAL_DELIVERY_AUTHORIZED) {
  throw new Error('Local candidate packaging requires explicit local_delivery_authorized=true')
}

const deliveryResult = await agent({
  label: 'delivery',
  agentType: 'sac-delivery',
  prompt: `## 项目上下文
项目：${PROJECT}
站点/区域：${TARGETS.join(', ')}
## 任务
1. 创建 release/${PROJECT}/ 目录结构，从 practices/${PROJECT}/ 复制文件
2. 打包 release/${PROJECT}/${PROJECT}.zip
3. 生成 SHA256SUMS，candidate_version 和 candidate_sha256，并核对归档内容与源文件
本工作流只生成本地交付包，不执行任何外部发布、云资源变更或 Git 操作。

输出交付结果。`,
  schema: {
    type: 'object',
    properties: {
      status: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' }, source_comparison: { type: 'string' }, blocked_reasons: { type: 'array' },
      release_dir: { type: 'string' },
      regions_released: { type: 'array', items: { type: 'string' } },
      archive_file: { type: 'string' },
      checksums: { type: 'object' },
      candidate_version: { type: 'string' },
      candidate_sha256: { type: 'string' },
      summary: { type: 'string' },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'source_comparison', 'blocked_reasons', 'release_dir', 'regions_released', 'archive_file', 'checksums', 'candidate_version', 'candidate_sha256'],
  },
})

const cloudTestVerified = CLOUD_TEST.passed === true && CLOUD_TEST.candidate_version === deliveryResult.candidate_version && CLOUD_TEST.candidate_sha256 === deliveryResult.candidate_sha256
if (!cloudTestVerified) log(`ℹ️ 本地候选包已生成，但未绑定该精确候选的云测证据；不得声明云上验证通过。`)

log(`✅ 交付完成`)
log(`   目录：${deliveryResult.release_dir}`)
log(`   归档：${deliveryResult.archive_file}`)
log(`   目标：${deliveryResult.regions_released.join(', ')}`)

// ============================================================================
// 最终汇总
// ============================================================================
log('')
log('='.repeat(60))
log(`🎉 SAC ${PROJECT} 全流程交付完成！`)
log('='.repeat(60))
log('')
log(`📋 最终总结：`)
log(`   架构：${architectResult.decisions.deployment_type} 版`)
log(`   目标：${TARGETS.join(', ')}`)
log(`   模板格式：${architectResult.decisions.template_format}`)
log(`   安装策略：${architectResult.decisions.install_strategy}`)
log('')
log(`🧪 质量检查：`)
log(`   测试：${testResult.passed ? '✅ 通过' : '⚠️ ' + testResult.issues.filter(i => i.severity === 'error').length + ' 个错误'}`)
log(`   安全：${securityResult.passed ? '✅ 通过' : '⚠️ ' + securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high').length + ' 个高危'}`)
log('')
log(`📦 交付物：`)
log(`   发布目录：${deliveryResult.release_dir}`)
log(`   归档包：${deliveryResult.archive_file}`)

return {
  project: PROJECT,
  regions: TARGETS,
  decisions: architectResult.decisions,
  test_passed: testResult.passed,
  security_passed: securityResult.passed,
  documentation: docResults,
  document_gate_passed: documentGatePassed,
  cloud_test_verified: cloudTestVerified,
  release_dir: deliveryResult.release_dir,
  archive_file: deliveryResult.archive_file,
  checksums: deliveryResult.checksums,
}
