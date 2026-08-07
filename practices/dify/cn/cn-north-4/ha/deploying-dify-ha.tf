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

provider "huaweicloud" {
  # 资源开通的区域
  region = "cn-north-4"
}

provider "kubernetes" {
  host                   = huaweicloud_cce_cluster.cluster.certificate_clusters.1.server
  client_certificate     = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_certificate_data)
  client_key             = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_key_data)
  cluster_ca_certificate = base64decode(huaweicloud_cce_cluster.cluster.certificate_clusters.0.certificate_authority_data)
}

variable "dify_version" {
  default     = "1.7.1"
  description = "社区版Dify版本。可以选择1.7.1, 1.4.1, 0.15.8。默认1.7.1"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["1.7.1", "1.4.1", "0.15.8"], var.dify_version)
    error_message = "Invalid input please re-enter."
  }
}

variable "resource_name_prefix" {
  default     = "ha-dify-app"
  description = "资源名称前缀，命名规则{resource_name_prefix}-资源英文名称，例如：CCE集群名称为{resource_name_prefix}-cce。取值范围：4-24个字符，支持小写字母、数字、-（中划线）。必须以小写字母开头。禁止以中划线（-）开头。默认ha-dify-app"
  type        = string
  nullable    = false
  validation {
    condition     = length(regexall("^[a-z][a-z0-9-]{3,23}$", var.resource_name_prefix)) > 0
    error_message = "取值范围：4-24个字符，支持小写字母、数字、-（中划线）。必须以小写字母开头。"
  }
}

variable "bandwidth_size" {
  default     = "300"
  description = "弹性公网带宽大小，该模板计费方式为按流量计费。单位：Mbit/s，取值范围：1-300Mbit/s。默认：300。"
  type        = string
  nullable    = false
}

variable "cce_cluster_flavor" {
  default     = "cce.s2.small"
  description = "CCE Turbo集群规格，集群创建完成后规格不可再变更，可选值：cce.s2.small、cce.s2.medium、cce.s2.large、cce.s2.xlarge，具体请参考部署指南。默认为cce.s2.small(小规模多控制节点CCE集群，最大50节点)。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["cce.s2.small", "cce.s2.medium", "cce.s2.large", "cce.s2.xlarge"], var.cce_cluster_flavor)
    error_message = "Invalid input please re-enter."
  }
}

variable "cce_node_pool_password" {
  default     = ""
  description = "CCE集群node节点密码，用于集群节点登录。取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!@#$^*-=_+,?）"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "cce_node_pool_flavor" {
  default     = "x1.16u.16g"
  description = "CCE集群节点云服务器实例规格，支持弹性云服务器 ECS及华为云Flexus 云服务器X实例。Flexus 云服务器X实例规格ID命名规则为x1.?u.?g，例如2vCPUs4GiB规格ID为x1.2u.4g。请使用3vCPUs6GiB及以上规格，具体华为云Flexus 云服务器X实例规格请参考控制台。弹性云服务器 ECS规格请参考部署指南配置。默认：x1.16u.16g"
  type        = string
  nullable    = false
}

variable "rds_flavor" {
  default     = "rds.pg.x1.2xlarge.4.ha"
  description = "云数据库 RDS for PostgreSQL实例规格，该方案默认创建主备版。默认rds.pg.x1.2xlarge.4.ha（8U32G），其他规格请参考部署指南配置。"
  type        = string
  nullable    = false
}

variable "pgsql_password" {
  default     = ""
  description = "PostgreSQL数据库的管理员密码，取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,）。"
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.pgsql_password)) > 0
    error_message = "取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "pgsql_user_password" {
  default     = ""
  description = "PostgreSQL数据库的database用户密码。取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,），不能与用户名或倒序的用户名相同。"
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.pgsql_user_password)) > 0
    error_message = "取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "redis_capacity" {
  default     = 4
  description = "分布式缓存服务 Redis版实例规格。可选值：1GB-64GB。默认4GB"
  type        = number
  nullable    = false
  validation {
    condition     = contains([1, 2, 4, 8, 16, 32, 64], var.redis_capacity)
    error_message = "Invalid input please re-enter."
  }
}

variable "redis_password" {
  default     = ""
  description = "redis数据库密码。取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,）。"
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.redis_password)) > 0
    error_message = "取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!^*-=_+,）。"
  }
}

