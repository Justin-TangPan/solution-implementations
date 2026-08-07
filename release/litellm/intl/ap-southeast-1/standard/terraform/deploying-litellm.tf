terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-1"
}

variable "solution_name" {
  default     = "litellm-llm-gateway"
  description = "Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter."
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS flavor. Recommended c7n.2xlarge.2 (8vCPUs 16GiB). Change to match available flavors in target region."
  type        = string
  nullable    = false
}

variable "ecs_password" {
  default     = ""
  description = "ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "db_password" {
  default     = ""
  description = "PostgreSQL password, 8-26 chars. Used by LiteLLM for internal database (virtual keys, spend tracking)."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "master_key" {
  default     = ""
  description = "LiteLLM master key, must start with 'sk-'. Used for Admin UI login and API authentication."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "salt_key" {
  default     = ""
  description = "LiteLLM salt key for encrypting stored API keys. CANNOT be changed once used. Leave empty to auto-generate."
  type        = string
  sensitive   = true
  nullable    = true
}

variable "system_disk_size" {
  default     = 200
  description = "System disk size in GB (high-IO SSD). Docker images + PG data + logs. 200GB recommended for production. Range: 40-1024."
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "System disk size must be between 40 and 1024 GB."
  }
}

variable "bandwidth_size" {
  default     = 200
  description = "EIP bandwidth in Mbit/s, traffic billing. Range: 1-300. Default: 200."
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "Bandwidth must be between 1 and 300 Mbit/s."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "Billing mode: postPaid (pay-per-use) or prePaid (subscription). Default: postPaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Must be postPaid or prePaid."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "Subscription unit: month or year. Required when charging_mode is prePaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Must be month or year."
  }
}

variable "charging_period" {
  default     = 1
  description = "Subscription period: 1-9 (month) or 1-3 (year). Required when charging_mode is prePaid."
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "Period must be 1-9."
  }
}

data "huaweicloud_images_image" "Ubuntu" {
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

resource "huaweicloud_networking_secgroup_rule" "allow_ping" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Allow ping for connectivity test"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "litellm_api" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "LiteLLM Proxy API and Admin UI"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 4000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "prometheus_ui" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Prometheus monitoring dashboard"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 9090
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "SSH access via Cloud Shell"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 22
  remote_ip_prefix  = "121.36.59.153/32"
}

