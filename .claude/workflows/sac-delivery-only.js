export const meta = {
  name: 'sac-delivery-only',
  status: 'deprecated',
  runtime: 'legacy-custom-workflow-dsl',
  replacement: 'Claude native builder -> reviewer subagent flow',
  description: 'SAC 本地交付流程：整理、归档并校验 release/ 交付包',
  phases: [
    { title: 'Prepare', detail: '整理本地交付目录' },
    { title: 'Package', detail: '生成归档与校验和' },
    { title: 'Verify', detail: '核对归档内容' },
  ],
}

const PROJECT = args.project
const TARGETS = args.regions || []
const GATES = args.gates || {}
const LOCAL_DELIVERY_AUTHORIZED = args.local_delivery_authorized === true

if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(PROJECT || '')) {
  throw new Error('Delivery requires a lowercase hyphenated project id')
}
if (!TARGETS.length || TARGETS.some(target => !/^(cn|intl)\/[^/]+$/.test(target))) {
  throw new Error('Delivery requires site/region targets, for example cn/cn-north-4')
}

if (!GATES.test_passed || !GATES.document_passed || (GATES.security_requested && !GATES.security_passed)) {
  throw new Error('Delivery requires passing test/document evidence and, when requested, security evidence')
}
if (!LOCAL_DELIVERY_AUTHORIZED) {
  throw new Error('Delivery requires explicit local_delivery_authorized=true')
}

phase('Prepare')
const prepResult = await agent({
  label: 'delivery-prep',
  agentType: 'sac-delivery',
  prompt: `将 practices/${PROJECT}/ 中已通过门禁的 ${TARGETS.join(', ')} 资产复制到 release/${PROJECT}/，保持 site/region/variant 结构。只整理本地文件。`,
  schema: {
    type: 'object',
    properties: {
      status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
      release_dir: { type: 'string' },
      regions_ready: { type: 'array', items: { type: 'string' } },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'release_dir', 'regions_ready'],
  },
})

phase('Package')
const archiveResult = await agent({
  label: 'delivery-archive',
  agentType: 'sac-delivery',
  prompt: `创建 release/${PROJECT}/${PROJECT}.zip 和 SHA256SUMS；不得执行外部发布、云资源变更或 Git 操作。`,
  schema: {
    type: 'object',
    properties: {
      status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
      archive_file: { type: 'string' },
      checksums: { type: 'object' }, candidate_version: { type: 'string' }, candidate_sha256: { type: 'string' },
      size_bytes: { type: 'number' },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'archive_file', 'checksums', 'candidate_version', 'candidate_sha256', 'size_bytes'],
  },
})

const cloudTestVerified = GATES.cloud_test_passed === true && archiveResult.candidate_version === GATES.candidate_version && archiveResult.candidate_sha256 === GATES.candidate_sha256

phase('Verify')
const verifyResult = await agent({
  label: 'delivery-verify',
  agentType: 'sac-delivery',
  prompt: `只读核对 ${archiveResult.archive_file} 的文件清单、SHA-256 和 practices/${PROJECT}/ 源资产一致性。若提供云测证据，核对其是否绑定精确候选。`,
  schema: {
    type: 'object',
      properties: { passed: { type: 'boolean' }, summary: { type: 'string' }, source_comparison: { type: 'string' }, blocked_reasons: { type: 'array' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' } },
      required: ['passed', 'summary', 'source_comparison', 'blocked_reasons', 'files_changed', 'checks_run', 'issues', 'handoff'],
  },
})

if (!verifyResult.passed) throw new Error(`Local delivery verification failed: ${verifyResult.summary}`)

return {
  project: PROJECT,
  release_dir: prepResult.release_dir,
  archive_file: archiveResult.archive_file,
  checksums: archiveResult.checksums,
  cloud_test_verified: cloudTestVerified,
}