variable "plugin_dify_inner_api_key" {
  description = "Dify plugin daemon internal API key. Provide a unique secret for this deployment."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "plugin_daemon_key" {
  description = "Dify plugin daemon shared key. Provide a unique secret for this deployment."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "searxng_secret_key" {
  description = "SearXNG server secret key. Provide a unique secret for this deployment."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "sandbox_api_key" {
  description = "Dify sandbox API key. Provide a unique secret for this deployment."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "obs_bucket" {
  default     = ""
  description = "已有对象存储服务OBS桶名称，桶所属区域必须与一键部署选择的区域保持一致。用于存储Dify WebUI上传的知识库文件。获取请参考部署指南。"
  nullable    = false
  type        = string
}

variable "access_key" {
  default     = ""
  description = "访问密钥ID（AK）,识别访问用户的身份，取值范围：20，仅支持大写字母和数字，用于将知识库文件上传至OBS桶。请参考部署指南获取。"
  nullable    = false
  type        = string
  sensitive   = true
}

variable "secret_key" {
  default     = ""
  description = "秘密访问密钥（SK）,对请求数据进行签名验证，取值范围：40，仅支持大小写字母和数字，用于将知识库文件上传至OBS桶。请参考部署指南获取。"
  nullable    = false
  type        = string
  sensitive   = true
}

variable "embedding_reranker_flavor" {
  default     = "x1e.32u.32g"
  description = "（可选，置空不创建）部署Embedding和Reranker模型的云服务器规格，支持弹性云服务器 ECS（含GPU服务器）及华为云Flexus 云服务器X实例。Flexus云服务器X实例规格ID命名规则为x1e.?u.?g，例如4vCPUs4GiB规格ID为x1.4u.4g。建议使用8vCPUs8GiB及以上规格，具体华为云Flexus云服务器X实例规格请参考控制台。弹性云服务器 ECS规格请参考部署指南配置。可替换成GPU加速型获得更高性能。默认值：x1e.32u.32g。"
  nullable    = true
  type        = string
}

variable "ecs_password" {
  default     = ""
  description = "部署Embedding和Reranker模型的云服务器密码，仅当embedding_reranker_flavor有值生效。取值范围：8-24个字符，密码至少必须包含大写字母、小写字母、并包含数字或特殊字符（~!@#^*=_+,?）"
  nullable    = true
  type        = string
  sensitive   = true
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式，默认自动扣费。可选值为：postPaid（按需计费）、prePaid（包年包月）。默认：postPaid。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Invalid input please re-enter."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期类型，仅当charging_mode为prePaid（包年/包月）生效，此时该参数为必填参数。可选值为：month（月），year（年）。默认month。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Invalid input please re-enter."
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期，仅当charging_mode为prePaid（包年/包月）生效，此时该参数为必填参数。当charging_unit=month（周期类型为月）时，取值范围：1-9；当charging_unit=year（周期类型为年）时，取值范围：1-3。默认订购1个月。"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^[1-9]$", var.charging_period)) > 0
    error_message = "Invalid input please re-enter."
  }
}

# 获取可用区
data "huaweicloud_availability_zones" "availability_zones" {}

data "huaweicloud_dcs_flavors" "flavors" {
  cache_mode       = "ha"
  capacity         = var.redis_capacity
  engine_version   = "6.0"
  cpu_architecture = "x86_64"
}

data "huaweicloud_images_images" "ubuntu" {
  name_regex     = "Ubuntu."
  flavor_id      = var.embedding_reranker_flavor
  visibility     = "public"
  os             = "Ubuntu"
  sort_direction = "desc"
  architecture   = "x86"
}

data "huaweicloud_css_flavors" "flavors" {
  type = "ess"
  name = local.css_flavor
}

data "huaweicloud_cce_nodes" "node" {
  depends_on = [huaweicloud_cce_node_pool.node_pool]
  cluster_id = huaweicloud_cce_cluster.cluster.id
}

data "huaweicloud_rds_flavors" "flavor" {
  db_type       = "PostgreSQL"
  db_version    = "16"
  instance_mode = "ha"
}

locals {
  region_id           = data.huaweicloud_availability_zones.availability_zones.region
  css_flavor          = "ess.spec-4u8g"
  css_nodes_count     = 3
  css_az              = join(",", slice(split(",", data.huaweicloud_css_flavors.flavors.flavors[0].availability_zones), 0, min(3, local.css_nodes_count)))
  dcs_az              = sort(data.huaweicloud_dcs_flavors.flavors.flavors[0].available_zones)
  rds_az              = data.huaweicloud_rds_flavors.flavor.flavors[index(data.huaweicloud_rds_flavors.flavor.flavors.*.name, var.rds_flavor)].availability_zones
  dify_version_legacy = split(".", var.dify_version)[0] == "0"
  dify_version_mcp    = (split(".", var.dify_version)[0] == "1" && parseint(split(".", var.dify_version)[1], 10) >= 6) || parseint(split(".", var.dify_version)[0], 10) > 1
}

resource "huaweicloud_vpc" "vpc_server" {
  cidr = "192.168.0.0/16"
  name = "${var.resource_name_prefix}-vpc"
}

resource "huaweicloud_vpc_subnet" "public_subnet" {
  cidr       = "192.168.0.0/24"
  gateway_ip = "192.168.0.1"
  name       = "${var.resource_name_prefix}-public-subnet"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "private_subnet" {
  cidr       = "192.168.1.0/24"
  gateway_ip = "192.168.1.1"
  name       = "${var.resource_name_prefix}-private-subnet"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "eni_cluster_1" {
  name       = "subnet-eni-1"
  cidr       = "192.168.2.0/24"
  gateway_ip = "192.168.2.1"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_vpc_subnet" "eni_cluster_2" {
  name       = "subnet-eni-2"
  cidr       = "192.168.3.0/24"
  gateway_ip = "192.168.3.1"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_networking_secgroup" "secgroup_server" {
  name = "${var.resource_name_prefix}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ips_database" {
  description       = "允许vpc内网访问"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "192.168.0.0/16"
  security_group_id = huaweicloud_networking_secgroup.secgroup_server.id
}

# 弹性公网IP，分别用于CCE集群和公网ELB
# CCE集群的EIP是由于terraform访问k8s api server需要，资源全部创建完成后，如果不需要api server公网访问，可以释放
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

# 部署embedding和reranker模型
resource "huaweicloud_compute_instance" "ecs" {
  depends_on = [
    huaweicloud_nat_snat_rule.snat_rule_1
  ]
  count     = var.embedding_reranker_flavor == "" ? 0 : 1
  name      = "${var.resource_name_prefix}-embedding-reranker"
  image_id  = data.huaweicloud_images_images.ubuntu.images[0].id
  flavor_id = var.embedding_reranker_flavor
  security_group_ids = [
    huaweicloud_networking_secgroup.secgroup_server.id
  ]
  system_disk_type            = "GPSSD"
  system_disk_size            = 40
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.private_subnet.id
  }
  agent_list    = "hss,ces"
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  user_data     = "#!/bin/bash\necho 'root:${var.ecs_password}' | chpasswd\nwget -P /home/ https://documentation-samples.obs.cn-north-4.myhuaweicloud.com/solution-as-code-publicbucket/solution-as-code-moudle/deploying-embedding-and-reranker-models/userdata/install-model.sh\nbash /home/install-model.sh &> /home/install-model.log\nrm -rf /home/install-model.sh"
}

# 公网ELB，连接CCE
resource "huaweicloud_elb_loadbalancer" "loadbalancer" {
  name            = "${var.resource_name_prefix}-lb"
  ipv4_subnet_id  = huaweicloud_vpc_subnet.public_subnet.ipv4_subnet_id
  backend_subnets = [huaweicloud_vpc_subnet.private_subnet.id]
  availability_zone = [
    data.huaweicloud_availability_zones.availability_zones.names[0],
    data.huaweicloud_availability_zones.availability_zones.names[1]
  ]
  autoscaling_enabled = true
  ipv4_eip_id         = huaweicloud_vpc_eip.eips[0].id
}

# NAT网关
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

# 为private subnet提供公网访问
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
    password = var.pgsql_password
  }
  volume {
    type = "CLOUDSSD"
    size = 100
  }

  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

resource "huaweicloud_rds_pg_account" "pgsql_user" {
  instance_id = huaweicloud_rds_instance.rds.id
  name        = "postgres"
  password    = var.pgsql_user_password
}

resource "huaweicloud_rds_pg_database" "pgsql_database" {
  depends_on    = [huaweicloud_rds_pg_account.pgsql_user]
  instance_id   = huaweicloud_rds_instance.rds.id
  name          = "dify"
  owner         = huaweicloud_rds_pg_account.pgsql_user.name
}

resource "huaweicloud_rds_pg_database" "pgsql_database_plugin" {
  depends_on    = [huaweicloud_rds_pg_account.pgsql_user]
  count         = local.dify_version_legacy ? 0 : 1
  instance_id   = huaweicloud_rds_instance.rds.id
  name          = "dify_plugin"
  owner         = huaweicloud_rds_pg_account.pgsql_user.name
}

resource "huaweicloud_rds_pg_database_privilege" "privilege" {
  depends_on = [
    huaweicloud_rds_pg_account.pgsql_user, huaweicloud_rds_pg_database.pgsql_database
  ]
  instance_id = huaweicloud_rds_instance.rds.id
  db_name     = huaweicloud_rds_pg_database.pgsql_database.name
  users {
    name        = huaweicloud_rds_pg_account.pgsql_user.name
    readonly    = false
    schema_name = "public"
  }
}

resource "huaweicloud_rds_pg_database_privilege" "privilege_plugin" {
  depends_on = [
    huaweicloud_rds_pg_account.pgsql_user, huaweicloud_rds_pg_database.pgsql_database_plugin
  ]
  count       = local.dify_version_legacy ? 0 : 1
  instance_id = huaweicloud_rds_instance.rds.id
  db_name     = huaweicloud_rds_pg_database.pgsql_database_plugin[0].name
  users {
    name        = huaweicloud_rds_pg_account.pgsql_user.name
    readonly    = false
    schema_name = "public"
  }
}

resource "huaweicloud_cce_cluster" "cluster" {
  depends_on = [
    huaweicloud_elb_loadbalancer.loadbalancer
  ]
  name                   = "${var.resource_name_prefix}-cluster"
  flavor_id              = var.cce_cluster_flavor
  cluster_version        = "v1.31"
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
    app = "Dify-CCE"
  }
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

# CCE节点池
resource "huaweicloud_cce_node_pool" "node_pool" {
  depends_on         = [huaweicloud_rds_pg_database.pgsql_database, huaweicloud_rds_pg_database.pgsql_database_plugin]
  cluster_id         = huaweicloud_cce_cluster.cluster.id
  availability_zone  = "random"
  flavor_id          = var.cce_node_pool_flavor
  initial_node_count = 3 # 批量创建的节点会位于同个可用区
  max_node_count     = 10
  min_node_count     = 0
  name               = "${var.resource_name_prefix}-pool"
  os                 = "Ubuntu 24.04"
  password           = var.cce_node_pool_password
  priority           = 1
  root_volume {
    size       = 40
    volumetype = "SAS"
  }
  data_volumes {
    size       = 100
    volumetype = "SAS"
  }
  scale_down_cooldown_time = 0
  scall_enable             = true
  subnet_id                = huaweicloud_vpc_subnet.private_subnet.id
  type                     = "vm"
}

resource "huaweicloud_dcs_instance" "dcs_instance" {
  name           = "${var.resource_name_prefix}-redis"
  engine         = "Redis"
  engine_version = "6.0"
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
  auto_renew    = "true"
  period        = var.charging_period

  backup_policy {
    backup_type = "auto"
    save_days   = 3
    backup_at   = [1, 3, 5, 7]
    begin_at    = "02:00-04:00"
  }

  whitelist_enable = false

  parameters {
    id    = "1"
    name  = "timeout"
    value = "500"
  }
  parameters {
    id    = "3"
    name  = "hash-max-ziplist-entries"
    value = "4096"
  }
}

resource "huaweicloud_css_cluster" "css" {
  name           = "${var.resource_name_prefix}-css"
  engine_type    = "elasticsearch"
  engine_version = "7.10.2"

  ess_node_config {
    flavor          = local.css_flavor
    instance_number = local.css_nodes_count
    volume {
      volume_type = "ULTRAHIGH"
      size        = 40
    }
  }

  availability_zone = local.css_az
  vpc_id            = huaweicloud_vpc.vpc_server.id
  subnet_id         = huaweicloud_vpc_subnet.private_subnet.id
  security_group_id = huaweicloud_networking_secgroup.secgroup_server.id
  vpcep_endpoint {
    endpoint_with_dns_name = true
  }

  security_mode = false
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period

  lifecycle {
    ignore_changes = [
      availability_zone
    ]
  }
}

resource "kubernetes_namespace" "namespace_dify" {
  metadata {
    name = "dify"
  }
}

resource "kubernetes_config_map" "configmap_dify_sandbox_env" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    TZ             = "Asia/Shanghai"
    LOG_TZ         = "Asia/Shanghai"
    API_KEY        = var.sandbox_api_key
    GIN_MODE       = "release"
    WORKER_TIMEOUT = "15"
    ENABLE_NETWORK = "true"
    SANDBOX_PORT   = "8194"
    HTTP_PROXY     = "http://dify-ssrf:3128"
    HTTPS_PROXY    = "http://dify-ssrf:3128"
    PIP_MIRROR_URL = "https://pypi.tuna.tsinghua.edu.cn/simple"
  }
  metadata {
    name      = "dify-sandbox-env"
    namespace = "dify"
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_sandbox" {
  depends_on = [
    kubernetes_namespace.namespace_dify,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_dify_sandbox_env
  ]
  metadata {
    labels = {
      "app" = "dify-sandbox"
    }
    name      = "dify-sandbox"
    namespace = "dify"
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "dify-sandbox"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-sandbox"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "dify-sandbox-env"
            }
          }
          image             = "langgenius/dify-sandbox:${local.dify_version_legacy ? "0.2.11" : "0.2.12"}"
          image_pull_policy = "IfNotPresent"
          name              = "dify-sandbox"
          port {
            container_port = 8194
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-sandbox"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_dify_sandbox" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "dify-sandbox"
    namespace = "dify"
  }
  spec {
    # cluster_ip = "None"
    port {
      name        = "dify-sandbox"
      port        = 8194
      protocol    = "TCP"
      target_port = 8194
    }
    selector = {
      app = "dify-sandbox"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "configmap_dify_ssrf_proxy_config" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    "squid.conf" = <<-EOT
      acl localnet src 0.0.0.1-0.255.255.255	# RFC 1122 "this" network (LAN)
      acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
      acl localnet src 100.64.0.0/10		# RFC 6598 shared address space (CGN)
      acl localnet src 169.254.0.0/16 	# RFC 3927 link-local (directly plugged) machines
      acl localnet src 172.16.0.0/12		# RFC 1918 local private network (LAN)
      acl localnet src 192.168.0.0/16		# RFC 1918 local private network (LAN)
      acl localnet src fc00::/7       	# RFC 4193 local private network range
      acl localnet src fe80::/10      	# RFC 4291 link-local (directly plugged) machines
      acl SSL_ports port 443
      acl Safe_ports port 80		# http
      acl Safe_ports port 21		# ftp
      acl Safe_ports port 443		# https
      acl Safe_ports port 70		# gopher
      acl Safe_ports port 210		# wais
      acl Safe_ports port 1025-65535	# unregistered ports
      acl Safe_ports port 280		# http-mgmt
      acl Safe_ports port 488		# gss-http
      acl Safe_ports port 591		# filemaker
      acl Safe_ports port 777		# multiling http
      acl CONNECT method CONNECT
      http_access deny !Safe_ports
      http_access deny CONNECT !SSL_ports
      http_access allow localhost manager
      http_access deny manager
      http_access allow localhost
      http_access allow localnet
      http_access deny all

      ################################## Proxy Server ################################
      http_port 3128
      coredump_dir /var/spool/squid
      refresh_pattern ^ftp:		1440	20%	10080
      refresh_pattern ^gopher:	1440	0%	1440
      refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
      refresh_pattern \/(Packages|Sources)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
      refresh_pattern \/Release(|\.gpg)$ 0 0% 0 refresh-ims
      refresh_pattern \/InRelease$ 0 0% 0 refresh-ims
      refresh_pattern \/(Translation-.*)(|\.bz2|\.gz|\.xz)$ 0 0% 0 refresh-ims
      refresh_pattern .		0	20%	4320


      # upstream proxy, set to your own upstream proxy IP to avoid SSRF attacks
      # cache_peer 172.1.1.1 parent 3128 0 no-query no-digest no-netdb-exchange default 


      ################################## Reverse Proxy To Sandbox ################################
      http_port 8194 accel vhost
      # Notice:
      # default is 'sandbox' in dify's github repo, here is 'dify-sandbox' because the service name of sandbox is 'dify-sandbox'
      # you can change it to your own service name
      cache_peer dify-sandbox parent 8194 0 no-query originserver
      acl src_all src all
      http_access allow src_all

      EOT
  }
  metadata {
    name      = "ssrf-proxy-config"
    namespace = "dify"
  }
}

resource "kubernetes_config_map" "configmap_dify_ssrf_proxy_entrypoint" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    "docker-entrypoint-mount.sh" = <<-EOT
      #!/bin/bash

      # Modified based on Squid OCI image entrypoint

      # This entrypoint aims to forward the squid logs to stdout to assist users of
      # common container related tooling (e.g., kubernetes, docker-compose, etc) to
      # access the service logs.

      # Moreover, it invokes the squid binary, leaving all the desired parameters to
      # be provided by the "command" passed to the spawned container. If no command
      # is provided by the user, the default behavior (as per the CMD statement in
      # the Dockerfile) will be to use Ubuntu's default configuration [1] and run
      # squid with the "-NYC" options to mimic the behavior of the Ubuntu provided
      # systemd unit.

      # [1] The default configuration is changed in the Dockerfile to allow local
      # network connections. See the Dockerfile for further information.

      echo "[ENTRYPOINT] re-create snakeoil self-signed certificate removed in the build process"
      if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
          /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite > /dev/null 2>&1
      fi

      tail -F /var/log/squid/access.log 2>/dev/null &
      tail -F /var/log/squid/error.log 2>/dev/null &
      tail -F /var/log/squid/store.log 2>/dev/null &
      tail -F /var/log/squid/cache.log 2>/dev/null &

      # Replace environment variables in the template and output to the squid.conf
      echo "[ENTRYPOINT] replacing environment variables in the template"
      awk '{
          while(match($0, /\$${[A-Za-z_][A-Za-z_0-9]*}/)) {
              var = substr($0, RSTART+2, RLENGTH-3)
              val = ENVIRON[var]
              $0 = substr($0, 1, RSTART-1) val substr($0, RSTART+RLENGTH)
          }
          print
      }' /etc/squid/squid.conf.template > /etc/squid/squid.conf

      /usr/sbin/squid -Nz
      echo "[ENTRYPOINT] starting squid"
      /usr/sbin/squid -f /etc/squid/squid.conf -NYC 1

      EOT
  }
  metadata {
    name      = "ssrf-proxy-entrypoint"
    namespace = "dify"
  }
}

