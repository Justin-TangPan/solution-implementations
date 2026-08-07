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
  # Region where resources are activated
  region    = "ap-southeast-1"
  endpoints = {
      bss   = "bss-intl.myhuaweicloud.com"
  }
}

provider "kubernetes" {
  host                   = huaweicloud_cce_cluster.cluster.certificate_clusters.1.server
  client_certificate     = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_certificate_data)
  client_key             = base64decode(huaweicloud_cce_cluster.cluster.certificate_users.0.client_key_data)
  cluster_ca_certificate = base64decode(huaweicloud_cce_cluster.cluster.certificate_clusters.0.certificate_authority_data)
}


variable "resource_name_prefix" {
  default     = "ha-new-api"
  description = "Resource name prefix naming rule: {resource_name_prefix}-English resource name. For example: CCE cluster name is {resource_name_prefix}-cce. Value range: 4-24 characters, supports lowercase letters, numbers, and - (hyphen). Must start with a lowercase letter. Cannot start with a hyphen (-).Default: ha-new-api"
  type        = string
  nullable    = false
  validation {
    condition     = length(regexall("^[a-z][a-z0-9-]{3,23}$", var.resource_name_prefix)) > 0
    error_message = "Value range: 4-24 characters, supports lowercase letters, numbers, and - (hyphen). Must start with a lowercase letter."
  }
}

variable "cce_cluster_flavor" {
  default     = "cce.s2.small"
  description = "CCE Turbo cluster specifications. The specification cannot be changed after the cluster is created. Optional values: cce.s2.small, cce.s2.medium, cce.s2.large, cce.s2.xlarge. For specific specifications, please refer to the deployment guide configuration.Default: cce.s2.small (small-scale multi-control node CCE cluster, maximum 50 nodes)."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["cce.s2.small", "cce.s2.medium", "cce.s2.large", "cce.s2.xlarge"], var.cce_cluster_flavor)
    error_message = "Invalid input please re-enter."
  }
}

variable "cce_node_pool_password" {
  default     = ""
  description = "CCE cluster node password, used for cluster node login. Valid range: 8-24 characters. The password must contain at least one uppercase letter, one lowercase letter, and include either a digit or a special character (~!@#$^*-=_,?)."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "cce_node_pool_flavor" {
  default     = "x1.8u.16g"
  description = "CCE cluster node cloud server instance specifications support Elastic Cloud Server (ECS) and Huawei Cloud Flexus Cloud Server X instances. The naming convention for Flexus Cloud Server X instance specification IDs is x1.?u.?g. For example, the specification ID for 2vCPUs4GiB is x1.2u.4g. Please use specifications of 3vCPUs6GiB or above. For specific Huawei Cloud Flexus Cloud Server X instance specifications, refer to the X instance console configuration. For Elastic Cloud Server (ECS) specifications, refer to the ECS console configuration.Default: x1.8u.16g."
  type        = string
  nullable    = false
}

variable "cce_node_pool_count" {
  default     = 3
  description = "The initial number of nodes in the CCE node pool, with a maximum of 10.Default: 3."
  type        = number
  nullable    = false
}


variable "rds_flavor" {
  default     = "rds.mysql.n1.xlarge.2.ha"
  description = "Cloud Database RDS for MySQL instance specification. This solution creates a primary/standby edition by default.Default: rds.mysql.n1.xlarge.2.ha（4U8G）.For other specifications, please refer to the deployment guide for configuration."
  type        = string
  nullable    = false
}

variable "mysql_password" {
  default     = ""
  description = "The administrator password for the MySQL database must be 8-24 characters long, including at least one uppercase letter, one lowercase letter, and one number or special character (~!^*-=_+,)."
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.mysql_password)) > 0
    error_message = "Value range: 8-24 characters. The password must include at least one uppercase letter, one lowercase letter, and either a number or a special character（~!^*-=_+,）."
  }
}

