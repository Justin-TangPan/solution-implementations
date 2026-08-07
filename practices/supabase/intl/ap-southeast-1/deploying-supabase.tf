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
  default     = "supabase"
  description = "Solution name, 4-24 characters. Use lowercase letters, digits, and hyphens; start with a lowercase letter and end with a lowercase letter or digit."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,22}[a-z0-9]$", var.solution_name))
    error_message = "Solution name must be 4-24 characters, start with a lowercase letter, end with a lowercase letter or digit, and contain only lowercase letters, digits, or hyphens."
  }
}

variable "ecs_flavor" {
  default     = "c7n.2xlarge.2"
  description = "ECS flavor. Supabase runs multiple Docker containers; c7n.2xlarge.2 (8 vCPUs, 16 GiB) or above is recommended."
  type        = string
  nullable    = false
}

variable "ecs_password" {
  default     = ""
  description = "ECS root password, 8-26 characters, containing at least three of uppercase letters, lowercase letters, digits, and special characters."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "db_password" {
  description = "PostgreSQL password, 8-24 characters, using letters, digits, and ~!^*-=_+,. The @ character is not supported."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.db_password)) > 0
    error_message = "PostgreSQL password must be 8-24 characters using letters, digits, and ~!^*-=_+,. The @ character is not supported."
  }
}

variable "system_disk_size" {
  default     = 100
  description = "General Purpose SSD system disk size in GiB. Range: 40-1024. A minimum of 100 GiB is recommended for Docker images and database data."
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "System disk size must be between 40 and 1024 GiB."
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "EIP bandwidth in Mbit/s, billed by traffic. Range: 1-300."
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "Bandwidth must be between 1 and 300 Mbit/s."
  }
}

variable "charging_mode" {
  default     = "postPaid"
  description = "Billing mode: postPaid (pay-per-use) or prePaid (subscription)."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["postPaid", "prePaid"], var.charging_mode)
    error_message = "Charging mode must be postPaid or prePaid."
  }
}

variable "charging_unit" {
  default     = "month"
  description = "Subscription unit: month or year. Used when charging_mode is prePaid."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["month", "year"], var.charging_unit)
    error_message = "Charging unit must be month or year."
  }
}