resource "kubernetes_config_map" "configmap_dify_ssrf_env" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    HTTP_PORT          = "3128"
    COREDUMP_DIR       = "/var/spool/squid"
    REVERSE_PROXY_PORT = "8194"
    SANDBOX_HOST       = "dify-sandbox"
    SANDBOX_PORT       = "8194"
  }
  metadata {
    name      = "dify-ssrf-env"
    namespace = "dify"
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_ssrf" {
  depends_on = [kubernetes_namespace.namespace_dify, huaweicloud_cce_node_pool.node_pool, kubernetes_config_map.configmap_dify_ssrf_env]
  metadata {
    labels = {
      "app" = "dify-ssrf"
    }
    name      = "dify-ssrf"
    namespace = "dify"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "dify-ssrf"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-ssrf"
        }
      }
      spec {
        container {
          command = [
            "sh",
            "-c",
            "cp /tmp/docker-entrypoint-mount.sh /docker-entrypoint.sh && sed -i 's/\r$$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh && /docker-entrypoint.sh",
          ]

          env_from {
            config_map_ref {
              name = "dify-ssrf-env"
            }
          }

          image = "ubuntu/squid:latest"
          name  = "dify-ssrf"
          port {
            container_port = 3128
            name           = "dify-ssrf"
          }

          resources {
            limits = {
              cpu    = "300m"
              memory = "300Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          volume_mount {
            mount_path = "/etc/squid/"
            name       = "ssrf-proxy-config"
          }
          volume_mount {
            mount_path = "/tmp/"
            name       = "ssrf-proxy-entrypoint"
          }

          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "squid -k check"]
            }
            initial_delay_seconds = 15
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        restart_policy = "Always"
        volume {
          config_map {
            name = "ssrf-proxy-config"
          }
          name = "ssrf-proxy-config"
        }
        volume {
          config_map {
            name = "ssrf-proxy-entrypoint"
          }
          name = "ssrf-proxy-entrypoint"
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-ssrf"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_dify_ssrf" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "dify-ssrf"
    namespace = "dify"
  }
  spec {
    port {
      port        = 3128
      protocol    = "TCP"
      target_port = 3128
    }
    selector = {
      app = "dify-ssrf"
    }
  }
}

