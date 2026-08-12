---
name: sac-implementation
description: Build or maintain SAC Terraform and local delivery assets. Use for resources, variables, outputs, providers, modules, user_data, bootstrap scripts, dependencies, RFS/OpenTofu compatibility, or deterministic packaging.
---

# SAC Implementation Core

Map an approved design or narrowly scoped maintenance request to the smallest Terraform and documentation
change that preserves existing deployment behavior outside the requested scope. This Skill creates local files;
it never authorizes cloud changes, publication, version changes, or Git operations.

Use with `sac-project`. Load `sac-documentation` only when documents must change. New Practices and architecture
changes require a complete `sac-architecture` contract. For a small maintenance edit, the existing implementation
plus the explicit request is the contract; do not redesign adjacent resources.

## Required implementation input

Before editing, resolve the exact project, site, Region, optional variant, source file, requested behavior, and
expected checks. For new or architecture-changing work, also resolve:

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

For a new ECS-based Practice, start from the canonical baseline order. Do not start from a blank file or redesign it:

```text
terraform/provider → variables → image data → VPC → subnet → security-group rules → EIP → ECS → outputs
```

Place the only standard deployment directly in:

```text
practices/<project>/<site>/<region>/deploying-<project>_vN.tf
```

Use `practices/<project>/<site>/<region>/<variant>/` only when variants coexist in that Region. Never add a
redundant `terraform/` wrapper. Each deployable instance directory contains exactly one loadable `.tf` or
`.tf.json` file and optional `.extension`.

## Implementation procedure

1. Inspect every reference to the target resource, variable, output, script, path, and document before editing.
2. Preserve provider constraints, resource topology, defaults, dependency order, and unrelated formatting.
3. For new templates, replace only contract fields: Region, names, confirmed values, image, ingress, EIP, ECS,
   tags, inline bootstrap, and outputs. Keep one `huaweicloud` provider with only `region`.
4. Keep one inline `#!/bin/bash` `user_data` block and the baseline shell/Compose shape. Adapt runtime commands
   only to the upstream project's documented installation unit. Do not add helper files, generated Terraform,
   credentials, or an unapproved remote installer.
5. Keep runtime-required configuration only. Pin the contract's approved upstream image or deployment revision
   and persist only plan-defined paths.
6. Express dependencies with native Terraform references. Do not add ordering, retries, variables, outputs, or
   resources as speculative flexibility.
7. Update affected documents from the resulting implementation; never make Terraform match stale prose.

## Variables and outputs

Every customer-facing variable includes `default`, `description`, `type`, and `nullable`, in that order. Add a
validation only for its own variable and only when the implementation contract requires it.

### Validation rules

1. **Self-reference only.** Terraform `validation` blocks can only reference the variable being validated
   (`var.xxx`). Cross-variable references (e.g. checking `var.charging_unit` inside `var.charging_period`) are
   rejected at `terraform validate`. When a variable's valid range depends on another variable, state the
   constraint in `error_message` only; do not attempt it in `condition`.

2. **No password validation.** Password variables (`ecs_password`, `db_password`, and any `*_password` input)
   must **not** include a `validation` block. Password complexity rules vary by cloud API version and special-
   character set; regex validation in Terraform frequently rejects legitimate passwords. Let the cloud API
   enforce its own policy and return clear errors at apply time.

3. **Flavor format.** ECS flavor validation matches the two supported naming conventions:
   - International: `{family}.{size}xlarge.{generation}` (e.g. `c7n.2xlarge.2`)
   - CN: `x1.{cpu}u.{mem}g` (e.g. `x1.4u.8g`)
   Use the combined regex:
   ```
   ^([a-z][a-z0-9]{0,3}\.)(x|[1-9][0-9]{0,1}x)large\.[1-9][0-9]{0,1}$|^x1\.([1-9]|1[0-6])u\.([1-9][0-9]{0,1}|1[0-2][0-8])g$
   ```
   Do not use a simpler "at least one letter and one digit" check — the combined regex prevents
   mistyped flavor strings while accepting both CN and international formats.

| Variable | Default | Type / nullable | Required rule |
|---|---|---|---|
| `solution_name` | confirmed lowercase project name | `string` / `false` | description states naming rule and default |
| `ecs_flavor` | confirmed flavor | `string` / `false` | at least one letter and one digit (see rule 3) |
| `ecs_password` | `""` | `string` / `true`; `sensitive = true` | no validation block (see rule 2); never output it |
| `system_disk_size` | confirmed GiB, normally `100` | `number` / `false` | `length(regexall("^([4-9][0-9]|[1-9][0-9]{2}|10[01][0-9]|102[0-4]|1024)$", var.system_disk_size)) > 0` |
| `bandwidth_size` | confirmed Mbps, normally `300` | `number` / `false` | `length(regexall("^([1-9][0-9]{0,1}|[1-2][0-9]{2}|300)$", var.bandwidth_size)) > 0` |
| `charging_mode` | `"postPaid"` | `string` / `false` | `contains(["postPaid", "prePaid"], var.charging_mode)` |
| `charging_unit` | `"month"` | `string` / `false` | `contains(["month", "year"], var.charging_unit)` |
| `charging_period` | `1` | `number` / `false` | `length(regexall("^[1-9]$", var.charging_period)) > 0` |

