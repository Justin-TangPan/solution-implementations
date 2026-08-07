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
  default     = "jiuwenswarm"
  description = "解决方案名称，4-24个字符，仅含小写字母、数字和中划线，必须以小写字母开头并以小写字母或数字结尾。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,22}[a-z0-9]$", var.solution_name))
    error_message = "解决方案名称格式无效，示例：jiuwenswarm。"
  }
}

variable "ecs_flavor" {
  default     = "x1.4u.8g"
  description = "云服务器实例规格，请选择目标区域实际可用规格。推荐4 vCPUs、8 GiB或更高配置。"
  type        = string
  nullable    = false
  validation {
    condition     = length(regexall("^([a-z][a-z0-9]{0,3}\\.)(x|[1-9][0-9]{0,1}x)large\\.[1-9][0-9]{0,1}$|^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor)) > 0
    error_message = "Invalid input please re-enter."
  }
}

variable "ecs_password" {
  default     = ""
  description = "云服务器root密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = true
}

variable "system_disk_size" {
  default     = 100
  description = "系统盘大小（GB），高IO类型，取值范围40-1024。默认：100。"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^([4-9][0-9]|[1-9][0-9]{2}|10[01][0-9]|102[0-4]|1024)$", var.system_disk_size)) > 0
    error_message = "Invalid input. Please re-enter."
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网带宽大小，按流量计费。单位：Mbit/s，取值范围1-300。默认：300。"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^([1-9][0-9]{0,1}|[1-2][0-9]{2}|300)$", var.bandwidth_size)) > 0
    error_message = "Invalid input. Please re-enter."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "云服务器计费模式：postPaid（按需计费）或prePaid（包年包月）。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "计费模式必须为postPaid或prePaid。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期类型：month（月）或year（年），仅prePaid模式生效。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "订购周期类型必须为month或year。"
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期，按月1-9或按年1-3，仅prePaid模式生效。"
  type        = number
  nullable    = false
  validation {
    condition     = length(regexall("^[1-9]$", var.charging_period)) > 0
    error_message = "Invalid input. Please re-enter."
  }
}

data "huaweicloud_images_image" "ubuntu" {
  most_recent = true
  name        = "Ubuntu 24.04 server 64bit"
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

resource "huaweicloud_networking_secgroup_rule" "web" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "JiuwenSwarm Web界面"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 5173
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell默认端口"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "eip" {
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

resource "huaweicloud_compute_instance" "ecs" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SAS"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period

  tags = {
    app = "jiuwenswarm"
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive

    LOGFILE="/var/log/jiuwenswarm-bootstrap.log"
    exec >"$LOGFILE" 2>&1

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

    install -d -m 0750 /opt/jiuwenswarm/jiuwenswarm-data
    cat > /opt/jiuwenswarm/Dockerfile <<'DOCKERFILE'
    ARG BASE_IMAGE=python:3.11.4-slim-bookworm
    FROM $${BASE_IMAGE}

    RUN pip install --upgrade pip
    RUN pip install jiuwenswarm -i https://pypi.tuna.tsinghua.edu.cn/simple

    EXPOSE 5173

    CMD ["bash", "-c", "jiuwenswarm-init && jiuwenswarm-start"]
    DOCKERFILE

    cat > /opt/jiuwenswarm/docker-compose.yml <<'COMPOSE'
    version: "3.8"

    services:
      jiuwenswarm:
        build:
          context: .
          dockerfile: Dockerfile
        container_name: jiuwenswarm
        restart: unless-stopped
        ports:
          - "5173:5173"
        volumes:
          - ./jiuwenswarm-data:/root/.jiuwenswarm
        environment:
          - FRONTEND_HOST=0.0.0.0
        networks:
          - swarm-net

    networks:
      swarm-net:
    COMPOSE

    cd /opt/jiuwenswarm
    docker compose config --quiet
    docker compose up -d --build

    for attempt in $(seq 1 24); do
      if curl --fail --silent --show-error http://127.0.0.1:5173/ >/dev/null; then
        exit 0
      fi
      sleep 5
    done
    docker compose logs --tail=200 || true
    exit 1
  EOT
}

output "access_instructions" {
  description = "JiuwenSwarm访问说明"
  value       = "等待镜像构建和容器启动完成后访问 http://${huaweicloud_vpc_eip.eip.address}:5173，并按官方指南完成模型配置。安装日志：/var/log/jiuwenswarm-bootstrap.log；容器日志：cd /opt/jiuwenswarm && docker compose logs"
}