resource "kubernetes_config_map" "configmap_dify_shared_env" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    TZ                        = "Asia/Shanghai"
    LOG_TZ                    = "Asia/Shanghai"
    LOG_LEVEL                 = "INFO"
    CONSOLE_WEB_URL           = ""
    CONSOLE_API_URL           = ""
    SERVICE_API_URL           = ""
    APP_WEB_URL               = ""
    FILES_URL                 = ""
    MIGRATION_ENABLED         = "true"
    DB_USERNAME               = "postgres"
    DB_HOST                   = huaweicloud_rds_instance.rds.private_ips[0]
    DB_PORT                   = "5432"
    DB_DATABASE               = "dify"
    REDIS_HOST                = huaweicloud_dcs_instance.dcs_instance.domain_name
    REDIS_PORT                = "6379"
    REDIS_USERNAME            = ""
    REDIS_USE_SSL             = "false"
    REDIS_DB                  = "0"
    STORAGE_TYPE              = "huawei-obs"
    HUAWEI_OBS_BUCKET_NAME    = trimspace(var.obs_bucket)
    HUAWEI_OBS_SERVER         = "https://obs.${local.region_id}.myhuaweicloud.com"
    VECTOR_STORE               = "elasticsearch"
    ELASTICSEARCH_HOST         = huaweicloud_css_cluster.css.vpcep_ip
    ELASTICSEARCH_PORT         = "9200"
    ELASTICSEARCH_USERNAME     = ""
    ELASTICSEARCH_USE_CLOUD    = "false"
    ELASTICSEARCH_VERIFY_CERTS = "false"
    SSRF_PROXY_HTTP_URL       = "http://dify-ssrf:3128"
    SSRF_PROXY_HTTPS_URL      = "http://dify-ssrf:3128"
    CODE_EXECUTION_ENDPOINT   = "http://dify-sandbox:8194"
    SENTRY_DSN                = ""
    APP_MAX_ACTIVE_REQUESTS   = "0"
    APP_MAX_EXECUTION_TIME    = "1200"
    MAX_SUBMIT_COUNT          = "100"
    SERVER_WORKER_CLASS       = "gevent"
    SERVER_WORKER_AMOUNT      = "1"
    SERVER_WORKER_CONNECTIONS = "256"
    GUNICORN_TIMEOUT          = "360"
    CELERY_AUTO_SCALE         = "true"
    SQLALCHEMY_MAX_OVERFLOW                 = "160"
    SQLALCHEMY_POOL_RECYCLE                 = "900"
    SQLALCHEMY_POOL_SIZE                    = "80"
    
    UPLOAD_FILE_SIZE_LIMIT                  = "150"
    UPLOAD_FILE_BATCH_LIMIT                 = "5"
    PROMPT_GENERATION_MAX_TOKENS            = "1024"
    CODE_GENERATION_MAX_TOKENS              = "1024"
    MAIL_TYPE                               = "smtp"
    SMTP_SERVER                             = "example.com"
    SMTP_PORT                               = "465"
    INDEXING_MAX_SEGMENTATION_TOKENS_LENGTH = "4000"
    TOP_K_MAX_VALUE                         = "10"
    # 1.0.0以上版本需要的参数
    PLUGIN_MAX_PACKAGE_SIZE           = "52428800"
    PLUGIN_DAEMON_URL                 = "http://dify-plugin-daemon:5002"
    PLUGIN_REMOTE_INSTALL_HOST        = "dify-plugin-daemon"
    PLUGIN_REMOTE_INSTALL_PORT        = "5003"
    FORCE_VERIFYING_SIGNATURE         = "false"
    HTTP_REQUEST_NODE_MAX_BINARY_SIZE = "10485760"
    HTTP_REQUEST_NODE_MAX_TEXT_SIZE   = "1048576"
    CODE_MAX_STRING_LENGTH            = "80000"
  }
  metadata {
    name      = "dify-shared-env"
    namespace = "dify"
  }
}