variable "mysql_user_password" {
  default     = ""
  description = "The password for the database user of the MySQL database must be 8-24 characters long, including at least one uppercase letter, one lowercase letter, and one number or special character (~!^*-=_+,). It cannot be identical to the username or the reverse of the username."
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.mysql_user_password)) > 0
    error_message = "Value range: 8-24 characters. The password must include at least one uppercase letter, one lowercase letter, and either a number or a special character（~!^*-=_+,）."
  }
}

variable "redis_capacity" {
  default     = 1
  description = "Distributed Cache Service Redis Edition instance specifications. Available options: 1GB-64GB.Default: 1GB"
  type        = number
  nullable    = false
  validation {
    condition     = contains([1, 2, 4, 8, 16, 32, 64], var.redis_capacity)
    error_message = "Invalid input please re-enter."
  }
}

variable "redis_password" {
  default     = ""
  description = "Redis database password. Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.redis_password)) > 0
    error_message = "Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  }
}

variable "session_secret" {
  default     = ""
  description = "Session key for the New API management backend. Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.session_secret)) > 0
    error_message = "Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  }
}

variable "crypto_secret" {
  default     = ""
  description = "Encryption key used for encrypting large model API keys. Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  nullable    = false
  type        = string
  sensitive   = true
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.crypto_secret)) > 0
    error_message = "Valid range: 8-24 characters. The password must contain at least uppercase letters, lowercase letters, and include numbers or special characters (~!^*-=_+,)."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "Billing mode, default automatic deduction. Valid values:postPaid (pay-as-you-go), prePaid (yearly/monthly). Default: postPaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Invalid input please re-enter."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "Order period type. This parameter is mandatory when charging_mode is prePaid. Valid values: month (monthly) or year (yearly).Default: month."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Invalid input please re-enter."
  }
}

