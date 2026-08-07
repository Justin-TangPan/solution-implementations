terraform {
  required_providers {
    huaweicloud = {
      source  = "huawei.com/provider/huaweicloud"
      version = ">= 1.20.0"
    }
  }
}

provider "huaweicloud" {
  region = "ap-southeast-2"
}

variable "solution_name" {
  default     = "mem0-memory-layer"
  description = "Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter."
  type        = string
  nullable    = false
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS flavor. Recommended c7n.2xlarge.2 (8vCPUs 16GiB) for Mem0 API + PostgreSQL/pgvector + Dashboard."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^c7n\\.([1-9]|1[0-6])xlarge\\.([2-9]|1[0-6])$", var.ecs_flavor))
    error_message = "Invalid ECS flavor format. Example: c7n.2xlarge.2"
  }
}

variable "ecs_password" {
  default     = ""
  description = "ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "openai_api_key" {
  default     = ""
  description = "OpenAI API key for Mem0 default LLM (gpt-5-mini) and embedder (text-embedding-3-small). After deployment, you can switch to Anthropic or Gemini in the Dashboard."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "system_disk_size" {
  default     = 100
  description = "System disk size in GB (general-purpose SSD). Docker images + PostgreSQL data + logs. 100GB recommended. Range: 40-1024."
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

resource "huaweicloud_networking_secgroup_rule" "mem0_api" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Mem0 API (REST + Swagger UI)"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8888
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "mem0_dashboard" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Mem0 Dashboard Web UI"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 3000
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
  tags = {
    app = "Mem0"
  }
  user_data = <<-EOT
  #!/bin/bash
  set -e

  echo 'root:${var.ecs_password}' | chpasswd

  LOG="/var/log/mem0-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1

  echo "[$(date)] Mem0 bootstrap: start"

  # ---- Install Docker CE (official source) ----
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-compose-plugin git
  echo "[$(date)] Docker installed: $(docker --version)"

  # ---- Clone mem0 upstream repository ----
  MEM0_DIR="/opt/mem0"
  mkdir -p "$MEM0_DIR"
  cd "$MEM0_DIR"

  echo "[$(date)] Cloning mem0 repository..."
  git clone --depth 1 https://github.com/mem0ai/mem0.git src
  cd src/server

  # ---- Generate .env ----
  POSTGRES_PASSWORD="$(openssl rand -base64 32)"
  JWT_SECRET="$(openssl rand -base64 32)"

  cat > "$MEM0_DIR/.env" << ENVEOF
  OPENAI_API_KEY=${var.openai_api_key}
  POSTGRES_HOST=postgres
  POSTGRES_PORT=5432
  POSTGRES_DB=postgres
  POSTGRES_USER=postgres
  POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
  POSTGRES_COLLECTION_NAME=memories

  JWT_SECRET=${JWT_SECRET}
  AUTH_DISABLED=false
  DASHBOARD_URL=http://localhost:3000
  APP_DB_NAME=mem0_app

  MEM0_DEFAULT_LLM_MODEL=gpt-5-mini
  MEM0_DEFAULT_EMBEDDER_MODEL=text-embedding-3-small

  MEM0_TELEMETRY=false
  ENVEOF

  chmod 0600 "$MEM0_DIR/.env"

  # ---- Write init-db.sh ----
  cat > "$MEM0_DIR/init-db.sh" << 'DBEOF'
  #!/bin/bash
  set -e
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
      SELECT 'CREATE DATABASE mem0_app'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mem0_app')\gexec
  EOSQL
  DBEOF

  # ---- Build Docker images ----
  echo "[$(date)] Building Mem0 API image..."
  docker build -t mem0-server:latest -f Dockerfile .

  echo "[$(date)] Building Mem0 Dashboard image..."
  docker build -t mem0-dashboard:latest ./dashboard

  # ---- Write docker-compose.yaml ----
  cat > "$MEM0_DIR/docker-compose.yaml" << 'COMPOSEEOF'
  services:
    mem0:
      image: mem0-server:latest
      container_name: mem0-api
      restart: unless-stopped
      ports:
        - "8888:8000/tcp"
      env_file:
        - .env
      depends_on:
        postgres:
          condition: service_healthy
      command: >
        sh -c "alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port 8000"
      environment:
        - PYTHONDONTWRITEBYTECODE=1
        - PYTHONUNBUFFERED=1
        - DASHBOARD_URL=http://localhost:3000
        - APP_DB_NAME=mem0_app
        - JWT_SECRET=${JWT_SECRET}
        - AUTH_DISABLED=false
        - MEM0_TELEMETRY=false
      volumes:
        - mem0_history:/app/history
      healthcheck:
        test: ["CMD-SHELL", "curl -fsS http://localhost:8000/auth/setup-status || exit 1"]
        interval: 15s
        timeout: 5s
        retries: 5
        start_period: 30s

    postgres:
      image: pgvector/pgvector:pg17
      container_name: mem0-db
      restart: on-failure
      shm_size: "128mb"
      environment:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -q -d postgres -U postgres"]
        interval: 5s
        timeout: 5s
        retries: 5
      volumes:
        - postgres_db:/var/lib/postgresql/data
        - ./init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
      ports:
        - "127.0.0.1:5432:5432"

    mem0-dashboard:
      image: mem0-dashboard:latest
      container_name: mem0-ui
      restart: unless-stopped
      ports:
        - "3000:3000/tcp"
      environment:
        - NEXT_PUBLIC_API_URL=http://localhost:8888
        - API_INTERNAL_URL=http://mem0:8000
        - NEXT_PUBLIC_INSTANCE_NAME=Mem0
      depends_on:
        mem0:
          condition: service_started
      healthcheck:
        test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/api/health"]
        interval: 10s
        timeout: 5s
        retries: 3

  volumes:
    postgres_db:
      name: mem0_postgres_data
    mem0_history:
      name: mem0_history_data
  COMPOSEEOF

  # ---- Make init-db.sh executable ----
  chmod +x "$MEM0_DIR/init-db.sh"

  # ---- Deploy with retry ----
  cd "$MEM0_DIR"
  MAX_RETRIES=5
  COUNT=0
  deploy_ok=0

  echo "[$(date)] Starting docker compose up..."
  until [ $COUNT -ge $MAX_RETRIES ]; do
    docker compose up -d 2>&1 && deploy_ok=1 && break
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
  echo "[$(date)] Waiting for Mem0 API..."
  for i in $(seq 1 12); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8000/auth/setup-status 2>/dev/null || echo "000")
    [ "$HTTP_CODE" = "200" ] && echo "[$(date)] Mem0 API healthy (HTTP 200)" && break
    echo "[$(date)] Waiting... (attempt $i/12, HTTP $HTTP_CODE)"
    sleep 10
  done

  # ---- Bootstrap: create admin and API key ----
  echo "[$(date)] Running Mem0 seed setup..."
  cd "$MEM0_DIR/src/server"

  ADMIN_EMAIL="admin@mem0.local"
  ADMIN_PASSWORD="$(openssl rand -base64 16)"
  ADMIN_NAME="Admin"

  REGISTER_RESP=$(curl -s -X POST http://localhost:8000/auth/register \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"${ADMIN_NAME}\", \"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  LOGIN_RESP=$(curl -s -X POST http://localhost:8000/auth/login \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  TOKEN=$(echo "${LOGIN_RESP}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || echo "")

  if [ -n "$TOKEN" ]; then
    KEY_RESP=$(curl -s -X POST http://localhost:8000/api-keys \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -d '{"label": "default-key"}')

    API_KEY=$(echo "${KEY_RESP}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('key',''))" 2>/dev/null || echo "")

    echo ""
    echo "=== Mem0 Admin Credentials ==="
    echo "Dashboard:  http://<EIP>:3000"
    echo "API:        http://<EIP>:8888"
    echo "Admin Email: ${ADMIN_EMAIL}"
    echo "Admin Password: ${ADMIN_PASSWORD}"
    if [ -n "$API_KEY" ]; then
      echo "API Key:    ${API_KEY}"
    fi
    echo ""
    echo "Save these credentials securely. They will not be shown again."
    echo ""
  else
    echo "[$(date)] Warning: Seed setup failed. Manual setup required via Dashboard."
    echo "Register response: ${REGISTER_RESP}"
  fi

  echo "--- Container status ---"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  echo "[$(date)] Mem0 bootstrap: done"
  EOT
}

output "access_info" {
  description = "Mem0 deployment access information"
  value       = <<-EOT
Wait ~10 minutes for deployment to complete, then access:

API:        http://${huaweicloud_vpc_eip.vpc_eip.address}:8888
API Docs:   http://${huaweicloud_vpc_eip.vpc_eip.address}:8888/docs
Dashboard:  http://${huaweicloud_vpc_eip.vpc_eip.address}:3000

SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address}

First use:
  1. Open Dashboard at http://<EIP>:3000
  2. Log in with admin credentials (saved in /var/log/mem0-bootstrap.log)
  3. Configure LLM provider (OpenAI/Anthropic/Gemini) in Dashboard Settings
  4. Test with: curl -X POST http://<EIP>:8888/memories \\
       -H 'X-API-Key: <api-key>' \\
       -H 'Content-Type: application/json' \\
       -d '{"messages": [{"role": "user", "content": "I like hiking"}], "user_id": "test-user"}'

Manage: /opt/mem0/.env
Logs: /var/log/mem0-bootstrap.log
EOT
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