resource "kubernetes_secret" "secret_dify_shared_secret" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    SECRET_KEY            = var.pgsql_user_password
    DB_PASSWORD           = var.pgsql_user_password
    REDIS_PASSWORD        = var.redis_password
    CELERY_BROKER_URL     = "redis://:${var.redis_password}@${huaweicloud_dcs_instance.dcs_instance.domain_name}:6379/1"
    SEARXNG_REDIS_URL     = "redis://:${var.redis_password}@${huaweicloud_dcs_instance.dcs_instance.domain_name}:6379/2"
    HUAWEI_OBS_SECRET_KEY = var.secret_key
    HUAWEI_OBS_ACCESS_KEY = var.access_key
    ELASTICSEARCH_PASSWORD = ""
    # 1.0.0以上版本需要的参数
    PLUGIN_DIFY_INNER_API_KEY = var.plugin_dify_inner_api_key
    PLUGIN_DAEMON_KEY         = var.plugin_daemon_key
  }
  metadata {
    name      = "dify-shared-secret"
    namespace = "dify"
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_api" {
  depends_on = [
    kubernetes_namespace.namespace_dify,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_dify_shared_env,
    kubernetes_secret.secret_dify_shared_secret,
    huaweicloud_rds_pg_database.pgsql_database
  ]
  metadata {
    labels = {
      "app" = "dify-api"
    }
    name      = "dify-api"
    namespace = "dify"
  }
  spec {
    replicas = 5
    selector {
      match_labels = {
        app = "dify-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-api"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "dify-shared-env"
            }
          }
          env_from {
            secret_ref {
              name = "dify-shared-secret"
            }
          }
          env {
            name  = "MODE"
            value = "api"
          }
          env {
            name = "INNER_API_KEY_FOR_PLUGIN"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "PLUGIN_DIFY_INNER_API_KEY"
              }
            }
          }
          image             = "langgenius/dify-api:${var.dify_version}"
          image_pull_policy = "IfNotPresent"
          name              = "dify-api"
          port {
            container_port = 5001
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path   = "/console/api/ping"
              port   = "5001"
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-api"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_dify_api" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "dify-api"
    namespace = "dify"
  }
  spec {
    port {
      name        = "dify-api"
      port        = 5001
      protocol    = "TCP"
      target_port = 5001
    }

    selector = {
      app = "dify-api"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_worker" {
  depends_on = [
    kubernetes_namespace.namespace_dify,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_dify_shared_env,
    kubernetes_secret.secret_dify_shared_secret,
    huaweicloud_rds_pg_database.pgsql_database
  ]
  metadata {
    labels = {
      "app" = "dify-worker"
    }
    name      = "dify-worker"
    namespace = "dify"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "dify-worker"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-worker"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "dify-shared-env"
            }
          }
          env_from {
            secret_ref {
              name = "dify-shared-secret"
            }
          }
          env {
            name  = "MODE"
            value = "worker"
          }
          env {
            name = "INNER_API_KEY_FOR_PLUGIN"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "PLUGIN_DIFY_INNER_API_KEY"
              }
            }
          }
          image             = "langgenius/dify-api:${var.dify_version}"
          image_pull_policy = "IfNotPresent"
          name              = "dify-worker"
          port {
            container_port = 5001
            protocol       = "TCP"
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "source /app/api/.venv/bin/activate && /app/api/.venv/bin/celery inspect ping -d celery@$HOSTNAME"]
            }
            initial_delay_seconds = 30
            timeout_seconds       = 3
            period_seconds        = 60
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        restart_policy = "Always"
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-worker"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_worker_beat" {
  count = local.dify_version_mcp ? 1 : 0
  depends_on = [
    kubernetes_namespace.namespace_dify,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_dify_shared_env,
    kubernetes_secret.secret_dify_shared_secret
  ]
  metadata {
    labels = {
      "app" = "dify-worker-beat"
    }
    name      = "dify-worker-beat"
    namespace = "dify"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "dify-worker-beat"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-worker-beat"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "dify-shared-env"
            }
          }
          env_from {
            secret_ref {
              name = "dify-shared-secret"
            }
          }
          env {
            name  = "MODE"
            value = "beat"
          }
          env {
            name = "INNER_API_KEY_FOR_PLUGIN"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "PLUGIN_DIFY_INNER_API_KEY"
              }
            }
          }
          image             = "langgenius/dify-api:${var.dify_version}"
          image_pull_policy = "IfNotPresent"
          name              = "dify-worker-beat"
          port {
            container_port = 5001
            protocol       = "TCP"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "source /app/api/.venv/bin/activate && /app/api/.venv/bin/celery inspect ping | grep -q OK"]
            }
            initial_delay_seconds = 30
            timeout_seconds       = 3
            period_seconds        = 60
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        restart_policy = "Always"
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-worker-beat"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_dify_worker" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "dify-worker"
    namespace = "dify"
  }
  spec {
    port {
      port        = 5001
      protocol    = "TCP"
      target_port = 5001
    }
    selector = {
      app = "dify-worker"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "configmap_dify_web_env" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    TZ                         = "Asia/Shanghai"
    LOG_TZ                     = "Asia/Shanghai"
    EDITION                    = "SELF_HOSTED"
    NEXT_TELEMETRY_DISABLED    = ""
    TEXT_GENERATION_TIMEOUT_MS = ""
    CONSOLE_API_URL            = ""
    APP_API_URL                = ""
    # 1.0.0以上版本需要的参数
    MARKETPLACE_API_URL       = "https://marketplace.dify.ai"
    MARKETPLACE_URL           = "https://marketplace.dify.ai"
    PM2_INSTANCES             = "2"
    LOOP_NODE_MAX_COUNT       = "100"
    MAX_TOOLS_NUM             = "10"
    MAX_PARALLEL_LIMIT        = "10"
    MAX_ITERATIONS_NUM        = "5"
    ENABLE_WEBSITE_JINAREADER = "true"
    ENABLE_WEBSITE_FIRECRAWL  = "true"
    ENABLE_WEBSITE_WATERCRAWL = "true"
    ALLOW_EMBED               = "false"
  }
  metadata {
    name      = "dify-web-env"
    namespace = "dify"
  }
}

