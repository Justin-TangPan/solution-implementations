export const meta = {
  name: 'sac-audit',
  status: 'deprecated',
  runtime: 'legacy-custom-workflow-dsl',
  replacement: 'Claude native reviewer subagent',
  description: 'SAC 审计流程：测试 + 按需安全审查 + 可选修复/交付包核验',
  phases: [
    { title: 'Test', detail: '模板与脚本验证' },
    { title: 'Security', detail: '安全审计' },
    { title: 'Report', detail: '审计报告汇总' },
  ],
}

const PROJECT = args.project
const REGIONS = args.regions || ['cn', 'intl']
const RELEASE_PACKAGE = args.release_package || null
const RUN_SECURITY = args.security === true
const FIX = args.fix === true

log(`🔍 SAC 审计启动：${PROJECT} - ${REGIONS.join(', ')}`)

phase('Test')
let testResult = await agent({
  label: 'tester',
  agentType: 'sac-tester',
  prompt: `## 项目上下文
项目：${PROJECT}，区域：${REGIONS.join(', ')}

	检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/validation-checklist.md 逐项验证。

输出结果。`,
  schema: {
    type: 'object',
    properties: {
      passed: { type: 'boolean' },
      files_changed: { type: 'array' }, checks_run: { type: 'array' }, commands: { type: 'array' }, handoff: { type: 'object' },
      issues: { type: 'array', items: { type: 'object', properties: {
        severity: { type: 'string', enum: ['error', 'warning', 'info'] },
        file: { type: 'string' },
        message: { type: 'string' }, evidence: { type: 'string' },
      }, required: ['severity', 'file', 'message', 'evidence'] } },
      summary: { type: 'string' },
    },
    required: ['passed', 'issues', 'summary', 'files_changed', 'checks_run', 'commands', 'handoff'],
  },
})

let securityResult = { passed: true, findings: [], summary: 'Not requested' }
if (RUN_SECURITY) {
phase('Security')
securityResult = await agent({
  label: 'security',
  agentType: 'sac-security',
  prompt: `## 项目上下文
项目：${PROJECT}，区域：${REGIONS.join(', ')}

	检查 practices/${PROJECT}/ 下所有文件，按 skills/reference/security-check-rules.md（SEC-001 至 SEC-008）逐条审计。

输出审计结果。`,
  schema: {
    type: 'object',
    properties: {
      passed: { type: 'boolean' },
      files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' }, scanned_scope: { type: 'array' },
      findings: { type: 'array', items: { type: 'object', properties: {
        id: { type: 'string' }, severity: { type: 'string' }, file: { type: 'string' },
        message: { type: 'string' }, evidence: { type: 'string' }, remediation: { type: 'string' },
      }, required: ['id', 'severity', 'file', 'message', 'evidence', 'remediation'] } },
      summary: { type: 'string' },
    },
    required: ['passed', 'findings', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'scanned_scope'],
  },
})
}

let deliveryResult = null
if (RELEASE_PACKAGE) {
  phase('Delivery package')
  deliveryResult = await agent({
    label: 'delivery-audit',
    agentType: 'sac-delivery',
    prompt: `只读核验候选交付包 ${RELEASE_PACKAGE} 的目录、确定性归档、SHA256SUMS 和门禁证据。不得修改、重打包或发布。`,
    schema: {
      type: 'object',
      properties: {
        passed: { type: 'boolean' },
        issues: { type: 'array', items: { type: 'string' } },
        summary: { type: 'string' },
      },
      required: ['passed', 'issues', 'summary'],
    },
  })
}

let errors = testResult.issues.filter(i => i.severity === 'error')
let highs = securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high')

if (FIX && (errors.length || highs.length)) {
  phase('Fix')
  await agent({
    label: 'audit-fix', agentType: 'sac-developer',
    prompt: `仅修复 ${PROJECT} 审计报告中的已证实阻断项，不扩大范围。测试：${JSON.stringify(errors)} 安全：${JSON.stringify(highs)}`,
    schema: { type: 'object', properties: { status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' } }, required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff'] },
  })
  const verification = await agent({
    label: 'audit-retest', agentType: 'sac-tester',
    prompt: `重新运行 ${PROJECT} 的正式测试门禁（包括 rfs_policy），核验修复。`,
    schema: { type: 'object', properties: { passed: { type: 'boolean' }, issues: { type: 'array' }, summary: { type: 'string' }, commands: { type: 'array' } }, required: ['passed', 'issues', 'summary', 'commands'] },
  })
  testResult = { ...testResult, ...verification }
  errors = testResult.issues.filter(i => i.severity === 'error')
  if (RUN_SECURITY && highs.length) {
    securityResult = await agent({
      label: 'audit-security-recheck', agentType: 'sac-security',
      prompt: `只读复审 ${PROJECT} 的 critical/high 安全修复。`,
      schema: { type: 'object', properties: { passed: { type: 'boolean' }, findings: { type: 'array' }, summary: { type: 'string' } }, required: ['passed', 'findings', 'summary'] },
    })
    highs = securityResult.findings.filter(f => f.severity === 'critical' || f.severity === 'high')
  }
}

phase('Report')

log(`📊 审计报告：${PROJECT}`)
log(`   测试：${testResult.passed ? '✅' : '❌'} ${errors.length} 个错误`)
log(`   安全：${securityResult.passed ? '✅' : '❌'} ${highs.length} 个高危`)
if (deliveryResult) log(`   交付包：${deliveryResult.passed ? '✅' : '❌'} ${deliveryResult.issues.length} 个问题`)
log()
if (!testResult.passed) {
  log('--- 测试问题 ---')
  testResult.issues.forEach(i => log(`   [${i.severity}] ${i.file}: ${i.message}`))
}
if (!securityResult.passed) {
  log('--- 安全问题 ---')
  securityResult.findings.forEach(f => log(`   [${f.severity}] ${f.id} ${f.file}: ${f.message}`))
}

return {
  project: PROJECT,
  test: { passed: testResult.passed, issues: testResult.issues.length },
  security: { passed: securityResult.passed, findings: securityResult.findings.length },
  delivery: deliveryResult && { passed: deliveryResult.passed, issues: deliveryResult.issues.length },
}
