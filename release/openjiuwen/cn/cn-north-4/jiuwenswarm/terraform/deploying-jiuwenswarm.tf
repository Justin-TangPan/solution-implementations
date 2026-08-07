terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
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
}

variable "ecs_password" {
  description = "云服务器root密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition = (
      length(var.ecs_password) >= 8 &&
      length(var.ecs_password) <= 26 &&
      (
        (can(regex("[A-Z]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[a-z]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[0-9]", var.ecs_password)) ? 1 : 0) +
        (can(regex("[^A-Za-z0-9]", var.ecs_password)) ? 1 : 0)
      ) >= 3
    )
    error_message = "云服务器密码必须为8到26位，并至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  }
}

variable "system_disk_size" {
  default     = 80
  description = "系统盘大小（GB），高IO类型，取值范围40-1024。默认：80。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须在40到1024之间。"
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网带宽大小，按流量计费。单位：Mbit/s，取值范围1-300。默认：300。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须在1到300之间。"
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
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "购买周期必须为1到9；按年购买时请填写1到3。"
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

    apt-get update -y
    apt-get install -y ca-certificates curl python3-venv

    useradd --system --home-dir /var/lib/jiuwenswarm --create-home --shell /usr/sbin/nologin jiuwenswarm
    install -d -o root -g root -m 0755 /opt/jiuwenswarm
    install -d -o jiuwenswarm -g jiuwenswarm -m 0750 /var/lib/jiuwenswarm
    python3 -m venv /opt/jiuwenswarm/venv
    /opt/jiuwenswarm/venv/bin/python -m pip install --upgrade pip \
      -i https://pypi.tuna.tsinghua.edu.cn/simple
    /opt/jiuwenswarm/venv/bin/python -m pip install 'jiuwenswarm==0.2.2' \
      -i https://pypi.tuna.tsinghua.edu.cn/simple
    chown -R root:root /opt/jiuwenswarm
    chown -R jiuwenswarm:jiuwenswarm /var/lib/jiuwenswarm

    runuser -u jiuwenswarm -- env \
      HOME=/var/lib/jiuwenswarm \
      USER=jiuwenswarm \
      JIUWENSWARM_DATA_DIR=/var/lib/jiuwenswarm \
      /opt/jiuwenswarm/venv/bin/jiuwenswarm-init </dev/null

    cat > /etc/systemd/system/jiuwenswarm.service <<'SERVICE'
    [Unit]
    Description=JiuwenSwarm
    Wants=network-online.target
    After=network-online.target

    [Service]
    Type=simple
    User=jiuwenswarm
    Group=jiuwenswarm
    Environment=HOME=/var/lib/jiuwenswarm
    Environment=USER=jiuwenswarm
    Environment=JIUWENSWARM_DATA_DIR=/var/lib/jiuwenswarm
    Environment=FRONTEND_HOST=0.0.0.0
    ExecStart=/opt/jiuwenswarm/venv/bin/jiuwenswarm-start
    Restart=on-failure
    RestartSec=5
    NoNewPrivileges=true
    PrivateTmp=true
    ProtectSystem=strict
    ProtectHome=true
    UMask=0077
    ReadWritePaths=/var/lib/jiuwenswarm

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now jiuwenswarm.service

    for attempt in $(seq 1 24); do
      if curl --fail --silent --show-error http://127.0.0.1:5173/ >/dev/null; then
        exit 0
      fi
      sleep 5
    done
    systemctl status jiuwenswarm.service --no-pager || true
    exit 1
  EOT
}

output "jiuwenswarm_url" {
  description = "JiuwenSwarm Web访问地址"
  value       = "http://${huaweicloud_vpc_eip.eip.address}:5173"
}

output "ecs_public_ip" {
  description = "云服务器公网IP"
  value       = huaweicloud_vpc_eip.eip.address
}
