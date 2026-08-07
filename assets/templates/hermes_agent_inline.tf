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
  default     = "deploying-hermes-agent-demo-sg"
  description = "解决方案名称，取值范围：4-24个字符，支持小写字母、数字、-（中划线）。必须以小写字母开头。禁止以中划线（-）开头。默认：deploying-hermes-agent-demo-sg"
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "x1.2u.4g"
  description = "云服务器实例规格，支持弹性云服务器 ECS及华为云Flexus 云服务器X实例。Flexus 云服务器X实例规格ID命名规则为x1.?u.?g，例如2vCPUs4GiB规格ID为x1.2u.4g，具体华为云Flexus 云服务器X实例规格请参考控制台。弹性云服务器 ECS规格请参考部署指南配置。默认：x1.2u.4g。"
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
  description = "云服务器系统盘大小，磁盘类型默认为通用型SSD，单位：GB，取值范围为40-1,024，不支持缩盘。默认：100"
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

resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "允许ping程序测试Flexus云服务器X实例的连通性"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell默认端口，通过CLoud shell登录服务器"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
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
  system_disk_type            = "GPSSD"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = true
  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }
  agent_list    = "hss,ces"
  eip_id        = huaweicloud_vpc_eip.vpc_eip.id
  charging_mode = var.charging_mode
  period_unit   = var.charging_unit
  period        = var.charging_period
  tags          = {
    app = "_sac_hermesagent"
  }
  user_data = <<-USER_DATA
    #!/bin/bash

    LOGFILE="/var/HermesAgent-install.log"
    exec 1>"$LOGFILE" 2>&1

    echo "开始部署 Hermes Agent..."
    sleep 10

    # 安装 Docker CE 与 Docker Compose 插件
    curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | apt-key add -
    echo "" | add-apt-repository "deb [arch=amd64] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
    echo "y" | apt-get -qq update
    sleep 10
    echo "y" | apt-get -qq install docker-ce docker-compose-plugin

    # docker.wangzhou3.top 是镜像中转站，不写入 registry-mirrors。
    # 通过镜像名前缀，经中转站直接拉取官方 nousresearch/hermes-agent 镜像。
    mkdir -p /root/hermes-agent
    cd /root/hermes-agent

    cat > docker-compose.yaml <<'COMPOSE_EOF'
    services:
      hermes:
        image: docker.wangzhou3.top/nousresearch/hermes-agent:v2026.5.7
        container_name: hermes
        restart: unless-stopped
        command: gateway run
        ports:
          - "8642:8642"
          - "9119:9119"
        volumes:
          - /root/.hermes:/opt/data
        environment:
          - HERMES_DASHBOARD=1
        # - ANTHROPIC_API_KEY=$${ANTHROPIC_API_KEY}
        # - OPENAI_API_KEY=$${OPENAI_API_KEY}
        # - TELEGRAM_BOT_TOKEN=$${TELEGRAM_BOT_TOKEN}
        deploy:
          resources:
            limits:
              memory: 4G
              cpus: "2.0"
    COMPOSE_EOF

    MAX_RETRIES=5      # 最大重试次数
    SLEEP_INTERVAL=30  # 失败后等待时间（秒）
    COUNT=0            # 当前尝试次数
    image_pulled=0

    echo "开始执行 docker compose up -d..."

    until [ "$COUNT" -ge "$MAX_RETRIES" ]; do
      if docker compose up --quiet-pull -d; then
        image_pulled=1
        break
      fi

      COUNT=$((COUNT + 1))
      echo "执行失败 (尝试次数: $COUNT/$MAX_RETRIES)，将在 $${SLEEP_INTERVAL}s 后重试..."
      sleep "$SLEEP_INTERVAL"
    done

    if [ "$image_pulled" -eq 0 ]; then
      echo "Hermes Agent 镜像拉取或容器启动失败。"
      exit 1
    fi

    echo "Hermes Agent 部署完成。"
  USER_DATA
}

output "access_instructions" {
  description = "hermes使用说明"
  value       = "等待应用下载及部署完毕（约15分钟）后， 请参考文档https://support.huaweicloud.com/hermes-aislt/hermes_06.html配置模型,更多使用教程请参考部署指南开始使用章节。"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
