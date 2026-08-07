export const meta = {
  name: 'sac-architect-develop',
  status: 'deprecated',
  runtime: 'legacy-custom-workflow-dsl',
  replacement: 'Claude native architect -> builder subagent flow',
  description: 'SAC 架构+开发：快速原型，跳过测试/安全/文档/交付，架构师设计后直接开发',
  phases: [
    { title: 'Architect', detail: '方案设计' },
    { title: 'Develop', detail: '快速开发' },
  ],
}

const PROJECT = args.project
const TARGETS = args.regions || []
const VARIANTS = args.variants || []
const DESCRIPTION = args.description
const CONFIRMED_INPUTS = args.confirmed_inputs || null

if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(PROJECT || '')) {
  throw new Error('Prototype requires a lowercase hyphenated project id')
}

log(`🚀 SAC 快速原型启动：${PROJECT}`)

// Phase 1: 架构师
phase('Architect')
const architectResult = await agent({
  label: 'architect',
  agentType: 'sac-architect',
  prompt: `## 项目上下文
项目：${PROJECT}
站点/区域：${TARGETS.length ? TARGETS.join(', ') : '尚未确认，请在初版方案中列为用户输入'}
描述：${DESCRIPTION}

## 任务
1. 技术可行性分析
2. 架构设计方案（ASCII 图 + 资源清单）
3. 决策点确认（格式/地域/语言/安装策略/容器化）
4. 冻结参数合同（只保留有规则、官方或用户依据的变量）
5. 返回规则、精确参考模板、固定值、公网入口、允许文件和偏差`,
  schema: {
    type: 'object',
    properties: {
      status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
      architecture: { type: 'string' },
      system_assessment: { type: 'string' },
      initial_solution: { type: 'string' },
      user_inputs_required: { type: 'array', items: { type: 'string' } },
      decisions: { type: 'object', properties: {
        template_format: { type: 'string' },
        install_strategy: { type: 'string' },
        language: { type: 'string' },
        containerization: { type: 'string' },
      }, required: ['template_format', 'install_strategy', 'language', 'containerization'] },
      variables: { type: 'array' },
      rules_read: { type: 'array' },
      reference_templates: { type: 'array' },
      fixed_values: { type: 'object' },
      public_endpoints: { type: 'array' },
      allowed_artifacts: { type: 'array' },
      deviations: { type: 'array' },
    },
    required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'architecture', 'system_assessment', 'initial_solution', 'user_inputs_required', 'decisions', 'variables', 'rules_read', 'reference_templates', 'fixed_values', 'public_endpoints', 'allowed_artifacts', 'deviations'],
  },
})

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

if (architectResult.deviations.some(item => item.requires_user_confirmation && !item.confirmed_by_user)) {
  throw new Error('Prototype development blocked by unapproved architecture deviations')
}

// Phase 2: 开发（按区域并行）
phase('Develop')
const devResults = await pipeline(
  targetDetails,
  async ({ target, site, region, variant }) => {
    const is_cn = site === 'cn'
    const result = await agent({
      label: `dev:${target}`,
      agentType: 'sac-developer',
      prompt: `## 项目上下文
    项目：${PROJECT}，站点：${site}，Region：${region}，Variant：${variant || 'none'}
${is_cn ? '源类型：国内（华为云镜像、PyPI镜像）' : '源类型：海外（官方源）'}

		从 assets/templates/hermes_agent_inline.tf 基线开始，按 sac-project-rules 的 site/region[/variant] 目录模型创建 deploying-${PROJECT}.tf 和可选 .extension；不创建 terraform/ 包装目录。
	安装逻辑、Docker Compose 和健康检查均内联到 Terraform user_data，不创建外部安装脚本。

决策：${JSON.stringify(architectResult.decisions)}
变量：${JSON.stringify(architectResult.variables)}
固定值：${JSON.stringify(architectResult.fixed_values)}
公网入口：${JSON.stringify(architectResult.public_endpoints)}
允许文件：${JSON.stringify(architectResult.allowed_artifacts)}
禁止增加合同外变量、端口、代理层、requirements/lock 或外部下载。`,
      schema: {
        type: 'object',
        properties: {
          status: { type: 'string' }, summary: { type: 'string' }, files_changed: { type: 'array' }, checks_run: { type: 'array' }, issues: { type: 'array' }, handoff: { type: 'object' },
          site: { type: 'string' }, region: { type: 'string' }, variant: { type: ['string', 'null'] }, files_created: { type: 'array', items: { type: 'string' } }, validation_notes: { type: 'array' },
        },
        required: ['status', 'summary', 'files_changed', 'checks_run', 'issues', 'handoff', 'site', 'region', 'variant', 'files_created', 'validation_notes'],
      },
    })
    return { target, site, region, variant, ...result }
  },
)

log(`✅ 快速原型完成：${PROJECT}`)
devResults.forEach(r => log(`   ${r.target}: ${r.files_created?.length || 0} 个文件`))

return { project: PROJECT, regions: TARGETS, decisions: architectResult.decisions, dev_results: devResults }
