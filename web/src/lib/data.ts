// 人工维护的展示字段。正式范围、Region 和部署形态来自 project.config.json 与生成索引。
export const practices = [
  { slug: "astrbot", name: "AstrBot", tagline: "多平台智能体聊天平台", desc: "支持 LLM 对话、多模态、Agent、MCP、技能与知识库。", overview: "AstrBot 是面向个人、开发者和团队的多平台智能体聊天平台。本实践交付中国站单 ECS 标准版，保留运行时模型、平台和插件配置给部署者。", stars: "—", category: "AI 平台", score: 7, tier: "good" as const, cost: "按实际资源计费", color: "violet" },
  { slug: "cognee", name: "Cognee", tagline: "知识与记忆应用服务", desc: "Cognee API 与 PostgreSQL + pgvector 的单节点部署。", overview: "Cognee 面向知识与记忆类应用。本实践在中国站部署 Cognee API 和 PostgreSQL + pgvector，LLM 与 Embedding 服务由客户自行配置。", stars: "—", category: "AI 数据", score: 7, tier: "good" as const, cost: "按实际资源计费", color: "indigo" },
  { slug: "dify", name: "Dify", tagline: "AI 应用开发平台", desc: "可视化编排 LLM 工作流、Agent 推理与 RAG 管道。", overview: "Dify 提供可视化 Workflow 编排、Agent 推理、RAG 知识库、Prompt 工程与评测能力，适合构建客服、知识问答和文档处理等 AI 应用。", stars: "—", category: "AI 平台", score: 8.5, tier: "strong" as const, cost: "按实际资源计费", color: "violet" },
  { slug: "litellm", name: "LiteLLM", tagline: "统一 LLM API 网关", desc: "统一多模型 Provider 的 OpenAI 兼容 API。", overview: "LiteLLM 统一多模型 Provider 的 OpenAI 兼容 API，适合作为企业多模型接入的网关层。", stars: "—", category: "AI 网关", score: 8.75, tier: "strong" as const, cost: "按实际资源计费", color: "blue" },
  { slug: "newapi", name: "NewAPI", tagline: "模型渠道与用量管理", desc: "统一管理上游模型渠道、访问令牌、用户权限和用量数据。", overview: "NewAPI 用于管理模型渠道、令牌、用户权限和用量数据；国际站交付标准版与高可用版模板。", stars: "—", category: "AI 网关", score: 7.5, tier: "good" as const, cost: "按实际资源计费", color: "blue" },
  { slug: "openjiuwen", name: "openJiuwen", tagline: "AI Agent 智能体开发平台", desc: "支持 Agent 开发、测试、工作流编排与模型管理。", overview: "openJiuwen Agent Studio 覆盖 Agent 开发、测试、工作流编排、模型管理、插件管理和发布运行等环节。", stars: "—", category: "AI 平台", score: 7, tier: "good" as const, cost: "按实际资源计费", color: "cyan" },
  { slug: "supabase", name: "Supabase", tagline: "开源 BaaS", desc: "PostgreSQL、身份认证、对象存储与向量搜索。", overview: "Supabase 是基于 PostgreSQL 的开源 BaaS，提供 Auth、Storage、Realtime 与向量搜索能力。", stars: "—", category: "BaaS", score: 7.75, tier: "good" as const, cost: "按实际资源计费", color: "indigo" },
]

export const evaluations = [
  { name: "CLI-Anything", url: "github.com/HKUDS/CLI-Anything", stars: "44.2k", d1: 3, d2: 6, d3: 4, d4: 1, total: 3.5, grade: "red", d1r: "CLI 包装层——在 REST API 外套一层 Click，核心桌面 harness 无法上云", d2r: "概念新颖但 44k stars 与云部署脱节", d3r: "本地有价值；云上是伪需求", d4r: "全部 8 项云上增量价值指标均未满足", rec: "不建议作为独立解决方案实践" },
  { name: "Dify", url: "github.com/langgenius/dify", stars: "80k+", d1: 9, d2: 8, d3: 9, d4: 8, total: 8.5, grade: "green", d1r: "服务端 + Web UI，REST API 完整", d2r: "80k stars，华为云市场零同类", d3r: "AI 应用开发是企业刚需", d4r: "云上高可用、RDS 持久化、多 Region", rec: "强烈推荐——已上线" },
  { name: "LiteLLM", url: "github.com/BerriAI/litellm", stars: "17k+", d1: 10, d2: 8, d3: 8, d4: 9, total: 8.75, grade: "green", d1r: "纯服务端 API 网关", d2r: "唯一统一 LLM 网关", d3r: "多 Provider 统一是真实痛点", d4r: "API 网关需 7×24 在线", rec: "强烈推荐——已上线" },
  { name: "Ollama", url: "github.com/ollama/ollama", stars: "120k+", d1: 9, d2: 7, d3: 7, d4: 6, total: 7.25, grade: "amber", d1r: "服务端 REST API", d2r: "120k stars 顶级知名度", d3r: "本地推理真实需求", d4r: "云上 GPU 可行但本地体验更好", rec: "值得做，与 Dify 组合价值更高" },
]

export const regions = [
  { code: "cn-north-4", name: "华北-北京四", group: "cn" },
  { code: "cn-southwest-2", name: "西南-贵阳一", group: "cn" },
  { code: "ap-southeast-1", name: "中国-香港", group: "cn" },
  { code: "ap-southeast-3", name: "亚太-新加坡", group: "intl" },
]
