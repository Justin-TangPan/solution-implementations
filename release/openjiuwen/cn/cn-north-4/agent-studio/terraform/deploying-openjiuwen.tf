terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0, < 2.0.0"
    }
  }
}

provider "huaweicloud" {
  region = "cn-north-4"
}

variable "solution_name" {
  default     = "openjiuwen"
  description = "解决方案名称，4-24个字符，支持小写字母、数字、-（中划线），必须以小写字母开头。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,23}$", var.solution_name))
    error_message = "解决方案名称格式无效，示例：openjiuwen。"
  }
}

variable "ecs_flavor" {
  default     = "x1.8u.16g"
  description = "云服务器实例规格。openJiuwen Agent Studio 将运行 MySQL、Milvus、MinIO、Etcd、前后端、插件、沙箱和 Runtime 等多个容器，推荐 x1.8u.16g 及以上。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
    error_message = "规格格式无效，示例：x1.8u.16g。"
  }
}

variable "ecs_password" {
  description = "云服务器 root 密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.ecs_password) >= 8 && length(var.ecs_password) <= 26
    error_message = "云服务器密码长度必须在8到26位之间。"
  }
}

variable "system_disk_size" {
  default     = 200
  description = "系统盘大小（GB），高IO类型，取值范围：100-1024。openJiuwen 会拉取多个容器镜像并保存运行数据，建议 200GB 起步。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 100 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须在100到1024之间。"
  }
}

variable "bandwidth_size" {
  default     = 100
  description = "弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300。首次部署需下载版本包和容器镜像，建议 100Mbit/s。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须在1到300之间。"
  }
}

variable "web_access_cidr" {
  default     = "121.36.59.153/32"
  description = "允许访问 openJiuwen Studio 前端的公网 IPv4 地址，必须使用 /32。默认仅允许 Cloud Shell 出口地址。"
  type        = string
  nullable    = false
  validation {
    condition     = can(cidrhost(var.web_access_cidr, 0)) && can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}/32$", var.web_access_cidr))
    error_message = "必须为有效的公网 IPv4 /32 CIDR，例如 203.0.113.10/32。"
  }
}

variable "frontend_port" {
  default     = 3000
  description = "openJiuwen Studio 前端公网访问端口。默认：3000。"
  type        = number
  nullable    = false
  validation {
    condition     = var.frontend_port >= 1024 && var.frontend_port <= 65535
    error_message = "前端端口必须在1024到65535之间。"
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "计费模式：postPaid（按需计费）或 prePaid（包年包月）。默认：postPaid。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "必须为 postPaid 或 prePaid。"
  }
}

variable "charging_unit" {
  default     = "month"
  description = "订购周期类型：month（月）或 year（年），仅 prePaid 模式生效。"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "必须为 month 或 year。"
  }
}

variable "charging_period" {
  default     = 1
  description = "订购周期，1-9（月）或 1-3（年），仅 prePaid 模式生效。"
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "周期必须在1到9之间。"
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
  name = "${var.solution_name}-sg"
}

