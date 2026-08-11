# SAC Agent Collaboration Rules

This repository is a **skills-core** project for AI coding agents. Canonical skill definitions in `skills/`
encode engineering rules, validation checklists, and architecture contracts for building, reviewing, and
deploying Huawei Cloud Solution Practices.

The project does not call language models or provide an Agent Runtime. Skills are configuration, prompts,
and engineering rules read by host tools.

## Task routing

Use the smallest sufficient role; not every task needs multiple agents:

| Task | Role / Flow | Core Skills |
|---|---|---|
| New Practice, topology/HA/database/storage/network design | Architect → Builder → Reviewer | `sac-project`, `sac-architecture`, `sac-implementation`, `sac-quality` |
| Maintain Terraform, variables, outputs, bootstrap | Builder; add Reviewer for medium/high risk | `sac-project`, `sac-implementation` |
| Security, quality, diff, or release-readiness review | Reviewer | `sac-project`, `sac-quality` |
| Deployment docs and parameter descriptions | Builder, load Documentation as needed | `sac-project`, `sac-documentation` |

## Working principles

- Run `git status --short` first; preserve existing user changes.
- Search all references before modifying; prefer smallest change.
- Never write credentials, tokens, or private endpoints to outputs or logs.
- Reviewer is read-only; fixes go through Builder.
- Static checks are not cloud verification; never claim deployed or production-ready without real-cloud evidence.
- External publishing, Git writes, and real cloud operations require explicit authorization.

## Verification

```bash
npm test
.venv-sac/bin/python -m scripts.tests.runner
npm run pack:check
```
