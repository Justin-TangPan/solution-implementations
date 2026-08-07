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
  type        = string
  default     = "cognee"
  nullable    = false
  description = "资源名称前缀：4-24 位小写字母、数字或连字符，且以字母开头。"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,22}[a-z0-9]$", var.solution_name))
    error_message = "solution_name 必须为 4-24 位小写字母、数字或连字符，且以字母开头、以字母或数字结尾。"
  }
}

variable "ecs_flavor" {
  type        = string
  default     = "x1.4u.8g"
  nullable    = false
  description = "ECS 规格，默认 x1.4u.8g（4 vCPU、8 GiB）。"
  validation {
    condition     = can(regex("^x1\\.([1-9]|1[0-6])u\\.([1-9][0-9]{0,1}|1[0-2][0-8])g$", var.ecs_flavor))
    error_message = "ecs_flavor 必须为可用的 x1.<vCPU>u.<内存>g 格式，例如 x1.4u.8g。"
  }
}

variable "ecs_password" {
  type        = string
  default     = ""
  sensitive   = true
  nullable    = false
  description = "ECS root 密码，8-26 位，至少包含大写、小写、数字和特殊字符中的三类。"
  validation {
    condition     = can(regex("^(?=.{8,26}$)(?:(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])|(?=.*[A-Z])(?=.*[a-z])(?=.*[^A-Za-z0-9])|(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9])|(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9])).*$", var.ecs_password))
    error_message = "ecs_password 必须为 8-26 位且至少包含三类字符。"
  }
}

variable "system_disk_size" {
  type        = number
  default     = 100
  nullable    = false
  description = "系统盘（SSD）容量，单位 GiB；同时承载容器、数据库卷和 Cognee 持久化目录。"
  validation {
    condition     = var.system_disk_size >= 100 && var.system_disk_size <= 1024
    error_message = "system_disk_size 必须在 100-1024 GiB 之间。"
  }
}

variable "charging_mode" {
  type        = string
  default     = "postPaid"
  nullable    = false
  description = "计费模式：postPaid（按需）或 prePaid（包年包月）。"
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "charging_mode 必须为 postPaid 或 prePaid。"
  }
}

variable "charging_unit" {
  type        = string
  default     = "month"
  nullable    = false
  description = "包年包月计费单位：month 或 year。按需计费时保持默认值即可。"
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "charging_unit 必须为 month 或 year。"
  }
}

variable "charging_period" {
  type        = number
  default     = 1
  nullable    = false
  description = "包年包月计费周期。"
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "charging_period 必须在 1-9 之间。"
  }
}

data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 24.04 server 64bit"
  most_recent = true
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

resource "huaweicloud_networking_secgroup_rule" "cloudshell_ssh" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "SSH only from Huawei CloudShell"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_networking_secgroup_rule" "vpc_api" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cognee API from this VPC only"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8000
  remote_ip_prefix  = "172.16.0.0/16"
}

resource "huaweicloud_compute_instance" "ecs" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SSD"
  system_disk_size            = var.system_disk_size
  admin_pass                  = var.ecs_password
  delete_disks_on_termination = false
  charging_mode               = var.charging_mode
  period_unit                 = var.charging_unit
  period                      = var.charging_period
  agent_list                  = "hss,ces"

  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }

  tags = {
    app = "Cognee"
  }

  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    LOG=/var/log/cognee-bootstrap.log
    exec > >(tee -a "$LOG") 2>&1

    apt-get update -y
    apt-get install -y ca-certificates curl gnupg openssl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    install -d -m 0755 /etc/docker
    cat > /etc/docker/daemon.json <<'JSON'
    {"registry-mirrors":["https://docker.wangzhou3.top"]}
    JSON
    systemctl daemon-reload
    systemctl restart docker
    docker info --format '{{json .RegistryConfig.Mirrors}}' | grep -Fx '["https://docker.wangzhou3.top"]'

    COGNEE_DIR=/opt/cognee
    install -d -m 0750 "$COGNEE_DIR" /var/lib/cognee/data /var/lib/cognee/system /var/lib/cognee/cache /var/lib/cognee/logs
    DB_PASSWORD=$(openssl rand -hex 32)
    JWT_SECRET=$(openssl rand -hex 48)
    umask 077
    cat > "$COGNEE_DIR/.env" <<ENV
    DB_PASSWORD=$DB_PASSWORD
    FASTAPI_USERS_JWT_SECRET=$JWT_SECRET
    ENV=production
    DEBUG=false
    CORS_ALLOWED_ORIGINS=
    ENABLE_BACKEND_ACCESS_CONTROL=true
    REQUIRE_AUTHENTICATION=true
    HASH_API_KEY=true
    ACCEPT_LOCAL_FILE_PATH=false
    ALLOW_HTTP_REQUESTS=false
    ALLOW_CYPHER_QUERY=false
    DB_PROVIDER=postgres
    DB_HOST=db
    DB_PORT=5432
    DB_NAME=cognee_db
    DB_USERNAME=cognee
    GRAPH_DATABASE_PROVIDER=postgres
    VECTOR_DB_PROVIDER=pgvector
    CACHE_BACKEND=postgres
    DATA_ROOT_DIRECTORY=/var/lib/cognee/data
    SYSTEM_ROOT_DIRECTORY=/var/lib/cognee/system
    CACHE_ROOT_DIRECTORY=/var/lib/cognee/cache
    COGNEE_LOGS_DIR=/var/lib/cognee/logs
    ENV
    chmod 0600 "$COGNEE_DIR/.env"
    unset DB_PASSWORD JWT_SECRET

    cat > "$COGNEE_DIR/compose.yaml" <<'COMPOSE'
    services:
      db:
        image: pgvector/pgvector@sha256:d2ef61f42ef767baa5a1475393303cc235bcd92febd9d7014eddb48b41f3bad0
        restart: unless-stopped
        environment:
          POSTGRES_DB: cognee_db
          POSTGRES_USER: cognee
          POSTGRES_PASSWORD: $${DB_PASSWORD}
        volumes:
          - postgres_data:/var/lib/postgresql/data
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U cognee -d cognee_db"]
          interval: 5s
          timeout: 5s
          retries: 24

      cognee:
        image: cognee/cognee@sha256:d8931a59034a6c69f3cf4a81e1ba0b5ddc660691a600a7711f6278aad26bb678
        restart: unless-stopped
        ports:
          - "8000:8000"
        env_file: .env
        depends_on:
          db:
            condition: service_healthy
        volumes:
          - /var/lib/cognee/data:/var/lib/cognee/data
          - /var/lib/cognee/system:/var/lib/cognee/system
          - /var/lib/cognee/cache:/var/lib/cognee/cache
          - /var/lib/cognee/logs:/var/lib/cognee/logs
        healthcheck:
          test: ["CMD-SHELL", "curl -fsS http://localhost:8000/health >/dev/null"]
          interval: 30s
          timeout: 10s
          retries: 3
          start_period: 40s

    volumes:
      postgres_data:
        name: cognee_postgres_data
    COMPOSE

    cd "$COGNEE_DIR"
    docker compose config --quiet
    docker compose pull
    docker compose up -d
    for attempt in $(seq 1 18); do
      if docker compose exec -T cognee curl -fsS http://localhost:8000/health >/dev/null; then
        echo "Cognee health check passed"
        exit 0
      fi
      sleep 10
    done
    docker compose ps
    docker compose logs --tail=100
    exit 1
  EOT
}
