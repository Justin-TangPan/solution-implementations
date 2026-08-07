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
  default     = "supabase"
  description = "解决方案名称，4-24个字符，支持小写字母、数字和中划线，必须以小写字母开头且不能以中划线结尾。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,22}[a-z0-9]$", var.solution_name))
    error_message = "解决方案名称必须为4-24个字符，以小写字母开头，以小写字母或数字结尾，且仅包含小写字母、数字和中划线。"
  }
}

variable "ecs_flavor" {
  default     = "x1.8u.16g"
  description = "云服务器实例规格，请选择目标区域实际可用规格。Supabase 需同时运行多个 Docker 容器，推荐 8 vCPUs、16 GiB 或更高配置。"
  type        = string
  nullable    = false
}

variable "ecs_password" {
  description = "云服务器密码，8-26位，至少包含大写字母、小写字母、数字和特殊字符中的三种。"
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

variable "db_password" {
  description = "PostgreSQL 数据库密码，8-24个字符，支持字母、数字和特殊字符（~!^*-=_+,），不支持@。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(regexall("^[a-zA-Z0-9~!^*\\-=_+,]{8,24}$", var.db_password)) > 0
    error_message = "PostgreSQL 数据库密码必须为8-24个字符，仅支持字母、数字和特殊字符（~!^*-=_+,），不支持@。"
  }
}

variable "system_disk_size" {
  default     = 100
  description = "系统盘大小（GB），高IO类型，取值范围：40-1024。Supabase建议100GB起步。默认：100。"
  type        = number
  nullable    = false
  validation {
    condition     = var.system_disk_size >= 40 && var.system_disk_size <= 1024
    error_message = "系统盘大小必须在40到1024之间。"
  }
}