variable "charging_period" {
  default     = 1
  description = "Subscription period: 1-9 for month or 1-3 for year. Used when charging_mode is prePaid."
  type        = number
  nullable    = false
  validation {
    condition     = var.charging_period >= 1 && var.charging_period <= 9
    error_message = "Charging period must be between 1 and 9; enter 1 to 3 when charging_unit is year."
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
  description       = "Allow ICMP connectivity tests"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "supabase_http" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Supabase Dashboard and API gateway"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "SSH access from Huawei Cloud Shell"
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
    app = "Supabase"
  }

  user_data = <<-EOT
  #!/bin/bash
  set -Eeuo pipefail
  umask 077

  ROOT_PASSWORD="$(printf '%s' '${base64encode(var.ecs_password)}' | base64 -d)"
  printf 'root:%s\n' "$ROOT_PASSWORD" | chpasswd
  unset ROOT_PASSWORD

  LOG=/var/log/supabase-bootstrap.log
  exec > >(tee -a "$LOG") 2>&1
  echo "[$(date --iso-8601=seconds)] Supabase bootstrap started"

  fail() {
    echo "[FATAL] $*" >&2
    exit 1
  }

  # ---- Stage 1: install Docker CE and required tools from official sources ----
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg git jq openssl nodejs
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  chmod 0644 /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  ARCH=$(dpkg --print-architecture)
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' "$ARCH" "$VERSION_CODENAME" > /etc/apt/sources.list.d/docker.list
  chmod 0644 /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker

  # ---- Stage 2: copy the complete official docker directory at the pinned commit ----
  SUPABASE_REPOSITORY=https://github.com/supabase/supabase.git
  SUPABASE_COMMIT=949a57d2854b7fcadc0d621cb7fffa167506d581
  SUPABASE_DIR=/opt/supabase
  SOURCE_DIR=$(mktemp -d /tmp/supabase-source.XXXXXX)
  trap 'rm -rf "$SOURCE_DIR"' EXIT

  git -C "$SOURCE_DIR" init -q
  git -C "$SOURCE_DIR" remote add origin "$SUPABASE_REPOSITORY"
  git -C "$SOURCE_DIR" config remote.origin.promisor true
  git -C "$SOURCE_DIR" config remote.origin.partialclonefilter blob:none
  git -C "$SOURCE_DIR" sparse-checkout init --cone
  git -C "$SOURCE_DIR" sparse-checkout set docker
  FETCH_OK=0
  for ATTEMPT in 1 2 3 4 5; do
    if git -C "$SOURCE_DIR" fetch -q --filter=blob:none --depth 1 origin "$SUPABASE_COMMIT"; then
      FETCH_OK=1
      break
    fi
    echo "[$(date --iso-8601=seconds)] Source fetch attempt $ATTEMPT/5 failed; retrying in 15 seconds"
    sleep 15
  done
  [ "$FETCH_OK" -eq 1 ] || fail "Official source fetch failed after 5 attempts"
  git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD
  ACTUAL_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
  [ "$ACTUAL_COMMIT" = "$SUPABASE_COMMIT" ] || fail "Official source commit verification failed"
  [ "$(git -C "$SOURCE_DIR" rev-parse --is-shallow-repository)" = true ] || fail "Official source checkout is not shallow"
  [ ! -e "$SUPABASE_DIR" ] || fail "$SUPABASE_DIR already exists"
  install -d -m 0700 "$SUPABASE_DIR"
  cp -a "$SOURCE_DIR/docker/." "$SUPABASE_DIR/"
  printf '%s\n' "$ACTUAL_COMMIT" > "$SUPABASE_DIR/.supabase-commit"
  chmod 0700 "$SUPABASE_DIR"
  cd "$SUPABASE_DIR"

  # ---- Stage 3: generate all secrets with the official scripts without logging them ----
  cp .env.example .env
  chmod 0600 .env
  sh utils/generate-keys.sh --update-env >/dev/null 2>&1
  rm -f .env.old
  sh utils/add-new-auth-keys.sh --update-env >/dev/null 2>&1
  rm -f .env.old docker-compose.yml.old

  set_env() {
    KEY="$1"
    VALUE="$2"
    ESCAPED_VALUE=$(printf '%s' "$VALUE" | sed "s/'/\\\\'/g")
    TMP_ENV=$(mktemp)
    grep -v "^$KEY=" .env > "$TMP_ENV" || true
    printf "%s='%s'\n" "$KEY" "$ESCAPED_VALUE" >> "$TMP_ENV"
    mv "$TMP_ENV" .env
  }

  DB_PASSWORD_B64='${base64encode(var.db_password)}'
  DB_PASSWORD=$(printf '%s' "$DB_PASSWORD_B64" | base64 --decode)
  PUBLIC_BASE_URL=http://${huaweicloud_vpc_eip.vpc_eip.address}:8000
  set_env POSTGRES_PASSWORD "$DB_PASSWORD"
  set_env SUPABASE_PUBLIC_URL "$PUBLIC_BASE_URL"
  set_env API_EXTERNAL_URL "$PUBLIC_BASE_URL/auth/v1"
  set_env SITE_URL "$PUBLIC_BASE_URL"
  set_env POOLER_TENANT_ID '${var.solution_name}'
  set_env OPENAI_API_KEY ''
  unset DB_PASSWORD DB_PASSWORD_B64 ESCAPED_VALUE
  chmod 0600 .env

  # ---- Stage 4: assert the pinned official configuration before deployment ----
  [ "$(cat .supabase-commit)" = "$SUPABASE_COMMIT" ] || fail "Pinned commit marker is invalid"
  grep -Fq 'SNIPPETS_MANAGEMENT_FOLDER: /app/snippets' docker-compose.yml || fail "Official snippets environment configuration is missing"
  grep -Fq './volumes/snippets:/app/snippets:z' docker-compose.yml || fail "Official snippets volume is missing"
  grep -Eq '^[[:space:]]*- name: basic-auth[[:space:]]*$' volumes/api/kong.yml || fail "Official Dashboard Basic Auth configuration is missing"
  grep -qx 'COMPOSE_FILE=docker-compose.yml' .env || fail "Optional Analytics/Vector Compose override must not be enabled"
  if grep -Eq 'image:[[:space:]]*[^#[:space:]]*:latest([[:space:]]|$)' docker-compose.yml; then
    fail "Unpinned latest image found in the official base Compose file"
  fi
  [ "$(stat -c '%a' "$SUPABASE_DIR")" = 700 ] || fail "$SUPABASE_DIR permissions must be 700"
  [ "$(stat -c '%a' .env)" = 600 ] || fail ".env permissions must be 600"
  docker compose config --quiet
  ACTIVE_SERVICES=$(docker compose config --services)
  for REQUIRED_SERVICE in studio kong auth rest realtime storage imgproxy meta functions db supavisor; do
    printf '%s\n' "$ACTIVE_SERVICES" | grep -qx "$REQUIRED_SERVICE" || fail "Required official service is missing: $REQUIRED_SERVICE"
  done
  if printf '%s\n' "$ACTIVE_SERVICES" | grep -Eq '^(analytics|vector)$'; then
    fail "Optional Analytics/Vector services must not be active"
  fi

  # ---- Stage 5: pull with retries and start through the official run.sh ----
  PULL_OK=0
  for ATTEMPT in 1 2 3 4 5; do
    if ./run.sh pull; then
      PULL_OK=1
      break
    fi
    echo "[$(date --iso-8601=seconds)] Image pull attempt $ATTEMPT/5 failed"
    [ "$ATTEMPT" -eq 5 ] || sleep 30
  done
  [ "$PULL_OK" -eq 1 ] || fail "Image pull failed after 5 attempts"
  ./run.sh start --wait-timeout 900

  # ---- Stage 6: verify Dashboard protection and writable SQL snippets ----
  UNAUTHENTICATED_STATUS=$(curl -sS -o /dev/null -w '%%{http_code}' http://127.0.0.1:8000/)
  [ "$UNAUTHENTICATED_STATUS" = 401 ] || fail "Dashboard must return HTTP 401 without credentials; got $UNAUTHENTICATED_STATUS"
  DASHBOARD_USERNAME=$(grep '^DASHBOARD_USERNAME=' .env | cut -d= -f2-)
  DASHBOARD_PASSWORD=$(grep '^DASHBOARD_PASSWORD=' .env | cut -d= -f2-)
  AUTHENTICATED_STATUS=$(curl -sS -o /dev/null -w '%%{http_code}' -u "$DASHBOARD_USERNAME:$DASHBOARD_PASSWORD" http://127.0.0.1:8000/)
  case "$AUTHENTICATED_STATUS" in
    2??|3??) ;;
    *) fail "Dashboard Basic Auth verification failed with HTTP $AUTHENTICATED_STATUS" ;;
  esac
  docker compose exec -T studio sh -c 'test -d /app/snippets && test -w /app/snippets' || fail "Studio snippets directory is not writable"
  [ "$(stat -c '%a' .env)" = 600 ] || fail ".env permissions changed after deployment"

  # ---- Stage 7: use the official run.sh for systemd lifecycle management ----
  cat > /etc/systemd/system/supabase.service <<'UNITEOF'
  [Unit]
  Description=Supabase self-hosted stack
  Requires=docker.service
  After=docker.service network-online.target
  Wants=network-online.target

  [Service]
  Type=oneshot
  RemainAfterExit=yes
  WorkingDirectory=/opt/supabase
  ExecStart=/opt/supabase/run.sh start --wait-timeout 900
  ExecStop=/opt/supabase/run.sh stop
  TimeoutStartSec=1000
  TimeoutStopSec=300

  [Install]
  WantedBy=multi-user.target
  UNITEOF
  systemctl daemon-reload
  systemctl enable supabase.service

  rm -rf "$SOURCE_DIR"
  trap - EXIT
  echo "[$(date --iso-8601=seconds)] Supabase bootstrap completed"
  EOT
}

output "access_info" {
  description = "Supabase access and operations information"
  value       = "Wait about 10-20 minutes for cloud-init to finish. Dashboard: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/ | Retrieve the randomly generated Dashboard password only over SSH with: cd /opt/supabase && sudo ./run.sh secrets | Deployment log: /var/log/supabase-bootstrap.log"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
