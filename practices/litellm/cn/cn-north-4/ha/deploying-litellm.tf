terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">=1.67.1"
    }
    kubernetes = {
      source  = "huawei.com/provider/kubernetes"
      version = ">=2.5.0"
    }
  }
}

provider "kubernetes" {
  host                   = huaweicloud_cce_cluster.cluster.certificate_clusters.1.server
  client_certificate     = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_certificate_data)
  client_key             = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_key_data)
  cluster_ca_certificate = base64decode(huaweicloud_cce_cluster.cluster.certificate_clusters.0.certificate_authority_data)
}

provider "huaweicloud" {
  region = "cn-north-4"
}

variable "resource_name_prefix" {
  default     = "ha-litellm"
  description = "资源名称前缀，命名规则为 {resource_name_prefix}-{资源英文名称}。取值范围为 4-24 个字符，支持小写字母、数字和中划线（-），且必须以小写字母开头。"
  type        = string
  nullable    = false

  validation {
    condition     = length(regexall("^[a-z][a-z0-9-]{3,23}$", var.resource_name_prefix)) > 0
    error_message = "取值范围为 4-24 个字符，支持小写字母、数字和中划线（-），且必须以小写字母开头。"
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网 IP 带宽大小，按流量计费。单位：Mbit/s，取值范围：1-300，默认 300 Mbit/s。"
  type        = number
  nullable    = false

  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300 && floor(var.bandwidth_size) == var.bandwidth_size
    error_message = "带宽大小必须是 1-300 之间的整数，单位为 Mbit/s。"
  }
}

variable "elb_certificate_id" {
  default     = ""
  description = "现有 ELB 服务器证书 ID，用于公网 HTTPS 监听器。"
  type        = string
  nullable    = false

  validation {
    condition     = length(regexall("^[0-9A-Fa-f-]{32,36}$", var.elb_certificate_id)) > 0
    error_message = "请输入有效的 32-36 位 ELB 服务器证书 ID。"
  }
}

variable "litellm_version" {
  default     = "1.87.0"
  description = "固定的 LiteLLM Proxy 镜像版本。模板使用 docker.litellm.ai/berriai/litellm:1.87.0。"
  type        = string
  nullable    = false

  validation {
    condition     = var.litellm_version == "1.87.0"
    error_message = "此高可用模板固定使用 LiteLLM 1.87.0。"
  }
}

variable "litellm_master_key" {
  default     = ""
  description = "LiteLLM 主密钥，必须以 sk- 开头，是外部调用 Proxy 时使用的 Bearer Token。"
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition     = length(regexall("^sk-[A-Za-z0-9_-]{29,61}$", var.litellm_master_key)) > 0
    error_message = "litellm_master_key 必须以 sk- 开头，总长度为 32-64 位，仅使用字母、数字、下划线或中划线，并使用密码学安全随机数生成。"
  }
}

variable "litellm_salt_key" {
  default     = ""
  description = "LiteLLM Salt Key 用于加密数据库敏感数据。请使用密码学安全随机数生成 32-64 位字母、数字、下划线或中划线；存储数据后不得轮换。"
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition     = length(regexall("^[A-Za-z0-9_-]{32,64}$", var.litellm_salt_key)) > 0
    error_message = "litellm_salt_key 必须为 32-64 位，仅使用字母、数字、下划线或中划线；请使用密码学安全随机数生成，存储数据后不得轮换。"
  }
}

variable "cce_cluster_flavor" {
  default     = "cce.s2.small"
  description = "CCE Turbo 集群规格。默认为 cce.s2.small（小规模多控制节点 CCE 集群，最多 50 个节点）。"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["cce.s2.small", "cce.s2.medium", "cce.s2.large", "cce.s2.xlarge"], var.cce_cluster_flavor)
    error_message = "输入无效，请重新输入。"
  }
}

