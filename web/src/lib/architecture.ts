export type ArchitectureNode = { id: string; kind: string; title: string; note: string; zone: "edge" | "compute" | "data" | "dependency" }
export type ArchitectureEdge = { from: string; to: string; label: string }
export type ArchitectureProfile = { slug: string; variant: string; title: string; summary: string; nodes: ArchitectureNode[]; edges: ArchitectureEdge[]; variables: string[]; fixed: string[]; endpoints: string[]; risks: string[] }

const profiles: Record<string, ArchitectureProfile> = {
  litellm: {
    slug: "litellm", variant: "standard", title: "LiteLLM Standard", summary: "单 ECS 公网入口，应用与 PostgreSQL 共置；适合低复杂度验证和轻量生产。", nodes: [
      { id: "internet", kind: "Internet", title: "公网用户", note: "外部调用方", zone: "edge" },
      { id: "eip", kind: "EIP", title: "公网入口", note: "Terraform 定义的 EIP", zone: "edge" },
      { id: "ecs", kind: "ECS", title: "LiteLLM ECS", note: "应用与依赖服务", zone: "compute" },
      { id: "postgres", kind: "PostgreSQL", title: "PostgreSQL", note: "用量与配置持久化", zone: "data" },
      { id: "maas", kind: "External API", title: "模型 API", note: "出站依赖", zone: "dependency" },
    ], edges: [{ from: "internet", to: "eip", label: "HTTPS / HTTP" }, { from: "eip", to: "ecs", label: "公网转发" }, { from: "ecs", to: "postgres", label: "内网持久化" }, { from: "ecs", to: "maas", label: "模型请求" }], variables: ["ecs_password", "ecs_flavor", "bandwidth_size", "vpc_cidr"], fixed: ["官方监听端口", "部署逻辑内联 user_data", "华为云 Provider 仅 region"], endpoints: ["公网应用入口由模板输出", "模型 API 出站依赖"], risks: ["公网控制面风险由正式质量门禁持续提示", "单 ECS 不提供节点级高可用"] },
  litellm_ha: {
    slug: "litellm", variant: "ha", title: "LiteLLM HA", summary: "ELB → CCE → 多副本 LiteLLM，使用 RDS/DCS 与 NAT，适合持续在线的网关服务。", nodes: [
      { id: "internet", kind: "Internet", title: "公网用户", note: "API 调用方", zone: "edge" },
      { id: "elb", kind: "ELB", title: "ELB", note: "统一入口与健康检查", zone: "edge" },
      { id: "cce", kind: "CCE", title: "CCE 集群", note: "跨节点运行副本", zone: "compute" },
      { id: "pods", kind: "Deployment", title: "LiteLLM Pods", note: "可扩展应用副本", zone: "compute" },
      { id: "rds", kind: "RDS", title: "RDS PostgreSQL", note: "配置、密钥与用量", zone: "data" },
      { id: "dcs", kind: "DCS", title: "DCS Redis", note: "缓存与会话", zone: "data" },
      { id: "nat", kind: "NAT", title: "NAT Gateway", note: "模型 API 出站", zone: "dependency" },
    ], edges: [{ from: "internet", to: "elb", label: "443" }, { from: "elb", to: "cce", label: "健康检查" }, { from: "cce", to: "pods", label: "调度" }, { from: "pods", to: "rds", label: "持久化" }, { from: "pods", to: "dcs", label: "缓存" }, { from: "pods", to: "nat", label: "出站" }], variables: ["ecs_password", "ecs_flavor", "bandwidth_size", "vpc_cidr"], fixed: ["CCE + Kubernetes Provider 例外已登记", "官方默认监听配置", "公网入口由 ELB 承担"], endpoints: ["ELB 公网入口", "NAT 出站模型 API"], risks: ["HA 复杂度和成本高于 Standard", "Kubernetes Provider 属于已批准架构例外"] },
  supabase: {
    slug: "supabase", variant: "standard", title: "Supabase Standard", summary: "单 ECS 运行完整 Supabase 服务单元，覆盖网关、Studio、Auth、Storage 与数据库。", nodes: [
      { id: "internet", kind: "Internet", title: "应用用户", note: "Web / Mobile 客户端", zone: "edge" },
      { id: "eip", kind: "EIP", title: "公网入口", note: "模板输出访问地址", zone: "edge" },
      { id: "ecs", kind: "ECS", title: "Supabase ECS", note: "Docker Compose 服务单元", zone: "compute" },
      { id: "gateway", kind: "Gateway", title: "Kong Gateway", note: "API 路由与认证边界", zone: "compute" },
      { id: "postgres", kind: "PostgreSQL", title: "PostgreSQL", note: "业务数据与 Auth", zone: "data" },
      { id: "storage", kind: "Storage", title: "Storage / Realtime", note: "对象与实时服务", zone: "data" },
    ], edges: [{ from: "internet", to: "eip", label: "公网请求" }, { from: "eip", to: "ecs", label: "端口转发" }, { from: "ecs", to: "gateway", label: "API 入口" }, { from: "gateway", to: "postgres", label: "数据库" }, { from: "gateway", to: "storage", label: "文件与事件" }], variables: ["ecs_password", "ecs_flavor", "bandwidth_size", "vpc_cidr"], fixed: ["完整上游 Compose 服务单元", "Kong 认证配置不可省略", "敏感配置运行时生成"], endpoints: ["Gateway 公网入口", "Studio 管理面"], risks: ["公网控制面风险由正式质量门禁持续提示", "单 ECS 重启会影响整套服务"] },
  openjiuwen: {
    slug: "openjiuwen", variant: "standard", title: "openJiuwen Standard", summary: "单 ECS 运行 Agent Studio 及其 MySQL、Milvus、MinIO 等依赖。", nodes: [
      { id: "internet", kind: "Internet", title: "开发者", note: "Agent Studio 用户", zone: "edge" },
      { id: "eip", kind: "EIP", title: "公网入口", note: "官方默认访问端口", zone: "edge" },
      { id: "ecs", kind: "ECS", title: "Agent Studio ECS", note: "官方部署包 + 服务编排", zone: "compute" },
      { id: "mysql", kind: "MySQL", title: "MySQL", note: "平台元数据", zone: "data" },
      { id: "milvus", kind: "Milvus", title: "Milvus", note: "向量检索", zone: "data" },
      { id: "minio", kind: "MinIO", title: "MinIO", note: "对象资产", zone: "data" },
    ], edges: [{ from: "internet", to: "eip", label: "5173" }, { from: "eip", to: "ecs", label: "公网访问" }, { from: "ecs", to: "mysql", label: "元数据" }, { from: "ecs", to: "milvus", label: "向量" }, { from: "ecs", to: "minio", label: "对象" }], variables: ["ecs_password", "ecs_flavor", "bandwidth_size", "vpc_cidr"], fixed: ["官方默认接口 5173", "inline user_data", "禁止 frontend_port 等扩展变量"], endpoints: ["5173 公网入口"], risks: ["单 ECS 多容器依赖，资源规格需在部署前确认"] },
}

export function getArchitectureProfile(slug: string, variant = "standard"): ArchitectureProfile {
  return profiles[`${slug}_${variant}`] ?? profiles[slug] ?? {
    slug,
    variant,
    title: `${slug} ${variant}`,
    summary: "当前没有可追溯的人工架构拓扑；请以 Terraform 和架构合同为准。",
    nodes: [{ id: "unavailable", kind: "待补证据", title: "暂无已验证拓扑", note: "未回退到其他方案的演示数据", zone: "dependency" }],
    edges: [],
    variables: [],
    fixed: [],
    endpoints: [],
    risks: ["人工架构展示尚未维护，不代表 Terraform 缺失或云测失败"],
  }
}

export function listArchitectureProfiles() { return Object.values(profiles) }
