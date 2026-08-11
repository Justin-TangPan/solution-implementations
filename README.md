# Solution Practice Skills

Canonical skill definitions for AI coding agents that build, review, and deploy Huawei Cloud Solution Practices.

## What this is

A **skills-core** package: structured SKILL.md files encoding engineering rules, validation checklists,
architecture contracts, and task-routing logic. Designed for consumption by Claude Code and compatible
AI coding tools.

The project does not call language models, provide an Agent Runtime, or deploy real cloud resources.
Skills are configuration, prompts, and engineering rules read by host tools.

## Core skills

| Skill | Purpose |
|---|---|
| `sac-project` | Project scope, layout, truth sources, and authorization |
| `sac-architecture` | Design contracts, topology, HA, and upstream research |
| `sac-implementation` | Terraform, variables, outputs, user_data, and bootstrap |
| `sac-quality` | Validation, security review, consistency, and release gates |
| `sac-documentation` | Deployment guides, parameter tables, and bilingual docs |

## Optional skills

| Skill | Purpose |
|---|---|
| `sac-deep-search` | Cross-domain, multi-source research for disputed topics |
| `sac-page-enhance` | Web presentation enhancements |
| `query-huawei-cloud-prices` | Huawei Cloud price and flavor queries |

## Project structure

```
skills/                          # Canonical skill definitions
  sac-*/SKILL.md                 # Core and optional skills
  reference/                     # Shared reference documents
  query-huawei-cloud-prices/     # Price query skill with scripts
.claude/                         # Claude Code adapter
  skills/                        # Discovery wrappers → canonical skills
  agents/                        # Role definitions (architect, builder, reviewer)
  workflows/                     # Workflow scripts
scripts/tests/                   # Quality gate test runner
docs/contracts/                  # Distribution and layout contracts
project.config.json              # Skills registry and capabilities
```

## Usage

Install as an npm package or clone directly. AI coding agents discover skills through
`.claude/skills/` (Claude Code) or the configured adapter path.

```bash
git clone https://github.com/Justin-TangPan/solution-practices.git
cd solution-practices
npm ci
npm test
```

## Development

```bash
npm test
.venv-sac/bin/python -m scripts.tests.runner
npm run pack:check
```

## License

MIT