variable "cce_node_pool_password" {
  default     = ""
  description = "CCE 集群节点密码，用于登录集群节点。"
  type        = string
  nullable    = false
  sensitive   = true
  validation {
    condition = (
      length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.cce_node_pool_password)) > 0 &&
      length(regexall("[A-Z]", var.cce_node_pool_password)) > 0 &&
      length(regexall("[a-z]", var.cce_node_pool_password)) > 0 &&
      length(regexall("[0-9~!^*\\-=_+,]", var.cce_node_pool_password)) > 0
    )
    error_message = "取值范围为 8-24 个字符，密码必须至少包含一个大写字母、一个小写字母以及一个数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "cce_node_pool_flavor" {
  default     = "c7n.2xlarge.2"
  description = "CCE 集群节点云服务器实例规格，建议至少满足 LiteLLM 官方每实例 4 核 8 GB 的生产建议。"
  type        = string
  nullable    = false
}

variable "cce_node_pool_count" {
  default     = 3
  description = "CCE 节点池初始节点数。"
  type        = number
  nullable    = false
  validation {
    condition     = var.cce_node_pool_count >= 1 && var.cce_node_pool_count <= 9 && floor(var.cce_node_pool_count) == var.cce_node_pool_count
    error_message = "节点池数量必须是 1-9 之间的整数。"
  }
}

variable "rds_flavor" {
  default     = "rds.pg.x1.2xlarge.2.ha"
  description = "RDS for PostgreSQL 主备实例规格，默认 8 核 16 GB（独享型）。"
  type        = string
  nullable    = false
}

variable "pgsql_admin_password" {
  default     = ""
  description = "PostgreSQL 管理员密码。"
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition = (
      length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.pgsql_admin_password)) > 0 &&
      length(regexall("[A-Z]", var.pgsql_admin_password)) > 0 &&
      length(regexall("[a-z]", var.pgsql_admin_password)) > 0 &&
      length(regexall("[0-9~!^*\\-=_+,]", var.pgsql_admin_password)) > 0
    )
    error_message = "取值范围为 8-24 个字符，密码必须至少包含一个大写字母、一个小写字母以及一个数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "redis_capacity" {
  default     = 8
  description = "分布式缓存服务 Redis 实例容量。可选值：1 GB-64 GB，默认 8 GB。"
  type        = number
  nullable    = false

  validation {
    condition     = contains([1, 2, 4, 8, 16, 32, 64], var.redis_capacity)
    error_message = "输入无效，请重新输入。"
  }
}

variable "redis_password" {
  default     = ""
  description = "Redis 密码。"
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition = (
      length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.redis_password)) > 0 &&
      length(regexall("[A-Z]", var.redis_password)) > 0 &&
      length(regexall("[a-z]", var.redis_password)) > 0 &&
      length(regexall("[0-9~!^*\\-=_+,]", var.redis_password)) > 0
    )
    error_message = "取值范围为 8-24 个字符，密码必须至少包含一个大写字母、一个小写字母以及一个数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式。可选值：postPaid（按需）、prePaid（包年包月）。"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "输入无效，请重新输入。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期类型，仅当 charging_mode=prePaid 时生效。"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "输入无效，请重新输入。"
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期，仅当 charging_mode=prePaid 时生效。"
  type        = number
  nullable    = false

  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9 && floor(var.charging_period) == var.charging_period
    error_message = "订购周期必须是 1-9 之间的整数。"
  }
}

data "huaweicloud_availability_zones" "availability_zones" {}

data "huaweicloud_dcs_flavors" "flavors" {
  cache_mode       = "ha"
  capacity         = var.redis_capacity
  engine_version   = "7.0"
  cpu_architecture = "x86_64"
}

data "huaweicloud_rds_flavors" "flavor" {
  db_type       = "PostgreSQL"
  db_version    = "16"
  instance_mode = "ha"
}

data "huaweicloud_elb_availability_zones" "az" {}

data "huaweicloud_elb_flavors" "flavors" {
  name = var.charging_mode == "prePaid" ? "L7_flavor.elb.s1.small" : "L7_flavor.elb.pro.max"
}

