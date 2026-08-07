terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">=1.67.1"
    }
  }
}

provider "huaweicloud" {
  region = "cn-north-4"
}

variable "solution_name" {
  default     = "astrbot"
  description = "解决方案名称，取值范围：4-24个字符，支持小写字母、数字、-（中划线）。必须以小写字母开头。禁止以中划线（-）开头。默认：astrbot"
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "x1.4u.8g"
  description = "云服务器实例规格，支持弹性云服务器 ECS及华为云Flexus 云服务器X实例。默认：x1.4u.8g。"
  type        = string
  nullable    = false
  validation {
    condition     = length(regexall("^([a-z][a-z0-9]{0,3}\\.)(x|[1-9][0-9]{0,1}x)large\\.[1-9][0-9]{0,1}$|^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor)) > 0
    error_message = "Invalid input please re-enter."
  }
}

variable "ecs_password" {
  default     = ""
  description = "云服务器密码，长度为8-26位，密码至少包含大写字母、小写字母、数字和特殊字符（!@$%^-_=+[{}]:,./?）中的三种。管理员账户默认root。"
  nullable    = true
  type        = string
  sensitive   = true
}

variable "system_disk_size" {
  default     = 100
  description = "云服务器系统盘大小，磁盘类型默认为高IO，单位：GB，取值范围为40-1,024，不支持缩盘。默认：100"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^([4-9][0-9]|[1-9][0-9]{2}|10[01][0-9]|102[0-4]|1024)$", var.system_disk_size)) > 0
    error_message = "Invalid input. Please re-enter."
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网带宽大小，该模板计费方式为按流量计费。单位：Mbit/s，取值范围：1-300Mbit/s。默认：300。"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^([1-9][0-9]{0,1}|[1-2][0-9]{2}|300)$", var.bandwidth_size)) > 0
    error_message = "Invalid input. Please re-enter."
  }
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

data "huaweicloud_images_image" "Ubuntu" {
  most_recent = true
  name        = "Ubuntu 22.04 server 64bit"
  visibility  = "public"
}

resource "huaweicloud_vpc" "vpc" {
  name = "${var.solution_name}-vpc"
  cidr = "172.16.0.0/16"
}

resource "huaweicloud_vpc_subnet" "subnet" {
  name       = "${var.solution_name}-subnet"
  cidr       = "172.16.1.0/24"
  gateway_ip = "172.16.1.1"
  vpc_id     = huaweicloud_vpc.vpc.id
}

resource "huaweicloud_networking_secgroup" "secgroup" {
  name = "${var.solution_name}-secgroup"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell默认端口，通过Cloud Shell登录服务器"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_networking_secgroup_rule" "astrbot_webui" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "AstrBot WebUI公网访问端口"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 6185
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bandwidth"
    share_type  = "PER"
    size        = var.bandwidth_size
    charge_mode = "traffic"
  }
  publicip {
    type = "5_bgp"
  }
  charging_mode = "postPaid"
}

resource "huaweicloud_compute_instance" "compute_instance" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.Ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SAS"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = false
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  tags = {
    app = "astrbot"
  }
  user_data = <<-USER_DATA
    #!/bin/bash
    set -eu
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod 0644 /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    install -d -m 0755 /etc/docker
    cat > /etc/docker/daemon.json <<'JSON'
    {"registry-mirrors":["https://docker.wangzhou3.top"]}
    JSON
    systemctl enable --now docker
    systemctl restart docker
    install -d -m 0750 /opt/astrbot /opt/astrbot/data
    cat > /opt/astrbot/compose.yaml <<'COMPOSE'
    services:
      astrbot:
        image: soulter/astrbot:v4.26.7
        container_name: astrbot
        restart: always
        security_opt:
          - no-new-privileges:true
        ports:
          - "6185:6185"
        environment:
          - TZ=Asia/Shanghai
        volumes:
          - /opt/astrbot/data:/AstrBot/data
          - /etc/localtime:/etc/localtime:ro
    COMPOSE
    cd /opt/astrbot
    docker compose config --quiet
    docker compose pull
    docker compose up -d
  USER_DATA
}

output "access_instructions" {
  description = "AstrBot使用说明"
  value       = "访问 http://${huaweicloud_vpc_eip.vpc_eip.address}:6185；首次登录密码请查看 ECS 的 Docker logs，并立即修改。"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