resource "kubernetes_deployment" "deployment_dify_dify_web" {
  depends_on = [kubernetes_namespace.namespace_dify, huaweicloud_cce_node_pool.node_pool, kubernetes_config_map.configmap_dify_web_env]
  metadata {
    labels = {
      "app" = "dify-web"
    }
    name      = "dify-web"
    namespace = "dify"
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "dify-web"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-web"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "dify-web-env"
            }
          }
          image             = "langgenius/dify-web:${var.dify_version}"
          image_pull_policy = "IfNotPresent"
          name              = "dify-web"
          port {
            container_port = 3000
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "pm2 list | grep online"]
            }
            initial_delay_seconds = 10
            timeout_seconds       = 3
            period_seconds        = 60
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-web"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_dify_web" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "dify-web"
    namespace = "dify"
  }
  spec {
    port {
      name        = "dify-web"
      port        = 3000
      protocol    = "TCP"
      target_port = 3000
    }
    selector = {
      app = "dify-web"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment" "deployment_dify_plugin" {
  depends_on = [
    kubernetes_namespace.namespace_dify,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_dify_shared_env,
    kubernetes_secret.secret_dify_shared_secret,
    huaweicloud_rds_pg_database.pgsql_database_plugin
  ]
  count = local.dify_version_legacy ? 0 : 1
  metadata {
    labels = {
      "app" = "dify-plugin-daemon"
    }
    name      = "dify-plugin-daemon"
    namespace = "dify"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "dify-plugin-daemon"
      }
    }
    template {
      metadata {
        labels = {
          app = "dify-plugin-daemon"
        }
      }
      spec {
        volume {
          name = "dify-plugin-daemon-storage"
          host_path {
            path = "/root/dify/app/plugin/storage"
            type = "DirectoryOrCreate"
          }
        }
        container {
          env {
            name  = "TZ"
            value = "Asia/Shanghai"
          }
          env {
            name  = "LOG_TZ"
            value = "Asia/Shanghai"
          }
          env {
            name = "DB_USERNAME"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "DB_USERNAME"
              }
            }
          }
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "DB_PASSWORD"
              }
            }
          }
          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "DB_HOST"
              }
            }
          }
          env {
            name = "DB_PORT"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "DB_PORT"
              }
            }
          }
          env {
            name = "REDIS_HOST"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "REDIS_HOST"
              }
            }
          }
          env {
            name = "REDIS_PORT"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "REDIS_PORT"
              }
            }
          }
          env {
            name = "REDIS_USERNAME"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "REDIS_USERNAME"
              }
            }
          }
          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "REDIS_PASSWORD"
              }
            }
          }
          env {
            name = "REDIS_USE_SSL"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "REDIS_USE_SSL"
              }
            }
          }
          env {
            name  = "REDIS_DB"
            value = "3"
          }
          env {
            name = "CELERY_BROKER_URL"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "CELERY_BROKER_URL"
              }
            }
          }
          env {
            name  = "DB_DATABASE"
            value = "dify_plugin"
          }
          env {
            name  = "SERVER_PORT"
            value = "5002"
          }
          env {
            name  = "EXPOSE_PLUGIN_DAEMON_PORT"
            value = "5002"
          }
          env {
            name = "SERVER_KEY"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "PLUGIN_DAEMON_KEY"
              }
            }
          }
          env {
            name  = "MAX_PLUGIN_PACKAGE_SIZE"
            value = "52428800"
          }
          env {
            name  = "PPROF_ENABLED"
            value = "false"
          }
          env {
            name  = "DIFY_INNER_API_URL"
            value = "http://dify-api:5001"
          }
          env {
            name = "DIFY_INNER_API_KEY"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "PLUGIN_DIFY_INNER_API_KEY"
              }
            }
          }
          env {
            name  = "PLUGIN_REMOTE_INSTALLING_HOST"
            value = "0.0.0.0"
          }
          env {
            name  = "PLUGIN_REMOTE_INSTALLING_PORT"
            value = "5003"
          }
          env {
            name  = "PLUGIN_WORKING_PATH"
            value = "/app/storage/cwd"
          }
          env {
            name  = "FORCE_VERIFYING_SIGNATURE"
            value = "false"
          }
          env {
            name  = "EXPOSE_PLUGIN_DEBUGGING_HOST"
            value = "localhost"
          }
          env {
            name  = "EXPOSE_PLUGIN_DEBUGGING_PORT"
            value = "5003"
          }
          env {
            name  = "PYTHON_ENV_INIT_TIMEOUT"
            value = "120"
          }
          env {
            name  = "PLUGIN_MAX_EXECUTION_TIMEOUT"
            value = "600"
          }
          env {
            name  = "PIP_MIRROR_URL"
            value = "https://pypi.tuna.tsinghua.edu.cn/simple"
          }
          env {
            name  = "PLUGIN_STORAGE_TYPE"
            value = "local"
          }
          env {
            name = "HUAWEI_OBS_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "HUAWEI_OBS_ACCESS_KEY"
              }
            }
          }
          env {
            name = "HUAWEI_OBS_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "HUAWEI_OBS_SECRET_KEY"
              }
            }
          }
          env {
            name = "PLUGIN_STORAGE_OSS_BUCKET"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "HUAWEI_OBS_BUCKET_NAME"
              }
            }
          }
          env {
            name = "HUAWEI_OBS_SERVER"
            value_from {
              config_map_key_ref {
                name = "dify-shared-env"
                key  = "HUAWEI_OBS_SERVER"
              }
            }
          }

          image             = "langgenius/dify-plugin-daemon:0.2.0-local"
          image_pull_policy = "IfNotPresent"
          name              = "dify-plugin-daemon"
          port {
            name           = "debug-port"
            container_port = 5003
          }
          port {
            name           = "service-port"
            container_port = 5002
          }
          resources {
            limits = {
              cpu    = "2"
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
          volume_mount {
            mount_path = "/app/storage"
            name       = "dify-plugin-daemon-storage"
          }
          liveness_probe {
            http_get {
              path   = "/health/check"
              port   = "5002"
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "dify-plugin-daemon"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "In"
                  values   = [data.huaweicloud_cce_nodes.node.nodes[0].private_ip]
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service_dify_plugin" {
  depends_on = [kubernetes_namespace.namespace_dify]
  count      = local.dify_version_legacy ? 0 : 1
  metadata {
    name      = "dify-plugin-daemon"
    namespace = "dify"
  }
  spec {
    port {
      name        = "dify-plugin-daemon-service-port"
      port        = 5002
      protocol    = "TCP"
      target_port = 5002
    }
    port {
      name        = "dify-plugin-daemon-debug-port"
      port        = 5003
      protocol    = "TCP"
      target_port = 5003
    }
    selector = {
      app = "dify-plugin-daemon"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_config_map" "configmap_searxng" {
  depends_on = [kubernetes_namespace.namespace_dify]
  data = {
    "settings.yml" = <<-EOT
      search:
        safe_search: 1
        max_results: 50
        results_per_page: 50   # 默认每页结果数（API 的 count 可覆盖）
        request_timeout: 4
        max_page: 2            # 允许的最大页码（API 的 pageno 不可超过此值）
        time_range:
          - month
        formats:
          - html
          - json

      server:
        limiter: false
        secret_key: "${var.searxng_secret_key}"

      redis:
        url: false

      # 请求指纹核心配置块
      request_fingerprint:
        enabled: true               # 总开关
        tls:
          version: "TLSv1.3"        # 强制协议版本
          cipher_suite: "RANDOM"    # 随机选择密码套件
          extensions: ["GREASE"]     # 启用 GREASE 扩展混淆
        http:
          header_rotation: true      # 随机化 HTTP 头顺序
          user_agents:               # User-Agent 池
            # Windows 桌面端
            - "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.58 Safari/537.36 Edg/123.0.2420.81"
            - "Mozilla/5.0 (Windows NT 11.0; WOW64; Trident/7.0; rv:11.0) like Gecko"  # IE 兼容模式
            - "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0"

            # macOS 桌面端
            - "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
            - "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.105 Safari/537.36"

            # Linux 桌面端
            - "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.105 Safari/537.36"
            - "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0"

            # iOS 移动端
            - "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
            - "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/123.0.6312.52 Mobile/15E148 Safari/604.1"  # iOS Chrome

            # Android 移动端
            - "Mozilla/5.0 (Linux; Android 14; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.105 Mobile Safari/537.36"
            - "Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.105 Mobile Safari/537.36"

            # 特殊设备
            - "Mozilla/5.0 (Nintendo Switch; WebApplet) AppleWebKit/609.4 (KHTML, like Gecko) NF/6.0.3.2 NintendoBrowser/5.1.0.24436"  # Switch 浏览器
            - "Mozilla/5.0 (Web0S; Linux/SmartTV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.6261.89 Safari/537.36 WebAppManager"  # LG WebOS 电视

          accept_language:           # 语言头随机化规则
            base: "en-US,en;q=0.9"
            variance: 3              # 允许最多3个附加区域变体
        behavior:
          mouse_jitter: 0.2          # 光标移动抖动率（0-1）
          request_delay:             # 请求间隔动态分布
            min: 1.5                 # 最小延迟（秒）
            max: 4.0                 # 最大延迟（秒）
            distribution: "normal"   # 延迟分布模型（normal/exponential）
        dynamic_generation:
          enabled: true
          model: "lstm"                  # 使用 LSTM 网络生成特征
          update_interval: 3600          # 每小时更新指纹库
          blacklist_threshold: 0.85      # 当特征匹配黑名单概率>85%时自动重置
        caching:
          enabled: true
          max_size: 1000         # 最大缓存指纹数
          ttl: 86400             # 缓存有效期（秒）
          whitelist_strategy: "lru"
      hardware_fingerprint:
        webgl:
          precision: "highp"             # 渲染精度设置
          hash_algorithm: "sha256"        # 指纹哈希算法
        audio_context: true               # 启用音频上下文指纹
      performance:
        pregenerate_pool: 20      # 保持 20 个就绪指纹待用
        generation_threads: 4     # 使用 4 个后台生成线程

      engines:
        - name: baidu
          engine: baidu
          categories: general
          shortcut: bd
          enabled: true
          weight: 1.5
          max_results: 40
          
        - name: sogou
          engine: sogou
          shortcut: sg
          enabled: true
          weight: 0.5
          max_results: 40

        - name: 360search
          engine: 360search
          shortcut: s360
          enabled: true
          weight: 0.5
          max_results: 40
          
      doi_resolvers:
        oadoi.org: 'https://oadoi.org/'

      default_doi_resolver: 'oadoi.org'

      EOT
  }
  metadata {
    name      = "searxng-settings"
    namespace = "dify"
  }
}

resource "kubernetes_deployment" "deployment_searxng" {
  depends_on = [kubernetes_namespace.namespace_dify, huaweicloud_cce_node_pool.node_pool]
  metadata {
    labels = {
      "app" = "searxng"
    }
    name      = "searxng"
    namespace = "dify"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "searxng"
      }
    }
    template {
      metadata {
        labels = {
          app = "searxng"
        }
      }
      spec {
        container {
          env {
            name = "SEARXNG_REDIS_URL"
            value_from {
              secret_key_ref {
                name = "dify-shared-secret"
                key  = "SEARXNG_REDIS_URL"
              }
            }
          }
          image             = "searxng/searxng:latest"
          image_pull_policy = "IfNotPresent"
          name              = "searxng"
          port {
            container_port = 8080
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
          volume_mount {
            mount_path = "/etc/searxng/settings.yml"
            name       = "searxng-settings"
            sub_path   = "settings.yml"
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "8080"
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
        volume {
          config_map {
            name         = "searxng-settings"
            default_mode = "0644"
          }
          name = "searxng-settings"
        }
        topology_spread_constraint {
          label_selector {
            match_labels = {
              "app" = "searxng"
            }
          }
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
        }
      }
    }
  }
}

resource "kubernetes_service" "service_searxng" {
  depends_on = [kubernetes_namespace.namespace_dify]
  metadata {
    name      = "searxng"
    namespace = "dify"
  }
  spec {
    port {
      name        = "searxng"
      port        = 8080
      protocol    = "TCP"
      target_port = 8080
    }
    selector = {
      app = "searxng"
    }
    type = "ClusterIP"
  }
}

# 配置ELB Ingress
resource "kubernetes_ingress_v1" "dify-ingress" {
  depends_on = [
    kubernetes_service.service_dify_dify_web,
    kubernetes_service.service_dify_dify_worker,
    kubernetes_service.service_dify_dify_api,
    kubernetes_service.service_dify_dify_sandbox,
    kubernetes_service.service_dify_dify_ssrf,
  ]
  metadata {
    name      = "dify-elb"
    namespace = "dify"
    annotations = {
      "kubernetes.io/elb.class"         = "performance"
      "kubernetes.io/elb.id"            = huaweicloud_elb_loadbalancer.loadbalancer.id
      "kubernetes.io/elb.port"          = "80"
      "kubernetes.io/elb.ingress-order" = "1" // 优先级高
    }
  }
  spec {
    ingress_class_name = "cce"
    rule {
      host = ""
      http {
        path {
          path      = "/console/api"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-api"
              port {
                number = 5001
              }
            }
          }
        }
        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-api"
              port {
                number = 5001
              }
            }
          }
        }
        path {
          path      = "/v1"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-api"
              port {
                number = 5001
              }
            }
          }
        }
        path {
          path      = "/files"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-api"
              port {
                number = 5001
              }
            }
          }
        }
        path {
          path      = "/mcp"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-api"
              port {
                number = 5001
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "dify-ingress-plugin" {
  depends_on = [
    kubernetes_service.service_dify_plugin
  ]
  count = local.dify_version_legacy ? 0 : 1
  metadata {
    name      = "dify-elb-plugin"
    namespace = "dify"
    annotations = {
      "kubernetes.io/elb.class"         = "performance"
      "kubernetes.io/elb.id"            = huaweicloud_elb_loadbalancer.loadbalancer.id
      "kubernetes.io/elb.port"          = "80"
      "kubernetes.io/elb.ingress-order" = "2" // 优先级低
    }
  }
  spec {
    ingress_class_name = "cce"
    rule {
      host = ""
      http {
        path {
          path      = "/e/"
          path_type = "Prefix"
          backend {
            service {
              name = "dify-plugin-daemon"
              port {
                number = 5002
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "dify-ingress-web" {
  depends_on = [
    kubernetes_service.service_dify_dify_web
  ]
  metadata {
    name      = "dify-elb-web"
    namespace = "dify"
    annotations = {
      "kubernetes.io/elb.class"         = "performance"
      "kubernetes.io/elb.id"            = huaweicloud_elb_loadbalancer.loadbalancer.id
      "kubernetes.io/elb.port"          = "80"
      "kubernetes.io/elb.ingress-order" = "3" // 优先级低
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
              name = "dify-web"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}

output "说明" {
  depends_on = [huaweicloud_elb_loadbalancer.loadbalancer]
  value      = "资源部署完毕后，请在浏览器上输入网址：http://${huaweicloud_vpc_eip.eips[0].address}/，即可访问高可用Dify-LLM应用开发平台。"
}
