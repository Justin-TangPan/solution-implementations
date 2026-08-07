export const meta = {
  name: 'sac-document-only',
  status: 'deprecated',
  runtime: 'legacy-custom-workflow-dsl',
  replacement: 'Claude native builder with sac-documentation',
  description: 'SAC 文档专用流水线：分析、生成、翻译、IDP Word 渲染、存量转换或只读质量检查',
  phases: [
    { title: 'Document', detail: '统一标准稿、双语输出与质量门禁' },
    { title: 'Review', detail: '输出人工审核项；不执行发布或 IDP 上架' },
  ],
}

const PROJECT = args.project
const MODE = args.mode || 'generate'
const INPUT = args.input || ''
const SITES = args.sites || ['cn', 'intl']
const LOCALES = args.locales || ['zh-cn', 'en-us']

const SUPPORTED_MODES = [
  'analyze',
  'generate',
  'markdown-only',
  'word-only',
  'english-only',
  'translate',
  'convert-word',
  'convert-pdf',
  'validate',
  'retemplate',
]

if (!PROJECT && !INPUT) {
  throw new Error('sac-document-only requires args.project or args.input')
}
if (!SUPPORTED_MODES.includes(MODE)) {
  throw new Error(`Unsupported document mode: ${MODE}`)
}
if ((MODE === 'convert-word' || MODE === 'convert-pdf') && !INPUT) {
  throw new Error(`${MODE} requires args.input`)
}

phase('Document')
log(`📝 SAC 文档流水线启动：${PROJECT || INPUT}`)
log(`   模式：${MODE}`)
log(`   站点：${SITES.join(', ')}`)
log(`   语言：${LOCALES.join(', ')}`)

const documentResult = await agent({
  label: `document:${MODE}`,
  agentType: 'sac-documenter',
  prompt: `## 输入
项目：${PROJECT || '(未指定)'}
源文件：${INPUT || '(从 Practice 读取)'}
模式：${MODE}
站点：${SITES.join(', ')}
语言：${LOCALES.join(', ')}

## 任务
按 sac-documentation 执行对应模式；sac-document-pipeline 仅为旧名兼容，不重复加载。事实以当前 Practice 和用户输入为准；跳过 .env、
.secrets 和凭证文件。内容先进入统一文档模型，再按需生成正式 _zh/_en Markdown 和 DOCX。

- analyze：只分析并输出标准稿，不写正式文档；
- generate：生成标准稿、部署指南、方案详情、Markdown、DOCX 和质量报告；
- markdown-only：只渲染 Markdown；
- word-only：从标准稿或 Markdown 渲染 DOCX，不改写正文；
- english-only/translate：保护技术内容后翻译英文并检查双语一致性；
- convert-word/convert-pdf：离线解析存量文档；无法可靠恢复时明确报错或标记人工确认；
- validate：只读检查，不修改输入；
- retemplate：保持正文不变，重新应用当前 IDP 模板。

始终输出结构化质量报告和人工审核项。不得发布、上传、导入 IDP 或声明人工审核已完成。`,
  schema: {
    type: 'object',
    properties: {
      standard_document: { type: 'string' },
      markdown_files: { type: 'array', items: { type: 'string' } },
      docx_files: { type: 'array', items: { type: 'string' } },
      languages: { type: 'array', items: { type: 'string', enum: ['zh-cn', 'en-us'] } },
      quality_report: { type: 'string' },
      quality_status: { type: 'string', enum: ['pass', 'warning', 'fail'] },
      errors: { type: 'array', items: { type: 'object' } },
      warnings: { type: 'array', items: { type: 'object' } },
      manual_review_items: { type: 'array', items: { type: 'object', properties: { blocking: { type: 'boolean' } }, required: ['blocking'] } },
      status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'standard_document', 'markdown_files', 'docx_files', 'languages', 'quality_report', 'quality_status', 'errors', 'warnings', 'manual_review_items'],
  },
})

phase('Review')
const blockingErrors = documentResult.errors.filter(error => error.blocks_export !== false)
const blockingManualReviews = documentResult.manual_review_items.filter(item => item.blocking === true)
const gatePassed = documentResult.quality_status !== 'fail' && blockingErrors.length === 0 && blockingManualReviews.length === 0

if (!gatePassed) {
  log(`❌ 文档质量门禁失败：${blockingErrors.length} 个阻断错误，${blockingManualReviews.length} 个阻断人工确认项`)
  log('   结果仅供整改，不得交付或导入 IDP')
} else {
  log(`✅ 文档自动检查完成（${documentResult.quality_status}）`)
  log('   仍需人工技术审核和 IDP 导入检查')
}

return {
  project: PROJECT,
  mode: MODE,
  ...documentResult,
  gate_passed: gatePassed,
  ready_for_listing: false,
}