locals {
  region_id      = data.huaweicloud_availability_zones.availability_zones.region
  dcs_az         = sort(data.huaweicloud_dcs_flavors.flavors.flavors[0].available_zones)
  rds_az         = data.huaweicloud_rds_flavors.flavor.flavors[index(data.huaweicloud_rds_flavors.flavor.flavors.*.name, var.rds_flavor)].availability_zones
  flatten_elb_az = flatten([
    for az_group in data.huaweicloud_elb_availability_zones.az.availability_zones : az_group.list
  ])
  elb_az = distinct([
    for az in local.flatten_elb_az : az.code
    if az.category == 0 && contains(az.protocol, "l7")
  ])
  valid_charging_period = (
    var.charging_unit == "month"
    ? var.charging_period >= 1 && var.charging_period <= 9
    : var.charging_period >= 1 && var.charging_period <= 3
  )
  pgsql_database_url  = "postgresql://root:${var.pgsql_admin_password}@${huaweicloud_rds_instance.rds.private_ips[0]}:5432/litellm"
  litellm_image       = "docker.litellm.ai/berriai/litellm:${var.litellm_version}"
  litellm_config_yaml = <<-EOT

  litellm_settings:
    json_logs: true
    set_verbose: false
    request_timeout: 600
    cache: true
    service_callbacks: ["prometheus"]
    enable_redis_auth_cache: true
    cache_params:
      type: redis
      host: os.environ/REDIS_HOST
      port: os.environ/REDIS_PORT
      password: os.environ/REDIS_PASSWORD
      namespace: litellm.cce
      supported_call_types: []
      max_connections: 200

  general_settings:
    master_key: os.environ/LITELLM_MASTER_KEY
    database_url: os.environ/DATABASE_URL
    database_connection_pool_limit: 80
    database_connection_timeout: 60
    use_shared_health_check: true
    enable_drain_endpoint: true
    drain_endpoint_token: os.environ/DRAIN_ENDPOINT_TOKEN
    proxy_batch_write_at: 60
    use_redis_transaction_buffer: true
    store_model_in_db: true
    store_prompts_in_spend_logs: false
    allow_requests_on_db_unavailable: true

  router_settings:
    routing_strategy: simple-shuffle
    redis_host: os.environ/REDIS_HOST
    redis_password: os.environ/REDIS_PASSWORD
    redis_port: os.environ/REDIS_PORT
    enable_pre_call_checks: true
    allowed_fails: 3
    cooldown_time: 30
    retry_policy:
      TimeoutErrorRetries: 2
      RateLimitErrorRetries: 3
      InternalServerErrorRetries: 2
  EOT
}

resource "huaweicloud_vpc" "vpc_server" {
  cidr = "192.168.0.0/16"
  name = "${var.resource_name_prefix}-vpc"
}

