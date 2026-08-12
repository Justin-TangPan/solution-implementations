---
name: sac-quality
description: Review SAC Terraform and delivery evidence. Use for validate, static tests, security audits, architecture or documentation consistency, diff impact, accepted risk, release readiness, or remediation verification.
---

# SAC Quality Core

Perform an evidence-based review of the requested scope. Reviews are read-only unless remediation is explicitly
requested; implementation fixes belong to the Builder using `sac-implementation`. Static evidence never proves
a real cloud deployment succeeded.

Use with `sac-project`. Read the frozen architecture contract or explicit maintenance request, exact diff,
current Terraform and documents, `project.config.json` (or `.sac/project.config.json` in an installed host),
`skills/reference/validation-checklist.md`, and `skills/reference/security-check-rules.md`. Read the relevant
layout or release contract only when that scope is under review.

## Review scope

Cover the parts affected by the task:

1. Terraform syntax, formatting, provider shape, variables, validations, outputs, and dependency references;
   specifically verify:
   - no `validation` block references a variable other than its own (Terraform rejects cross-variable conditions);
   - no `*_password` variable contains a `validation` block (password policy is enforced by the cloud API);
   - no `output` joins unrelated values with `|`, commas, or other decorative separators.
   - `system_disk_type` is `"GPSSD"` unless the architecture contract explicitly overrides;
   - `system_disk_size` variable `description` does not mention a disk type;
   - bootstrap log destination is `/var/log/{solution_name}-install.log`;
   - no `bun install -g` in `user_data` (use `npm install -g` when npm is available);
   - China templates use `docker.wangzhou3.top/` image prefix for Docker Hub images;
     International templates use official Docker Hub or `ghcr.io` — no China-only mirror.
2. directory and artifact layout, exactly one deployable file per instance, and formal-scope consistency;
3. architecture-contract parity for resources, topology, network, storage, data, bootstrap, availability,
   operations, billing, and accepted deviations;
4. rendered `user_data`, shell, Compose or service configuration, startup order, persistence, and idempotency;
5. security exposure, secrets, privileges, dependency provenance, data protection, and sensitive artifacts;
6. document parity for parameters, defaults, ports, endpoints, limitations, rollback, and validation claims;
7. change impact on defaults, resource behavior, replacement risk, compatibility, and surrounding variants;
8. release provenance, deterministic packaging, checksums, and source equality when delivery is requested.

For a narrow change, review the changed item and its real callers or consumers. For a new Practice,
architecture change, security request, or release gate, cover the complete affected instance and documents.

## Static validation

Use existing repository entry points rather than reimplementing checks:

```bash
.venv-sac/bin/python -m scripts.tests.runner
```

In an npm-installed host use:

```bash
PYTHONPATH=.sac/tooling .venv-sac/bin/python -m scripts.tests.runner
```

Run narrower instance checks when the task scope is small. As applicable also run `terraform fmt -check`,
`terraform validate` in an initialized offline-capable environment, HCL or JSON parsing, rendered Bash syntax,
Compose validation, and the instance-scoped `rfs_policy`. If Terraform providers, plugins, credentials, or
network are unavailable, report the skipped command and cause; do not turn an environment limitation into a
pass or a code defect.

Separate:

- automatically executed results with command and exit code;
- manual findings backed by file and line evidence;
- environment or tool limitations;
- real-cloud checks not run.

## Security review

Security review is part of the Reviewer capability and must not be silently omitted from a full review or
release-readiness decision. At minimum inspect:

### Secrets and identity

- embedded AK/SK, API keys, tokens, passwords, private endpoints, or private bucket data;
- secret interpolation into Terraform state, `user_data`, command lines, URLs, outputs, logs, documents, or
  archives;
- password generation, storage, file permissions, rotation boundary, and credential-retrieval guidance;
- excessive cloud permissions and undocumented identity assumptions.

Never reproduce a suspected secret in full. Record location and type only.

### Network and service exposure

- ingress and egress CIDRs, ports, protocols, administrative access, TLS termination, and public-entry intent;
- public database, cache, Docker API, debugger, metrics, or control-plane exposure;
- security-group parity with the architecture contract and documents;
- trust boundaries between application, data services, external APIs, and management access.

### Runtime and supply chain

- privileged containers, host networking, Docker socket, dangerous host mounts, writable system paths, and
  runtime user;
- image source, immutable revision, installer provenance, package sources, and unverified remote execution;
- bootstrap failure handling, sensitive debug output, unsafe permissions, and persistence choices.

### Data and operations

- encryption and TLS assumptions, backups, restore path, deletion behavior, logs, tenant or user data, and
  recovery limits;
- artifacts or local packages containing credentials, transient files, private URLs, or unverifiable content.

Distinguish an approved public image proxy from a credential. Report untested runtime assumptions separately.

## Architecture and document consistency

Every resource and customer-facing value must trace to the architecture contract or explicit maintenance
request. Flag unapproved resources, missing dependencies, broader ingress, changed defaults, altered durability,
unexplained cost, and HA claims unsupported by the topology.

Compare Terraform and `.extension` against every affected parameter table, deployment step, endpoint, output,
security statement, rollback instruction, and cloud-test claim. Documentation must not state that static checks
proved a live deployment.

## Findings and accepted risk

Classify findings by release impact:

- **blocker**: invalid or undeployable template, formal contract violation, critical/high security exposure,
  secret disclosure, architecture conflict, unusable required document, or unverifiable delivery;
- **non-blocking**: material warning, incomplete optional coverage, maintainability issue, or defense-in-depth
  opportunity that does not invalidate the configured gate;
- **info**: evidence or improvement without release impact.

For security findings also retain `critical`, `high`, `medium`, or `low` severity. A critical or high security
finding is always a blocker unless an authorized, scope-specific accepted risk already exists. Accepted risk must
record owner or authority, exact scope, rationale, evidence, expiry or review condition, and compensating control.
Do not create or broaden accepted risk during review, and do not hide the underlying finding.

- `critical`: direct credential compromise, unauthenticated sensitive control, or equivalent immediate impact;
- `high`: practical remote compromise, broad privileged exposure, or release-blocking secret handling;
- `medium`: a defense-in-depth gap with meaningful prerequisites;
- `low`: a limited hardening opportunity.

## Result contract

Set `passed=false` when any blocker remains. For each finding return:

```text
id and category
blocker/non-blocking/info
security severity when applicable
file and line when available
evidence without secret values
impact
required remediation
verification guidance
accepted-risk reference when applicable
```

Also return commands, exit codes, checks not run and why, architecture/document consistency result, cloud-test
boundary, and whether another Builder fix plus Reviewer pass is required.
