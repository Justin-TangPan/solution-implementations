# Ownership

This file defines which parts of the repository are formal delivery assets, local collaboration assets, or experimental work.

## Formal Delivery

- `skills/sac-{project,architecture,implementation,quality,documentation}/`: platform-neutral SAC Core.
- `skills/query-huawei-cloud-prices/`: Huawei Cloud price query skill.
- `skills/reference/`: shared reference documents consumed by skills.
- `scripts/tests/`: quality gate test runner.
- `project.config.json`: skills registry and agent capabilities.
- `package.json`: npm package metadata.

## Local Collaboration

- `.claude/CLAUDE.md`, `.claude/skills/`, `.claude/agents/*.md`: Claude Code Adapter.
- `AGENTS.md`: project-level collaboration and orchestration instructions.
- `.var/log/`: local internal change log. `.var/` is never committed or uploaded.

These files can help development, but public release correctness must not depend on them.

## User-Controlled

- `practices/`, `release/`, `web/`: local-only practice output, not tracked in git.
- `.secrets/`, `.env`, OBS credentials, AK/SK, and test bucket endpoints.