resource "huaweicloud_vpc_eip" "vpc_eip" {
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

resource "huaweicloud_compute_instance" "compute_instance" {
  name                        = "${var.solution_name}-ecs"
  image_id                    = data.huaweicloud_images_image.Ubuntu.id
  flavor_id                   = var.ecs_flavor
  security_group_ids          = [huaweicloud_networking_secgroup.secgroup.id]
  system_disk_type            = "SSD"
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
  tags = {
    app = "LiteLLM"
  }
  user_data = <<-EOT
  #!/bin/bash
  set -e

  echo 'root:${var.ecs_password}' | chpasswd

  LOG="/var/log/litellm-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1

  echo "[$(date)] LiteLLM bootstrap: start"

  # ---- Install Docker CE (official source) ----
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-compose-plugin
  echo "[$(date)] Docker installed: $(docker --version)"

  # ---- Prepare directory ----
  LITELLM_DIR="/opt/litellm"
  mkdir -p "$LITELLM_DIR"

  # ---- Generate .env ----
  DB_PASSWORD="${var.db_password}"
  MASTER_KEY="${var.master_key}"
  SALT_KEY="${var.salt_key}"
  [ -z "$SALT_KEY" ] && SALT_KEY="$(openssl rand -base64 32)"

  cat > "$LITELLM_DIR/.env" << ENVEOF
  POSTGRES_PASSWORD=$DB_PASSWORD
  LITELLM_MASTER_KEY=$MASTER_KEY
  LITELLM_SALT_KEY=$SALT_KEY
  DATABASE_URL=postgresql://llmproxy:$DB_PASSWORD@db:5432/litellm
  STORE_MODEL_IN_DB=True
  # Add provider API keys below, then `docker compose restart`:
  # OPENAI_API_KEY=sk-xxx
  # ANTHROPIC_API_KEY=sk-ant-xxx
  ENVEOF

  # ---- Generate config.yaml (minimal; models managed via Admin UI) ----
  cat > "$LITELLM_DIR/config.yaml" << 'CFGEOF'
  general_settings:
    master_key: os.environ/LITELLM_MASTER_KEY
    database_url: os.environ/DATABASE_URL

  litellm_settings:
    num_retries: 3
    request_timeout: 600
    drop_params: true
  CFGEOF

  # ---- Generate prometheus.yml ----
  cat > "$LITELLM_DIR/prometheus.yml" << 'PROMEOF'
  scrape_configs:
    - job_name: 'litellm'
      scrape_interval: 15s
      static_configs:
        - targets: ['litellm:4000']
  PROMEOF

  # ---- Generate docker-compose.yaml (2026 official pattern) ----
  cat > "$LITELLM_DIR/docker-compose.yaml" << 'COMPOSEEOF'
  services:
    litellm:
      image: ghcr.io/berriai/litellm:main-stable
      container_name: litellm-proxy
      restart: unless-stopped
      ports:
        - "4000:4000/tcp"
      command:
        - "--config=/app/config.yaml"
      environment:
        DATABASE_URL: "postgresql://llmproxy:$${POSTGRES_PASSWORD}@db:5432/litellm"
        STORE_MODEL_IN_DB: "True"
        LITELLM_MASTER_KEY: $${LITELLM_MASTER_KEY}
        LITELLM_SALT_KEY: $${LITELLM_SALT_KEY}
      env_file:
        - .env
      volumes:
        - ./config.yaml:/app/config.yaml:ro
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test:
          - CMD-SHELL
          - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')"
        interval: 30s
        timeout: 10s
        retries: 3
        start_period: 40s

    db:
      image: postgres:16
      container_name: litellm-db
      restart: unless-stopped
      ports:
        - "5432:5432"
      environment:
        POSTGRES_DB: litellm
        POSTGRES_USER: llmproxy
        POSTGRES_PASSWORD: $${POSTGRES_PASSWORD}
      volumes:
        - postgres_data:/var/lib/postgresql/data
      healthcheck:
        test:
          - CMD-SHELL
          - pg_isready -d litellm -U llmproxy
        interval: 5s
        timeout: 5s
        retries: 10

    prometheus:
      image: prom/prometheus:v2.53.0
      container_name: litellm-prometheus
      restart: unless-stopped
      ports:
        - "9090:9090/tcp"
      command:
        - "--config.file=/etc/prometheus/prometheus.yml"
        - "--storage.tsdb.path=/prometheus"
        - "--storage.tsdb.retention.time=15d"
      volumes:
        - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
        - prometheus_data:/prometheus
      depends_on:
        - litellm

  volumes:
    postgres_data:
      name: litellm_postgres_data
    prometheus_data:
      name: litellm_prometheus_data
  COMPOSEEOF

  # ---- Deploy with retry ----
  cd "$LITELLM_DIR"
  MAX_RETRIES=5
  COUNT=0
  deploy_ok=0

  echo "[$(date)] Starting docker compose pull & up..."
  until [ $COUNT -ge $MAX_RETRIES ]; do
    docker compose pull 2>&1 && docker compose up -d 2>&1 && deploy_ok=1 && break
    COUNT=$((COUNT+1))
    echo "[$(date)] Retry $COUNT/$MAX_RETRIES in 30s..."
    sleep 30
  done

  if [ $deploy_ok -eq 0 ]; then
    echo "[$(date)] FATAL: deploy failed after $MAX_RETRIES attempts"
    docker compose logs --tail=50 2>&1 || true
    exit 1
  fi

  # ---- Health check ----
  echo "[$(date)] Waiting for services..."
  sleep 15

  for i in $(seq 1 12); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" --connect-timeout 5 http://localhost:4000/health/liveliness 2>/dev/null || echo "000")
    [ "$HTTP_CODE" = "200" ] && echo "[$(date)] LiteLLM healthy (HTTP 200)" && break
    echo "[$(date)] Waiting... (attempt $i/12, HTTP $HTTP_CODE)"
    sleep 10
  done

  echo "--- Container status ---"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  echo "[$(date)] LiteLLM bootstrap: done"

  EOT
}

output "access_info" {
  description = "Deployment access information"
  value       = <<-EOT
Wait ~10 minutes for deployment to complete, then access:

Admin UI:   http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/ui
API:        http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/v1/chat/completions
Health:     http://${huaweicloud_vpc_eip.vpc_eip.address}:4000/health/liveliness

SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

First use:
  1. Login to Admin UI with master_key
  2. Go to 'Model Management' to add models and API keys
  3. Or edit config: vi /opt/litellm/config.yaml
  4. Restart: cd /opt/litellm && docker compose restart

Logs: /var/log/litellm-bootstrap.log
EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