Preserve existing variable defaults unless the architecture contract explicitly changes deployment behavior.
Product-specific variables follow the same field rules and need an exact contract value.

Provide one short primary `access_instructions` or `access_info` output. Add separate meaningful `snake_case`
outputs for each value users must retrieve independently, such as `dashboard_url`, `rest_api_url`,
`auth_api_url`, `ssh_command`, `dashboard_password_hint`, and `deployment_log`. **Never join unrelated
values with `|`, commas, or any decorative separator** — each distinct piece of information is its own
`output` block. This ensures downstream automation can reference individual outputs
(`terraform output -raw dashboard_url`) and JSON output is naturally structured. Interpolate the
provisioned EIP for a public entry; describe the agreed private-access path for a private entry. Keep output
descriptions short and ASCII-only. Never output a password, token, generated secret, or speculative detail.

## Infrastructure and bootstrap rules

- Preserve the canonical image and `agent_list` unless the architecture contract records a regional or upstream
  reason to change them.
- Use `GPSSD` as the required EVS type. Every template must set `system_disk_type = "GPSSD"`.
  Do not use `SAS`, `SSD`, or any other type unless the architecture contract explicitly overrides.
  The `system_disk_size` variable description must not mention disk type — disk type is a
  resource attribute, not a sizing parameter.
  Keep `delete_disks_on_termination` exactly aligned with the durability decision.
- Current formal policy requires an EIP and `bandwidth_size`; preserve its billing mode and the approved
  application ingress scope.
- Keep administrative SSH at `121.36.59.153/32`. Open only the approved application ports. Never expose a
  database, cache, Docker API, debugger, or internal control port.
- Use no random provider or random resource names.
- China vs international deployment differences:

  | Dimension | China (cn-*) | International |
  |---|---|---|
  | Docker image prefix | `docker.wangzhou3.top/` (e.g. `docker.wangzhou3.top/library/postgres:16`) | Official Docker Hub or `ghcr.io` |
  | Docker daemon mirror | `"registry-mirrors": ["https://docker.wangzhou3.top"]` | None (direct pull) |
  | Docker CE source | Huawei Cloud apt mirror | Official Docker CE source |
  | apt/npm upstream | Default Huawei Cloud or mirror | Default official |

  China templates must use `docker.wangzhou3.top/` as image prefix for every Docker Hub image
  in Compose files. Never use `docker.wangzhou3.top/` outside China templates.
- Mark secret inputs sensitive, keep generated runtime secrets on the instance with restrictive permissions,
  and never place secret values in URLs, outputs, logs, archives, or documentation.
- Passing an established RFS password input through `user_data` is a reviewable compatibility exposure, not a
  blanket approval. Minimize its scope and prefer the native ECS password field where the template supports it.
- Reset the ECS root password in `user_data` with the simple inline pattern:
  ```bash
  echo 'root:${var.ecs_password}' | chpasswd
  ```
  The `user_data` heredoc delimiter must be **unquoted** (`<<-EOT`, not `<<-'EOT'`) so Terraform interpolates
  `var.ecs_password` at render time. Do not use Base64 encode/decode wrappers or intermediate variables for the
  root password — the inline `echo` + `chpasswd` pattern is sufficient and avoids unnecessary complexity.

- Redirect bootstrap output to `/var/log/{solution_name}-install.log`. Use the pattern immediately
  after `export DEBIAN_FRONTEND=noninteractive`:
  ```bash
  LOGFILE="/var/log/${var.solution_name}-install.log"
  exec 1>"$LOGFILE" 2>&1
  ```
  Do not place logs in `/var/`, `/tmp/`, or the working directory — only `/var/log/`.

- When a system package manager (apt, yum) already provides Node.js/npm, use `npm install -g`
  for global Node.js tools. Do not use `bun install -g` — Bun's global directory is not
  reliably initialized in a bootstrap context. Prefer the package manager that matches the
  runtime already installed.

## Local checks and fix loop

Run the smallest checks that cover the change, including as applicable:

- `terraform fmt -check` when Terraform is installed;
- HCL or JSON parsing;
- rendered Bash syntax and generated Compose validation;
- instance-scoped `rfs_policy`;
- affected documentation checks;
- the formal project quality entry before local delivery.

Return paths, commands, exit codes, findings fixed, and cloud checks not run. Tool or plugin download failure is
an environment result, not evidence that a template passed or failed in the cloud.

## Local delivery

When local packaging is requested and quality has passed:

1. copy only authoritative `practices/` inputs and required documents to the local delivery directory;
2. byte-compare every copied file with its source;
3. create the archive deterministically and list its contents;
4. generate SHA-256 checksums for delivered files and the archive;
5. update version records only with explicit authorization.

Do not create URL manifests or hosted-object metadata. Return the release directory, site, Region, variant,
archive, checksums, comparison result, and the quality evidence used. Local packaging never means published,
deployed, or production-ready.