resource "huaweicloud_networking_secgroup_rule" "openjiuwen_frontend" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "openJiuwen Studio 前端 HTTPS 访问"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = var.frontend_port
  remote_ip_prefix  = var.web_access_cidr
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell SSH 登录"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "eip" {
  name = "${var.solution_name}-eip"
  bandwidth {
    name        = "${var.solution_name}-bw"
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
    app = "openJiuwen"
  }

  user_data = <<-EOT
  #!/bin/bash
  set -e

  ROOT_PASSWORD="$(printf '%s' '${base64encode(var.ecs_password)}' | base64 -d)"
  printf 'root:%s\n' "$ROOT_PASSWORD" | chpasswd
  unset ROOT_PASSWORD

  LOG="/var/log/openjiuwen-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1
  echo "[$(date)] openJiuwen bootstrap: start"

  export DEBIAN_FRONTEND=noninteractive

  echo "[$(date)] 安装系统依赖..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release unzip net-tools openssl

  echo "[$(date)] 安装 Docker CE..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  DOCKER_CE_VERSION="$(apt-cache policy docker-ce | awk '/Candidate:/ {print $2}')"
  DOCKER_CLI_VERSION="$(apt-cache policy docker-ce-cli | awk '/Candidate:/ {print $2}')"
  test -n "$DOCKER_CE_VERSION" && test "$DOCKER_CE_VERSION" != "(none)"
  test -n "$DOCKER_CLI_VERSION" && test "$DOCKER_CLI_VERSION" != "(none)"
  apt-get install -y "docker-ce=$DOCKER_CE_VERSION" "docker-ce-cli=$DOCKER_CLI_VERSION" containerd.io docker-buildx-plugin docker-compose-plugin
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json << 'DOCKERDAEMON'
  {
    "registry-mirrors": ["https://docker.wangzhou3.top"]
  }
  DOCKERDAEMON
  systemctl enable docker
  systemctl restart docker
  echo "[$(date)] Docker 安装完成: $(docker --version)"

  echo "[$(date)] 下载 openJiuwen Agent Studio 官方部署工具..."
  INSTALL_DIR="/opt/openjiuwen"
  TOOL_ZIP="/opt/openjiuwen-deploytool.zip"
  TOOL_URL="https://openjiuwen-ci.obs.cn-north-4.myhuaweicloud.com/agentstudio/deployTool_0.1.5_amd64.zip"
  TOOL_SHA256="fb6df7f006660d4c1e1b6e800e83c14d6c806f84236fb46452af38ba946ff783"
  rm -rf "$INSTALL_DIR" "$TOOL_ZIP"
  mkdir -p "$INSTALL_DIR"
  curl -fL --retry 5 --retry-delay 10 -o "$TOOL_ZIP" "$TOOL_URL"
  printf '%s  %s\n' "$TOOL_SHA256" "$TOOL_ZIP" | sha256sum --check --strict -
  unzip -q "$TOOL_ZIP" -d /opt
  TOOL_DIR="/opt/deployTool_0.1.5_amd64"
  if [ ! -d "$TOOL_DIR" ]; then
    echo "[$(date)] 未找到 deployTool 解压目录"
    exit 1
  fi
  mv "$TOOL_DIR" "$INSTALL_DIR/deployTool"
  cd "$INSTALL_DIR/deployTool"
  umask 077

  SECRET_KEY="$(openssl rand -base64 32 | tr -d '\n')"
  AES_KEY="$(openssl rand -base64 32 | tr -d '\n')"

  cat > .env.custom << CUSTOMENV
  IP=${huaweicloud_vpc_eip.eip.address}
  FRONTEND_HOST_PORT=${var.frontend_port}
  BACKEND_HOST_PORT=8000
  RUNTIME_HOST_PORT=8186
  SECRET_KEY=$SECRET_KEY
  SERVER_AES_MASTER_KEY_ENV=$AES_KEY
  EMBED_API_BASE=
  EMBED_MODEL_NAME=
  EMBED_API_KEY=
  CUSTOMENV
  chmod 0600 .env.custom

  chmod +x ./*.sh

  echo "[$(date)] 启动 openJiuwen Agent Studio..."
  ./service.sh up -n || {
    echo "[$(date)] 首次启动失败，等待 30 秒后重试一次..."
    sleep 30
    ./service.sh up
  }

  echo "[$(date)] 等待前端服务就绪..."
  for i in $(seq 1 24); do
    if curl -k -fsS "https://localhost:${var.frontend_port}/" >/dev/null 2>&1; then
      echo "[$(date)] openJiuwen 前端服务已就绪"
      break
    fi
    if [ "$i" = "24" ]; then
      echo "[$(date)] 前端服务仍未就绪，请查看 $LOG 和 $INSTALL_DIR/deployTool/log-dirs"
      docker ps
      exit 1
    fi
    sleep 5
  done

  echo "[$(date)] openJiuwen bootstrap: done"
  EOT
}

output "access_info" {
  description = "openJiuwen Agent Studio 访问信息"
  value       = "openJiuwen Studio: https://${huaweicloud_vpc_eip.eip.address}:${var.frontend_port} | ECS: ${huaweicloud_vpc_eip.eip.address} | 后端和 Runtime 仅限主机本地健康检查 | 安装目录: /opt/openjiuwen/deployTool | 日志: /var/log/openjiuwen-bootstrap.log"
}

output "studio_url" {
  description = "openJiuwen Studio 访问地址"
  value       = "https://${huaweicloud_vpc_eip.eip.address}:${var.frontend_port}"
}