variable "bandwidth_size" {
  default     = 300
  description = "弹性公网带宽（Mbit/s），按流量计费，取值范围：1-300。默认：300。"
  type        = number
  nullable    = false
  validation {
    condition     = var.bandwidth_size >= 1 && var.bandwidth_size <= 300
    error_message = "带宽必须在1到300之间。"
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
    error_message = "订购周期必须在1到9之间；选择按年时请填写1到3。"
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
  description       = "允许ping测试连通性"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "supabase_http" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Supabase Dashboard及API服务"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = 8000
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "cloud_shell" {
  security_group_id = huaweicloud_networking_secgroup.secgroup.id
  description       = "Cloud Shell SSH登录"
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
  system_disk_type            = "SAS"
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

  LOG="/var/log/supabase-bootstrap.log"
  exec > >(tee -a "$LOG") 2>&1
  echo "[$(date --iso-8601=seconds)] Supabase bootstrap started"

  export DEBIAN_FRONTEND=noninteractive
  export DEBCONF_NONINTERACTIVE_SEEN=true
  APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
  dpkg --configure -a >/dev/null 2>&1 || true
  apt-get update
  apt-get $APT_OPTS install ca-certificates curl gnupg jq lsb-release nodejs openssl xz-utils

  install -d -m 0755 /usr/share/keyrings
  curl -fsSL https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu/gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/docker.gpg
  chmod 0644 /usr/share/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://mirrors.huaweicloud.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  chmod 0644 /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get $APT_OPTS install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  install -d -m 0755 /etc/docker
  cat > /etc/docker/daemon.json <<'DOCKER_CONFIG'
  {
    "registry-mirrors": ["https://docker.wangzhou3.top"]
  }
  DOCKER_CONFIG
  systemctl enable docker
  systemctl restart docker
  for CHECK in 1 2 3 4 5; do
    systemctl is-active --quiet docker && break
    sleep 2
  done
  if ! systemctl is-active --quiet docker; then
    echo "[FATAL] Docker daemon failed to restart after registry mirror configuration"
    exit 1
  fi
  if ! docker info --format '{{json .RegistryConfig.Mirrors}}' | grep -Fq 'https://docker.wangzhou3.top/'; then
    echo "[FATAL] Docker daemon did not load the required registry mirror"
    docker info 2>&1 || true
    exit 1
  fi
  echo "[$(date --iso-8601=seconds)] Docker registry mirror loaded: https://docker.wangzhou3.top"

  SUPABASE_COMMIT="00ecb5305965ff85e1b5757e34a8eb5eb787f6f6"
  SUPABASE_DIR="/opt/supabase"
  RUNTIME_ARCHIVE="/tmp/supabase-runtime.txz"

  if [ -e "$SUPABASE_DIR" ]; then
    echo "[FATAL] $SUPABASE_DIR already exists; refusing to overwrite persistent data"
    exit 1
  fi

  base64 --decode > "$RUNTIME_ARCHIVE" <<'SUPABASE_RUNTIME_B64'
  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
  SUPABASE_RUNTIME_B64
  echo "3b2f91b97c413848ca6d3d46a421204435e00b11a010fd6ece2e8950e7075f08  $RUNTIME_ARCHIVE" | sha256sum --check --status || {
    echo "[FATAL] Embedded Supabase runtime checksum verification failed"
    exit 1
  }
  install -d -m 0700 "$SUPABASE_DIR"
  tar -xJf "$RUNTIME_ARCHIVE" -C "$SUPABASE_DIR"
  rm -f "$RUNTIME_ARCHIVE"
  chmod 0700 "$SUPABASE_DIR"
  cd "$SUPABASE_DIR"
  umask 077

  cp .env.example .env
  chmod 0600 .env
  if ! sh utils/generate-keys.sh --update-env >/dev/null 2>&1; then
    echo "[FATAL] Official Supabase secret generation failed"
    exit 1
  fi
  if ! sh utils/add-new-auth-keys.sh --update-env >/dev/null 2>&1; then
    echo "[FATAL] Official Supabase auth key generation failed"
    exit 1
  fi

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
  PUBLIC_URL="http://${huaweicloud_vpc_eip.vpc_eip.address}:8000"
  set_env POSTGRES_PASSWORD "$DB_PASSWORD"
  set_env SUPABASE_PUBLIC_URL "$PUBLIC_URL"
  set_env API_EXTERNAL_URL "$PUBLIC_URL/auth/v1"
  set_env SITE_URL "$PUBLIC_URL"
  set_env POOLER_TENANT_ID '${var.solution_name}'
  set_env OPENAI_API_KEY ''
  unset DB_PASSWORD DB_PASSWORD_B64 ESCAPED_VALUE
  rm -f .env.old docker-compose.yml.old
  chmod 0600 .env
  printf '%s\n' "$SUPABASE_COMMIT" > .supabase-upstream-commit
  chmod 0600 .supabase-upstream-commit

  test "$(cat .supabase-upstream-commit)" = "$SUPABASE_COMMIT"
  grep -Fq 'SNIPPETS_MANAGEMENT_FOLDER: /app/snippets' docker-compose.yml
  grep -Fq './volumes/snippets:/app/snippets:z' docker-compose.yml
  grep -Fq 'basic-auth' docker-compose.yml
  grep -Fq 'basic-auth' volumes/api/kong.yml
  grep -qx 'COMPOSE_FILE=docker-compose.yml' .env
  if grep -Eq 'image:[[:space:]]+[^#[:space:]]+:latest([[:space:]]|$)' docker-compose.yml; then
    echo "[FATAL] Unpinned :latest image found in the active official Compose file"
    exit 1
  fi

  docker compose config --quiet
  ACTIVE_SERVICES=$(docker compose config --services)
  for REQUIRED_SERVICE in studio kong auth rest realtime storage imgproxy meta functions db supavisor; do
    if ! printf '%s\n' "$ACTIVE_SERVICES" | grep -qx "$REQUIRED_SERVICE"; then
      echo "[FATAL] Required official service is missing: $REQUIRED_SERVICE"
      exit 1
    fi
  done
  if printf '%s\n' "$ACTIVE_SERVICES" | grep -Eq '^(analytics|vector)$'; then
    echo "[FATAL] Optional Analytics/Vector layer must not be active"
    exit 1
  fi

  PULL_OK=0
  for ATTEMPT in 1 2 3 4 5; do
    if ./run.sh pull; then
      PULL_OK=1
      break
    fi
    echo "[$(date --iso-8601=seconds)] Image pull attempt $ATTEMPT/5 failed"
    sleep 30
  done
  if [ "$PULL_OK" -ne 1 ]; then
    echo "[FATAL] Unable to pull the pinned official Supabase images"
    exit 1
  fi

  ./run.sh start --wait-timeout 900

  UNAUTH_CODE=$(curl -sS --max-time 30 -o /dev/null -w '%%{http_code}' http://127.0.0.1:8000/)
  if [ "$UNAUTH_CODE" != "401" ]; then
    echo "[FATAL] Dashboard unauthenticated request did not return 401"
    exit 1
  fi

  DASHBOARD_USERNAME=$(sed -n 's/^DASHBOARD_USERNAME=//p' .env | head -n 1)
  DASHBOARD_PASSWORD=$(sed -n 's/^DASHBOARD_PASSWORD=//p' .env | head -n 1)
  AUTH_CODE=$(curl -sS --max-time 30 -o /dev/null -w '%%{http_code}' \
    -u "$DASHBOARD_USERNAME:$DASHBOARD_PASSWORD" http://127.0.0.1:8000/)
  case "$AUTH_CODE" in
    2??|3??) ;;
    *)
      echo "[FATAL] Dashboard authenticated request is not accessible"
      exit 1
      ;;
  esac

  test -d volumes/snippets
  test -w volumes/snippets
  docker compose exec -T studio sh -c 'test -d /app/snippets && test -w /app/snippets'
  test "$(stat -c '%a' .env)" = "600"

  cat > /etc/systemd/system/supabase.service <<'SYSTEMD_UNIT'
  [Unit]
  Description=Supabase official Docker Compose stack
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
  SYSTEMD_UNIT
  systemctl daemon-reload
  systemctl enable supabase.service

  echo "[$(date --iso-8601=seconds)] Supabase bootstrap completed"
  EOT
}

output "access_info" {
  description = "部署访问信息"
  value       = "等待约10-15分钟部署完成 | Dashboard: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/ | REST API: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/rest/v1/ | Auth API: http://${huaweicloud_vpc_eip.vpc_eip.address}:8000/auth/v1/ | SSH: ssh root@${huaweicloud_vpc_eip.vpc_eip.address} | 登录后执行 cd /opt/supabase && ./run.sh secrets 可查看随机生成的 Dashboard 凭证（请勿在日志或工单中粘贴密码） | 日志: /var/log/supabase-bootstrap.log"
  depends_on  = [huaweicloud_vpc_eip.vpc_eip]
}
