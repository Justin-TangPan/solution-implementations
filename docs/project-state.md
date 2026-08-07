# Project State

This document summarizes repository state without duplicating structured inventories. Authority and field
ownership are defined in [source-of-truth.md](source-of-truth.md).

## Current Formal Scope

- Formal practices: `project.config.json` → `formal.practices`
- Formal verification tools: `scripts/tests/`
- SAC Core: `skills/sac-project/`, `skills/sac-architecture/`, `skills/sac-implementation/`,
  `skills/sac-quality/`, `skills/sac-documentation/`
- Capability roles and supported Coding Agent adapters: `project.config.json` → `agent_capabilities`
- Formal npm distribution: `package.json`, `bin/sac.js`, `src/`, and `templates/`
- Auxiliary visualization: `web/` (read-only presentation layer; not a release authority)
- Scope config: `project.config.json`

## Explicitly Out Of Formal Scope

- `AGENTS.md`, `.codex/`, `.claude/CLAUDE.md`, `.claude/skills/`, and `.claude/agents/` are Runtime adapters,
  not SAC business-rule authorities. Legacy `.claude/workflows/` remains compatibility-only.
- Historical half-finished practices may still be referenced by old documents, scripts, or catalog data. Those references are not formal unless the practice is listed in `project.config.json`.

## Source of Truth

`project.config.json` defines formal scope and project policy. Implementation facts live in `practices/`,
and executable checks provide validation evidence. The complete precedence order remains owned by
`skills/sac-project/SKILL.md`; this status page does not restate it.

## npm Distribution

The package name is `solution-practices`, the executable is `sac`, and Node.js 20 or newer is required.
Installed state is recorded in `.sac/manifest.json`. Distribution compatibility and file-ownership rules are
defined in `docs/contracts/npm-distribution.md`.

## Data-Source Policy

README, Web snapshots, presentation material, and historical scripts are never formal-scope authorities.

`practices/` contains only configured formal projects. Local candidates that have not entered formal scope are
kept under `.var/candidates/practices/`; empty layout directories and duplicate input archives are excluded.

## Current Template Policy

- Terraform is stored directly in each deployable instance directory; a sole standard deployment uses the Region directory directly.
- `scripts/` is optional because some practices use fully inline `user_data`.
- `.extension` is recommended but not currently a hard requirement.
