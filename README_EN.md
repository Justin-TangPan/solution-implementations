# Solution Practice Skills

**Canonical Skill Definitions for AI Coding Agents** — Engineering rules, validation checklists, and architecture contracts for Huawei Cloud solution practices.

[![npm version](https://img.shields.io/badge/version-0.17.1-blue)](https://github.com/Justin-TangPan/solution-practices)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **[中文版 README](README.md)**

---

## Overview

SAC (Solution Practice Skills) is a **skills-core** project. Its primary deliverable is a set of canonical SKILL.md files under the `skills/` directory, encoding the engineering rules, validation checklists, and architecture contracts that AI coding agents need when building, reviewing, and deploying Huawei Cloud solution practices.

The project itself **does not invoke language models**, **does not provide an Agent Runtime**, and **does not deploy real cloud resources**. The skill files are configuration, prompts, and engineering rules that host tools (such as Claude Code) read and execute.

---

## Core Skills

| Skill | Purpose |
|---|---|
| `sac-project` | Project scope, directory layout, source of truth, authorization boundaries |
| `sac-architecture` | Architecture contracts, topology, HA design, upstream research |
| `sac-implementation` | Terraform implementation, variables, outputs, user_data, init scripts |
| `sac-quality` | Static validation, security review, consistency checks, release gates |
| `sac-documentation` | Deployment guides, parameter tables, bilingual doc generation |

## Optional Skills

| Skill | Purpose |
|---|---|
| `sac-deep-search` | Cross-domain, multi-source deep research on controversial topics |
| `sac-page-enhance` | Web presentation layer enhancement |
| `query-huawei-cloud-prices` | Real-time Huawei Cloud product pricing & specs query |

---

## Agent Role Routing

The project defines three core AI agent roles. Select the simplest role sequence based on the task type:

| Task | Recommended Flow | Required Skills |
|---|---|---|
| New architecture / topology / HA / DB / storage / network design | **Architect → Builder → Reviewer** | `sac-project` + `sac-architecture` + `sac-implementation` + `sac-quality` |
| Terraform maintenance / variables / outputs / init script changes | **Builder**; add **Reviewer** for med/high risk | `sac-project` + `sac-implementation` |
| Security review / quality gates / diff analysis / release readiness | **Reviewer** | `sac-project` + `sac-quality` |
| Deployment docs & parameter description updates | **Builder** (load documentation skill as needed) | `sac-project` + `sac-documentation` |

> Small tasks do not require three sub-agents. Always choose the simplest role sequence sufficient to complete the task.

---

## Project Structure

```
skills/                                          # Canonical skill definitions (primary deliverable)
├── sac-project/SKILL.md                         # Project scope & configuration rules
├── sac-architecture/SKILL.md                    # Architecture design rules
├── sac-implementation/SKILL.md                  # Implementation & Terraform rules
├── sac-quality/SKILL.md                         # Quality review & validation rules
├── sac-documentation/SKILL.md                   # Documentation generation rules
├── sac-deep-search/SKILL.md                     # Optional: deep search
├── sac-page-enhance/SKILL.md                    # Optional: page enhancement
├── query-huawei-cloud-prices/                   # Optional: Huawei Cloud price query skill
│   ├── SKILL.md
│   ├── scripts/                                 # Price query scripts
│   └── references/
└── reference/                                   # Shared reference documents
    ├── validation-checklist.md                  # Validation checklist
    ├── security-check-rules.md                  # Security check rules
    ├── decision-framework.md                    # Decision framework
    ├── doc-templates.md                         # Doc template specifications
    ├── region-mapping.md                        # Region code mapping
    ├── docker-registry.md                       # Image mirror & registry rules
    └── skill-zone-rules.md                      # Skill context zone rules

.claude/                                         # Claude Code adapter layer
├── CLAUDE.md                                    # Project instructions (source of truth)
├── skills/                                      # Skill discovery wrappers → canonical skills
├── agents/                                      # Agent role definitions (architect, builder, reviewer)
└── workflows/                                   # Workflow scripts

scripts/tests/                                   # Quality gate test runner
├── runner.py                                    # Python quality gate entry
└── checks/                                      # Per-dimension check implementations

docs/contracts/                                  # Distribution contracts
├── npm-distribution.md                          # npm package distribution contract
├── practice-layout.md                           # Practice directory layout contract
├── release-contract.md                          # Release contract
├── script-policy.md                             # Script policy contract
└── skill-status.md                              # Skill status contract

project.config.json                              # Skill registry & agent capability definitions
package.json                                     # npm package metadata
```

---

## Usage

### Installation

```bash
# Install via npm
npm install solution-practices

# Or clone the repository
git clone https://github.com/Justin-TangPan/solution-practices.git
cd solution-practices
npm ci
```

### Using with Claude Code

Open Claude Code in the project directory and describe your task in natural language — the system automatically routes to the right skills.

```bash
cd solution-practices
claude
# Then just type what you need, for example:
# 「Design a cross-AZ HA web architecture using ELB + ECS + RDS」
# 「Review all changes under infra/ for security issues」
# 「Add a new subnet and security group in the existing VPC using Terraform」
```

Claude Code automatically selects the best-fit AI role (Architect / Builder / Reviewer) based on your request and loads the matching SAC skills to guide the work. **You don't need to know the skill names — just describe what you need.**

#### Real Conversation Examples

**Example 1: Design a new solution**

```
User: Design a cross-AZ HA web architecture using ELB + ECS + RDS
Claude → auto-detects as architecture task
       → loads sac-project + sac-architecture rules
       → outputs topology, HA plan, architecture constraints per skill requirements
```

**Example 2: Review changes**

```
User: Review all changes under infra/ for security issues
Claude → auto-detects as review task
       → loads sac-project + sac-quality rules
       → outputs security findings, consistency diffs, release readiness
```

**Example 3: Implement infrastructure**

```
User: Add a new subnet and security group in the existing VPC using Terraform
Claude → auto-detects as implementation task
       → loads sac-project + sac-implementation rules
       → generates Terraform code following skill constraints (variables, outputs, SG rules, etc.)
```

#### How Auto-routing Works

The project defines three AI agent roles in `.claude/agents/` (`architect`, `builder`, `reviewer`), each bound to a set of SAC skills. Claude Code infers the task type from your natural language, routes your request to the matching role, and the role auto-loads the bound skill rules to govern its output.

> You can also specify a role manually: prefix your request with `/architect`, `/builder`, or `/reviewer` to force a specific role.

---

## Development Guide

### Prerequisites

- Node.js >= 20
- Python 3.10+ (quality gate tests)
- Git

### Validation Commands

```bash
# Skills structure tests (Node)
npm test

# Python quality gate
.venv-sac/bin/python -m scripts.tests.runner

# Package check
npm run pack:check
```

### Commit Convention

```
<type>: <short description>

- <change 1>
- <change 2>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat` / `fix` / `refactor` / `test` / `docs` / `chore`

### Terraform Conventions

- Password/secret variables **must** set `sensitive = true`
- Password variables **do not** add a `validation` block — the cloud API enforces policy
- `validation` blocks can only reference their own variable (cross-variable refs unsupported)
- Security group rules must restrict source IP; `0.0.0.0/0` is prohibited
- All variables must include a `description` field
- Use standalone `output` blocks; no `|` or comma concatenation
- Region codes use standard naming (`cn-north-4`, `ap-southeast-1`, etc.)

---

## Version History

| Version | Date | Summary |
|---|---|---|
| v0.17.1 | 2026-08-13 | README split into pure Chinese + standalone English files; natural language usage guide |
| v0.17.0 | 2026-08-12 | Minimalist Skills refactor: centered on successful deployment |
| v0.16.0 | 2026-08-11 | Final cleanup: removed deprecated workflows, dangling ref fixes |
| v0.15.0 | 2026-08-11 | Skills-core repositioning: converged to pure skills project |
| v0.14.0 | 2026-08-07 | Dual adapter (Codex + Claude Code), 5 core skills convergence |
| v0.13.0 | 2026-08-06 | Workflow & repo structure convergence, Huawei Cloud price query skill |
| v0.12.0 | 2026-07-27 | Release consistency fixes, scope solidification |
| v0.11.0 | 2026-07-21 | Precision routing & local toolchain |
| v0.10.0 | 2026-07-20 | SAC Web added to GitHub release |
| v0.9.x | 2026-07 | Doc pipeline, npm CLI, multi-Practice candidate release |
| v0.6.x | 2026-07 | Region refactor, security fixes, Supabase completion |
| v0.5.x | 2026-06 | SAC Web visualization platform, business assessment Skill |
| v0.4.x–v0.0.x | 2026-05~06 | Initial releases and iterative evolution |

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.

---

## Security Notes

- **Do not** commit real AK/SK, passwords, or tokens in code
- **Do not** commit `.tfvars` files to the repository
- **Do not** commit `.secrets/`, `.env`, or OBS credentials
- Pass sensitive information via environment variables or RFS parameters
- Report security vulnerabilities to the maintainers

---

## License

[MIT](LICENSE)

---

## Related Links

- [GitHub Repository](https://github.com/Justin-TangPan/solution-practices)
- [Issue Tracker](https://github.com/Justin-TangPan/solution-practices/issues)
- [Contributing Guide](CONTRIBUTING.md)
- [Ownership](OWNERSHIP.md)
- [Agent Collaboration Rules](AGENTS.md)