resource "huaweicloud_vpc_subnet" "public_subnet" {
  cidr       = "192.168.200.0/24"
  gateway_ip = "192.168.200.1"
  name       = "${var.resource_name_prefix}-public-subnet"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "private_subnet" {
  cidr       = "192.168.201.0/24"
  gateway_ip = "192.168.201.1"
  name       = "${var.resource_name_prefix}-private-subnet"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "eni_cluster_1" {
  name       = "${var.resource_name_prefix}-eni-1"
  cidr       = "192.168.202.0/24"
  gateway_ip = "192.168.202.1"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "eni_cluster_2" {
  name       = "${var.resource_name_prefix}-eni-2"
  cidr       = "192.168.203.0/24"
  gateway_ip = "192.168.203.1"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_networking_secgroup" "secgroup_server" {
  name = "${var.resource_name_prefix}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_vpc_ingress" {
  description       = "允许 VPC 内部访问"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "192.168.0.0/16"
  security_group_id = huaweicloud_networking_secgroup.secgroup_server.id
}

resource "huaweicloud_vpc_eip" "eips" {
  bandwidth {
    charge_mode = "traffic"
    name        = "${var.resource_name_prefix}-bandwidth"
    share_type  = "PER"
    size        = var.bandwidth_size
  }
  publicip {
    type = "5_bgp"
  }
  count = 3
}

resource "huaweicloud_elb_loadbalancer" "loadbalancer" {
  name            = "${var.resource_name_prefix}-lb"
  ipv4_subnet_id  = huaweicloud_vpc_subnet.public_subnet.ipv4_subnet_id
  backend_subnets = [huaweicloud_vpc_subnet.private_subnet.id]
  availability_zone = [
    local.elb_az[0],
    local.elb_az[1]
  ]
  ipv4_eip_id   = huaweicloud_vpc_eip.eips[0].id
  l7_flavor_id  = data.huaweicloud_elb_flavors.flavors.flavors[0].id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period

  lifecycle {
    precondition {
      condition     = local.valid_charging_period
      error_message = "charging_period 按月必须为 1-9，按年必须为 1-3。"
    }
    precondition {
      condition     = length(local.elb_az) >= 2
      error_message = "所选区域必须提供至少两个不同的 category-0 L7 ELB 可用区。"
    }
  }
}

resource "huaweicloud_rds_instance" "rds" {
  name                = "${var.resource_name_prefix}-pg"
  flavor              = var.rds_flavor
  ha_replication_mode = "async"
  vpc_id              = huaweicloud_vpc.vpc_server.id
  subnet_id           = huaweicloud_vpc_subnet.private_subnet.id
  security_group_id   = huaweicloud_networking_secgroup.secgroup_server.id
  availability_zone = [
    local.rds_az[0],
    local.rds_az[1]
  ]
  db {
    type     = "PostgreSQL"
    version  = "16"
    password = var.pgsql_admin_password
  }
  volume {
    type = "CLOUDSSD"
    size = 100
  }

  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period

  lifecycle {
    precondition {
      condition     = length(distinct(local.rds_az)) >= 2
      error_message = "所选 RDS PostgreSQL 高可用规格必须支持至少两个不同的可用区。"
    }
  }
}

resource "huaweicloud_rds_pg_database" "pgsql_database" {
  instance_id = huaweicloud_rds_instance.rds.id
  name        = "litellm"
  owner       = "root"
}

resource "huaweicloud_cce_cluster" "cluster" {
  depends_on = [
    huaweicloud_elb_loadbalancer.loadbalancer
  ]
  name                   = "${var.resource_name_prefix}-cluster"
  flavor_id              = var.cce_cluster_flavor
  cluster_version        = "v1.34"
  multi_az               = true
  vpc_id                 = huaweicloud_vpc.vpc_server.id
  subnet_id              = huaweicloud_vpc_subnet.private_subnet.id
  eip                    = huaweicloud_vpc_eip.eips[1].address
  container_network_type = "eni"
  eni_subnet_id = join(",", [
    huaweicloud_vpc_subnet.eni_cluster_1.ipv4_subnet_id,
    huaweicloud_vpc_subnet.eni_cluster_2.ipv4_subnet_id
  ])
  tags = {
    app = "_sac_litellm_cce"
  }
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

resource "huaweicloud_cce_node_pool" "node_pool" {
  depends_on         = [huaweicloud_rds_pg_database.pgsql_database]
  cluster_id         = huaweicloud_cce_cluster.cluster.id
  availability_zone  = "random"
  flavor_id          = var.cce_node_pool_flavor
  initial_node_count = 1
  max_node_count     = 10
  min_node_count     = 1
  name               = "${var.resource_name_prefix}-pool"
  os                 = "Ubuntu 24.04"
  password           = var.cce_node_pool_password
  priority           = 1
  root_volume {
    size       = 100
    volumetype = "GPSSD"
  }
  storage {
    selectors {
      name = "cceUse"
      type = "system"
    }
    groups {
      name           = "vgpaas"
      selector_names = ["cceUse"]
      cce_managed    = true
      virtual_spaces {
        name        = "kubernetes"
        size        = "10%"
        lvm_lv_type = "linear"
      }
      virtual_spaces {
        name = "runtime"
        size = "90%"
      }
    }
  }
  scale_down_cooldown_time = 0
  scall_enable             = var.charging_mode == "postPaid" ? true : false
  subnet_id                = huaweicloud_vpc_subnet.private_subnet.id
  type                     = "vm"
  charging_mode            = var.charging_mode
  period_unit              = var.charging_unit
  period                   = var.charging_period
}

# 节点池创建后扩容节点，以确保随机分布到可用区
resource "huaweicloud_cce_node_pool_scale" "init" {
  cluster_id         = huaweicloud_cce_cluster.cluster.id
  nodepool_id        = huaweicloud_cce_node_pool.node_pool.id
  scale_groups       = ["default"]
  desired_node_count = var.cce_node_pool_count
  charging_mode      = var.charging_mode
  period_unit        = var.charging_unit
  period             = var.charging_period
}

resource "huaweicloud_dcs_instance" "dcs_instance" {
  name           = "${var.resource_name_prefix}-redis"
  engine         = "Redis"
  engine_version = "7.0"
  capacity       = data.huaweicloud_dcs_flavors.flavors.capacity
  flavor         = data.huaweicloud_dcs_flavors.flavors.flavors[0].name
  availability_zones = [
    local.dcs_az[0],
    local.dcs_az[1]
  ]
  password  = var.redis_password
  vpc_id    = huaweicloud_vpc.vpc_server.id
  subnet_id = huaweicloud_vpc_subnet.private_subnet.id

  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  auto_renew    = "false"
  period        = var.charging_period

  backup_policy {
    backup_type = "auto"
    save_days   = 3
    backup_at   = [1, 3, 5, 7]
    begin_at    = "02:00-04:00"
  }

  whitelist_enable = false

  lifecycle {
    precondition {
      condition     = length(distinct(local.dcs_az)) >= 2
      error_message = "所选 DCS Redis 高可用规格必须支持至少两个不同的可用区。"
    }
  }
}

resource "huaweicloud_nat_gateway" "nat" {
  depends_on = [
    huaweicloud_rds_instance.rds,
    huaweicloud_cce_cluster.cluster
  ]
  name          = "${var.resource_name_prefix}-nat"
  spec          = "1"
  vpc_id        = huaweicloud_vpc.vpc_server.id
  subnet_id     = huaweicloud_vpc_subnet.private_subnet.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

resource "huaweicloud_nat_snat_rule" "snat_rule_1" {
  nat_gateway_id = huaweicloud_nat_gateway.nat.id
  floating_ip_id = huaweicloud_vpc_eip.eips[2].id
  subnet_id      = huaweicloud_vpc_subnet.private_subnet.id
}

resource "huaweicloud_nat_snat_rule" "snat_rule_2" {
  depends_on = [
    huaweicloud_nat_snat_rule.snat_rule_1
  ]
  nat_gateway_id = huaweicloud_nat_gateway.nat.id
  floating_ip_id = huaweicloud_vpc_eip.eips[2].id
  subnet_id      = huaweicloud_vpc_subnet.eni_cluster_1.id
}

resource "huaweicloud_nat_snat_rule" "snat_rule_3" {
  depends_on = [
    huaweicloud_nat_snat_rule.snat_rule_2
  ]
  nat_gateway_id = huaweicloud_nat_gateway.nat.id
  floating_ip_id = huaweicloud_vpc_eip.eips[2].id
  subnet_id      = huaweicloud_vpc_subnet.eni_cluster_2.id
}

resource "kubernetes_namespace" "namespace_litellm" {
  metadata {
    name = "litellm"
    labels = {
      app = "litellm"
    }
  }
}

resource "kubernetes_config_map" "configmap_litellm_env" {
  depends_on = [kubernetes_namespace.namespace_litellm]
  data = {
    TZ                 = "Asia/Shanghai"
    REDIS_HOST         = huaweicloud_dcs_instance.dcs_instance.domain_name
    REDIS_PORT         = "6379"
    USE_PRISMA_MIGRATE = "True"
  }
  metadata {
    name      = "litellm-env"
    namespace = "litellm"
  }
}

resource "kubernetes_config_map" "configmap_litellm_config" {
  depends_on = [kubernetes_namespace.namespace_litellm]
  data = {
    "config.yaml" = local.litellm_config_yaml
  }
  metadata {
    name      = "litellm-config"
    namespace = "litellm"
  }
}

resource "kubernetes_secret" "secret_litellm" {
  depends_on = [kubernetes_namespace.namespace_litellm]
  data = {
    LITELLM_MASTER_KEY   = var.litellm_master_key
    LITELLM_SALT_KEY     = var.litellm_salt_key
    DATABASE_URL         = local.pgsql_database_url
    REDIS_PASSWORD       = var.redis_password
    DRAIN_ENDPOINT_TOKEN = var.litellm_master_key
  }
  metadata {
    name      = "litellm-secret"
    namespace = "litellm"
  }
}

resource "kubernetes_deployment" "deployment_litellm_proxy" {
  depends_on = [
    kubernetes_namespace.namespace_litellm,
    kubernetes_config_map.configmap_litellm_env,
    kubernetes_config_map.configmap_litellm_config,
    kubernetes_secret.secret_litellm,
    huaweicloud_cce_node_pool_scale.init,
    huaweicloud_rds_pg_database.pgsql_database,
    huaweicloud_dcs_instance.dcs_instance,
    huaweicloud_nat_snat_rule.snat_rule_3
  ]
  metadata {
    name      = "litellm-proxy"
    namespace = "litellm"
    labels = {
      app = "litellm-proxy"
    }
  }
  spec {
    replicas = 4
    selector {
      match_labels = {
        app = "litellm-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "litellm-proxy"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/metrics"
          "prometheus.io/port"   = "4000"
        }
      }
      spec {
        termination_grace_period_seconds = 120
        container {
          name              = "litellm-proxy"
          image             = local.litellm_image
          image_pull_policy = "IfNotPresent"
          args = [
            "--config",
            "/app/config/config.yaml",
            "--port",
            "4000"
          ]

          env_from {
            config_map_ref {
              name = "litellm-env"
            }
          }
          env_from {
            secret_ref {
              name = "litellm-secret"
            }
          }
          env {
            name  = "LITELLM_MODE"
            value = "PRODUCTION"
          }
          env {
            name  = "NO_DOCS"
            value = "True"
          }
          env {
            name  = "NO_REDOC"
            value = "True"
          }

          port {
            container_port = 4000
          }

          volume_mount {
            mount_path = "/app/config"
            name       = "litellm-config"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "1000m"
              memory = "4Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "4Gi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health/readiness"
              port = 4000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health/liveliness"
              port = 4000
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "topology.kubernetes.io/zone"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = {
              app = "litellm-proxy"
            }
          }
        }

        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = {
              app = "litellm-proxy"
            }
          }
        }

        volume {
          name = "litellm-config"
          config_map {
            name = "litellm-config"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service_litellm_proxy" {
  depends_on = [kubernetes_namespace.namespace_litellm]
  metadata {
    name      = "litellm-proxy"
    namespace = "litellm"
    labels = {
      app = "litellm-proxy"
    }
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/path"   = "/metrics"
      "prometheus.io/port"   = "4000"
    }
  }
  spec {
    port {
      name        = "http"
      port        = 4000
      protocol    = "TCP"
      target_port = 4000
    }
    selector = {
      app = "litellm-proxy"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "litellm_ingress" {
  depends_on = [
    kubernetes_service.service_litellm_proxy
  ]
  metadata {
    name      = "litellm-elb"
    namespace = "litellm"
    annotations = {
      "kubernetes.io/elb.class"                 = "performance"
      "kubernetes.io/elb.id"                    = huaweicloud_elb_loadbalancer.loadbalancer.id
      "kubernetes.io/elb.port"                  = "443"
      "kubernetes.io/elb.tls-certificate-ids"   = var.elb_certificate_id
      "kubernetes.io/elb.rule-priority-enabled" = "true"
      "kubernetes.io/elb.ingress-order"         = "1"
    }
  }
  spec {
    ingress_class_name = "cce"
    rule {
      host = ""
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "litellm-proxy"
              port {
                number = 4000
              }
            }
          }
        }
      }
    }
  }
}

output "instructions" {
  depends_on = [huaweicloud_elb_loadbalancer.loadbalancer]
  value      = "部署完成后，将 ELB 证书覆盖的 DNS 域名通过 A 记录解析到 ${huaweicloud_vpc_eip.eips[0].address}，再使用该域名通过 HTTPS 访问 LiteLLM Proxy。"
}