variable "charging_period" {
  default     = 1
  description = "Billing period. This parameter is mandatory when charging_mode is prePaid. Valid values: 1-3 (year) or 1-9 (month).Default: 1 month."
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

data "huaweicloud_cce_nodes" "node" {
  depends_on = [huaweicloud_cce_node_pool.node_pool]
  cluster_id = huaweicloud_cce_cluster.cluster.id
}

data "huaweicloud_rds_flavors" "flavor_rds" {
  db_type       = "MySQL"
  db_version    = "8.0"
  instance_mode = "ha"

}

data "huaweicloud_elb_availability_zones" "az" {}

data "huaweicloud_elb_flavors" "flavors" {
  name = "L7_flavor.elb.pro.max"
}

locals {
  dcs_az        = sort(data.huaweicloud_dcs_flavors.flavors.flavors[0].available_zones)

  matched_flavor = [
    for f in data.huaweicloud_rds_flavors.flavor_rds.flavors :
    f if f.name == var.rds_flavor
  ]

  rds_az_raw = length(local.matched_flavor) > 0 ? local.matched_flavor[0].availability_zones : data.huaweicloud_availability_zones.availability_zones.names

  rds_az = length(local.rds_az_raw) >= 2 ? local.rds_az_raw : concat(local.rds_az_raw, local.rds_az_raw)


  elb_az = [
    for az in data.huaweicloud_elb_availability_zones.az.availability_zones[0].list : az
    if az.category == 0 && contains(az.protocol, "l7")
  ]
  is_main_region = startswith("ap-southeast-3", "ap-")
  image_mapping = {
    cn-east-3 = "swr.cn-east-3.myhuaweicloud.com/sac/"
  }
  image_prefix = lookup(local.image_mapping, "ap-southeast-3", "swr.cn-east-3.myhuaweicloud.com/sac/")
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
  name       = "subnet-eni-1"
  cidr       = "192.168.202.0/24"
  gateway_ip = "192.168.202.1"
  vpc_id     = huaweicloud_vpc.vpc_server.id
}

resource "huaweicloud_networking_secgroup" "secgroup_server" {
  name = "${var.resource_name_prefix}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "allow_ips_database" {
  description       = "Allow VPC intranet access"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "192.168.0.0/16"
  security_group_id = huaweicloud_networking_secgroup.secgroup_server.id
}

# Elastic IP addresses for CCE cluster, public ELB, and NAT respectively
# The EIP for the CCE cluster is required for Terraform to access the Kubernetes API server. After all resources are created, if public access to the API server is not needed, the EIP can be released.
resource "huaweicloud_vpc_eip" "eips" {
  bandwidth {
    charge_mode = "traffic"
    name        = "${var.resource_name_prefix}-bandwidth"
    share_type  = "PER"
    size        = "300"
  }
  publicip {
    type = "5_bgp"
  }
  count = 3
}


# Public ELB, connecting to CCE.
resource "huaweicloud_elb_loadbalancer" "loadbalancer" {
  name            = "${var.resource_name_prefix}-lb"
  ipv4_subnet_id  = huaweicloud_vpc_subnet.public_subnet.ipv4_subnet_id
  backend_subnets = [huaweicloud_vpc_subnet.private_subnet.id]
  availability_zone = [
    local.elb_az[0].code,
    local.elb_az[1].code
  ]
  ipv4_eip_id   = huaweicloud_vpc_eip.eips[0].id
  l7_flavor_id  = data.huaweicloud_elb_flavors.flavors.flavors[0].id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

# NAT Gateway
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

# Provide public network access for the private subnet.
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

resource "huaweicloud_rds_instance" "rds" {
  name                = "${var.resource_name_prefix}-mysql"
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
    type     = "MySQL"
    version  = "8.0"
    password = var.mysql_password
  }
  volume {
    type = "CLOUDSSD"
    size = 100
  }

  charging_mode = var.charging_mode
}

resource "huaweicloud_rds_mysql_account" "mysql_user" {
  instance_id = huaweicloud_rds_instance.rds.id
  name        = "newapi"
  password    = var.mysql_user_password
}

resource "huaweicloud_rds_mysql_database" "mysql_database" {
  depends_on    = [huaweicloud_rds_mysql_account.mysql_user]
  instance_id   = huaweicloud_rds_instance.rds.id
  name          = "newapi"
  character_set = "utf8mb4"
}

resource "huaweicloud_rds_mysql_database_privilege" "privilege" {
  depends_on = [
    huaweicloud_rds_mysql_account.mysql_user, huaweicloud_rds_mysql_database.mysql_database
  ]
  instance_id = huaweicloud_rds_instance.rds.id
  db_name     = huaweicloud_rds_mysql_database.mysql_database.name
  users {
    name     = huaweicloud_rds_mysql_account.mysql_user.name
    readonly = false
  }
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
  ])
  tags = {
    app = "_sac_newapi_cce"
  }
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
}

# CCE node pool
resource "huaweicloud_cce_node_pool" "node_pool" {
  depends_on         = [huaweicloud_rds_mysql_database.mysql_database]
  cluster_id         = huaweicloud_cce_cluster.cluster.id
  availability_zone  = "random"
  flavor_id          = var.cce_node_pool_flavor
  initial_node_count = var.cce_node_pool_count # Nodes created in batches will be located in the same availability zone.
  max_node_count     = 10
  min_node_count     = 0
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
  auto_renew    = "false"
  period        = var.charging_period

  backup_policy {
    backup_type = "auto"
    save_days   = 3
    backup_at   = [1, 3, 5, 7]
    begin_at    = "02:00-04:00"
  }

  whitelist_enable = false
}

resource "kubernetes_namespace" "namespace_newapi" {
  metadata {
    name = "new-api"
  }
}

resource "kubernetes_config_map" "configmap_new_api_env" {
  depends_on = [kubernetes_namespace.namespace_newapi]
  data = {
    TZ                           = "Asia/Shanghai"
    SYNC_FREQUENCY               = "60"
    BATCH_UPDATE_ENABLED         = "true"
    BATCH_UPDATE_INTERVAL        = "5"
    ERROR_LOG_ENABLED            = "true"
    GLOBAL_API_RATE_LIMIT        = "1800"
    GLOBAL_WEB_RATE_LIMIT        = "600"
    CRITICAL_RATE_LIMIT          = "200"
    GLOBAL_API_RATE_LIMIT_ENABLE = "true"
    GLOBAL_WEB_RATE_LIMIT_ENABLE = "true"
    CRITICAL_RATE_LIMIT_ENABLE   = "true"
  }
  metadata {
    name      = "new-api-env"
    namespace = "new-api"
  }
}

