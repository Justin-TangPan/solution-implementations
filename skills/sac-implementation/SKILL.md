---
name: sac-implementation
description: Build or maintain SAC Terraform and deployment assets. Use for resources, variables, outputs, providers, modules, user_data, bootstrap scripts, dependencies, or packaging.
---

# SAC Implementation Core

Produce minimal, deployable Terraform and bootstrap scripts that successfully launch the target application
on Huawei Cloud ECS. **一切以资源与应用的成功部署为目标。** This Skill creates local files; actual cloud deployment
requires proper provider credentials and `terraform apply`.

Use with `sac-project`. Load `sac-documentation` only when documents must change. New Practices and architecture
changes require a complete `sac-architecture` contract. For a small maintenance edit, the existing implementation
plus the explicit request is the contract.

## Required implementation input

Before editing, resolve: project, site, Region, optional variant, source file, requested behavior, and expected checks.

For new or architecture-changing work, also resolve:

```text
upstream revision and installation unit
image and compute flavor
disk type, size, and termination behavior
billing mode and period
VPC and subnet CIDRs
ingress ports and source CIDRs
EIP bandwidth and billing
runtime commands and persistent paths
external service dependencies
outputs and access instructions
accepted deviations
```

Stop when a missing value would require inventing a resource, variable, default, endpoint, dependency, or
security choice.

## Terraform baseline and layout

For a new ECS-based Practice, start from the canonical baseline order:

```text
terraform/provider → variables → image data → VPC → subnet → security-group rules → EIP → ECS → outputs
```

Place the standard deployment directly in:

```text
practices/<project>/<site>/<region>/deploying-<project>_vN.tf
```

Use `practices/<project>/<site>/<region>/<variant>/` only when variants coexist in that Region. Never add a
redundant `terraform/` wrapper. Each deployable instance directory contains exactly one loadable `.tf` or
`.tf.json` file and optional `.extension`.

## Infrastructure rules

- Preserve the canonical image and `agent_list` unless the architecture contract records a reason to change them.
- Use `GPSSD` as the default EVS system disk type. Override only when the architecture contract explicitly requires it.
  Keep `delete_disks_on_termination` aligned with the durability decision.
- Current formal policy requires an EIP and `bandwidth_size`; preserve its billing mode and approved ingress scope.
- Keep administrative SSH restricted to the configured CloudShell `/32` source. Open only the approved application ports.
  Never expose database, cache, Docker API, debugger, or internal control ports.
- Use no random provider or random resource names.
- China vs international deployment differences:

  | Dimension | China (cn-*) | International |
  |---|---|---|
  | Docker image prefix | `docker.wangzhou3.top/` | Official Docker Hub or `ghcr.io` |
  | Docker daemon mirror | `"registry-mirrors": ["https://docker.wangzhou3.top"]` | None (direct pull) |
  | Docker CE source | Huawei Cloud apt mirror | Official Docker CE source |
  | apt/npm upstream | Default Huawei Cloud or mirror | Default official |

  China templates must use `docker.wangzhou3.top/` as image prefix for Docker Hub images in Compose files.
  Never use `docker.wangzhou3.top/` outside China templates.

- Mark secret inputs as `sensitive = true`. Keep generated runtime secrets on the instance with restrictive
  permissions. Never place secret values in URLs, outputs, logs, archives, or documentation.
- Reset the ECS root password in `user_data` with the simple inline pattern:
  ```bash
  echo 'root:${var.ecs_password}' | chpasswd
  ```
  Use an **unquoted** heredoc delimiter (`<<-EOT`, not `<<-'EOT'`) so Terraform interpolates variables.
  Do not add Base64 encode/decode wrappers or intermediate variables for the root password.

## user_data / bootstrap 脚本规范

以 **极简高效** 为核心原则，部署脚本不加复杂代码逻辑。

### 标准模板

```bash
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
LOGFILE="/var/log/${var.solution_name}-install.log"
exec 1>"$LOGFILE" 2>&1

# System preparation
apt-get update -y && apt-get install -y docker-compose-plugin

# Deploy application
mkdir -p "$APP_DIR"
cat > "$APP_DIR/docker-compose.yaml" << 'EOF'
version: "3.8"
services:
  app:
    image: ${image}
    restart: always
EOF

# Start services
cd "$APP_DIR" && docker compose up -d
```

### 核心原则

1. **单段内联 Bash** — 不依赖外部安装脚本、不生成辅助脚本、不添加 base64 包装
2. **无复杂逻辑** — 不加 retry 循环、状态机、条件分支树。若需要等待依赖就绪，使用简单的 `sleep N` + 单次健康检查
3. **启动顺序** — 通过 Docker Compose `depends_on` 控制服务启动顺序，无需自定义编排逻辑
4. **日志可追溯** — 输出重定向到 `/var/log/{solution_name}-install.log`
5. **幂等性** — 包管理命令加 `-y` 等幂等标志；数据库初始化使用 `CREATE IF NOT EXISTS` 模式
6. **容器权限** — 避免使用全局 `umask 077`（会影响 bind-mount 文件的容器可读性）。敏感文件用显式 `chmod` 控制权限即可

### 镜像与版本

- 使用架构合同批准的上游镜像或部署版本
- 不添加未批准的远端安装器或自建镜像

## Variables and outputs

Every customer-facing variable includes `default`, `description`, `type`, and `nullable`, in that order.
Add a `validation` block only when the implementation contract requires it. Password variables
(`ecs_password`, `db_password`, `*_password`) must **not** include a `validation` block — let the cloud API
enforce its own password policy.

| Variable | Default | Type / nullable | Notes |
|---|---|---|---|
| `solution_name` | confirmed lowercase name | `string` / `false` | description states naming rule |
| `ecs_flavor` | confirmed flavor | `string` / `false` | validates expected format |
| `ecs_password` | `""` | `string` / `true`; `sensitive = true` | no validation block; never output |
| `system_disk_size` | confirmed GiB | `number` / `false` | validates range |
| `bandwidth_size` | confirmed Mbps | `number` / `false` | validates range |
| `charging_mode` | `"postPaid"` | `string` / `false` | `postPaid` or `prePaid` |
| `charging_unit` | `"month"` | `string` / `false` | `month` or `year` |
| `charging_period` | `1` | `number` / `false` | validates range |

Product-specific variables follow the same field rules and need an exact contract value.

**Outputs**: Provide one short primary `access_instructions` or `access_info` output. Add separate
`snake_case` outputs for each distinct value users must retrieve independently (`dashboard_url`,
`rest_api_url`, `ssh_command`, etc.). **Never join unrelated values with `|`, commas, or decorative
separators** — each distinct piece of information gets its own `output` block. Never output a password,
token, generated secret, or speculative detail.

## Local checks and fix loop

Run the smallest checks that cover the change:

- `terraform fmt -check` when Terraform is installed;
- HCL or JSON parsing;
- rendered Bash syntax and generated Compose validation;
- instance-scoped `rfs_policy` when applicable;
- affected documentation checks;
- the formal project quality entry before local delivery.

Return paths, commands, exit codes, findings fixed, and cloud checks not run. Tool or plugin download failure
is an environment result, not evidence that a template passed or failed in the cloud.

## Local delivery

When local packaging is requested and quality has passed:

1. Copy only authoritative `practices/` inputs and required documents to the local delivery directory.
2. Byte-compare every copied file with its source.
3. Create the archive deterministically and list its contents.
4. Generate SHA-256 checksums for delivered files and the archive.
5. Update version records only with explicit authorization.

Return the release directory, site, Region, variant, archive, checksums, comparison result, and quality evidence.
