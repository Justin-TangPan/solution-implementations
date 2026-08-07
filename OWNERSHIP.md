# Ownership

This file defines which parts of the repository are formal delivery assets, local collaboration assets, or experimental work.

## Formal Delivery

- `practices/`: source of truth for deployable solution practices.
- `skills/sac-{project,architecture,implementation,quality,documentation}/`: platform-neutral SAC Core.
- `scripts/tests/`: quality gate for formal practices.
- `project.config.json`: current formal scope and quality-gate policy.
- `package.json`, `bin/`, and `src/`: npm package metadata and deterministic SAC CLI implementation.
- `templates/`: npm-installed mergeable project assets.

## Optional Delivery

- `scripts/obs/`: OBS upload workflow. It must read credentials only from environment variables.
- `scripts/generate_extension.py` and `scripts/validate_template.py`: helper tools for RFS packaging and validation.

## Auxiliary

- `web/`: read-only visualization. It is built in CI but is not a release or scope authority.
- `scripts/gen-practices-index.mjs`: web catalog generation helper. It must not be used as the formal source of truth.

## Local Collaboration

- `.claude/CLAUDE.md`, `.claude/skills/`, `.claude/agents/*.md`: Claude Code Adapter.
- `.claude/agents/*.json`, `.claude/workflows/`: legacy compatibility assets.
- `.claude/settings*.json`: local tool settings.
- `AGENTS.md`: Codex project-level collaboration and orchestration instructions.
- `.codex/agents/`: Codex role contracts.
- `.codex/workflows/`: Codex workflow contracts.
- `.var/log/`: local internal change log. Each modification batch records a timestamp and four-level internal version here. `.var/` is never committed or uploaded.

These files can help development, but public release correctness must not depend on them.

## User-Controlled

- `reference/`: read-only reference material unless the user explicitly authorizes edits.
- `.secrets/`, `.env`, OBS credentials, AK/SK, and test bucket endpoints.
- Production OBS bucket names and public production endpoints are open publication data for this project; they are not treated as security risks.

## Historical Or One-Off Scripts

Scripts that hard-code a local path, a specific practice, or a one-time document generation task should be treated as archive candidates. They should not be called by formal release automation until they are parameterized and documented.