resource "kubernetes_secret" "shared_secret" {
  depends_on = [kubernetes_namespace.namespace_newapi]
  data = {
    SQL_DSN           = "newapi:${var.mysql_user_password}@tcp(${huaweicloud_rds_instance.rds.private_ips[0]}:3306)/newapi"
    REDIS_CONN_STRING = "redis://:${var.redis_password}@${huaweicloud_dcs_instance.dcs_instance.domain_name}:6379"
    SESSION_SECRET    = var.session_secret
    CRYPTO_SECRET     = var.crypto_secret
  }
  metadata {
    name      = "new-api-secret"
    namespace = "new-api"
  }
}


resource "kubernetes_deployment" "deployment_new_api_master" {
  depends_on = [
    kubernetes_namespace.namespace_newapi,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_new_api_env
  ]
  metadata {
    name      = "new-api-master"
    namespace = "new-api"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app  = "new-api"
        type = "master"
      }
    }
    template {
      metadata {
        labels = {
          "app"  = "new-api"
          "type" = "master"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "new-api-env"
            }
          }
          env_from {
            secret_ref {
              name = "new-api-secret"
            }
          }
          image             = "${local.image_prefix}new-api:v1.0.0-rc.8"
          image_pull_policy = "IfNotPresent"
          name              = "new-api-master"
          port {
            container_port = 3000
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
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "wget -q -O - http://localhost:3000/api/status | grep -o '\"success\":\\s*true' || exit 1"]
            }
            initial_delay_seconds = 15
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "deployment_new_api_slave" {
  depends_on = [
    kubernetes_namespace.namespace_newapi,
    huaweicloud_cce_node_pool.node_pool,
    kubernetes_config_map.configmap_new_api_env
  ]
  metadata {
    name      = "new-api-slave"
    namespace = "new-api"
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app  = "new-api"
        type = "slave"
      }
    }
    template {
      metadata {
        labels = {
          "app"  = "new-api"
          "type" = "slave"
        }
      }
      spec {
        container {
          env_from {
            config_map_ref {
              name = "new-api-env"
            }
          }
          env_from {
            secret_ref {
              name = "new-api-secret"
            }
          }
          env {
            name  = "NODE_TYPE"
            value = "slave"
          }
          image             = "${local.image_prefix}new-api:v1.0.0-rc.8"
          image_pull_policy = "IfNotPresent"
          name              = "new-api-slave"
          port {
            container_port = 3000
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
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "wget -q -O - http://localhost:3000/api/status | grep -o '\"success\":\\s*true' || exit 1"]
            }
            initial_delay_seconds = 15
            timeout_seconds       = 3
            period_seconds        = 30
            success_threshold     = 1
            failure_threshold     = 3
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "service_new_api" {
  depends_on = [kubernetes_namespace.namespace_newapi]
  metadata {
    name      = "new-api"
    namespace = "new-api"
  }
  spec {
    port {
      name        = "new-api"
      port        = 3000
      protocol    = "TCP"
      target_port = 3000
    }
    selector = {
      app = "new-api"
    }
    type = "ClusterIP"
  }
}

# ELB Ingress
resource "kubernetes_ingress_v1" "ingress" {
  depends_on = [kubernetes_service.service_new_api]
  metadata {
    name      = "new-api-elb"
    namespace = "new-api"
    annotations = {
      "kubernetes.io/elb.class"                 = "performance"
      "kubernetes.io/elb.id"                    = huaweicloud_elb_loadbalancer.loadbalancer.id
      "kubernetes.io/elb.port"                  = "80"
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
              name = "new-api"
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

output "Instruction" {
  depends_on = [huaweicloud_elb_loadbalancer.loadbalancer]
  value      = "After the resource deployment is complete, please enter the URL http://${huaweicloud_vpc_eip.eips[0].address}/ in your browser, and you can access the New API platform."
}
