<!-- SAC:START -->
# SAC project instructions

This repository is an engineering package for producing and validating Solution Practices. It does not call
language models, provide an Agent Runtime, or deploy real cloud resources automatically. Terraform templates
and their verified documentation are the primary deliverables.

## Sources of truth

- `project.config.json`: formal Practice scope, project configuration, capability roles, and supported adapters.
- `skills/<name>/SKILL.md`: canonical SAC business rules. Files under `.claude/skills/` are discovery wrappers only.
- `docs/project-state.md`: maintained status narrative; do not maintain formal scope there by hand.
- `web/`: read-only presentation; never use it as a release or quality authority.

## Task routing

- Routine Terraform, variable, output, or initialization changes: use Builder with `sac-project` and
  `sac-implementation`. A Terraform field description is implementation work, not documentation work.
- Deployment-guide, README, parameter-table, or other document-file changes: use Builder and load
  `sac-documentation`; load implementation only when repository facts must be checked.
- Security, validation, architecture consistency, diff, or release-readiness review: use Reviewer with
  `sac-project` and `sac-quality`. Never select compatibility names such as `sac-security` or `sac-testing`
  for a new request.
- New Practices, upstream research, topology changes, HA, database, storage, or network design: use Architect,
  then Builder and Reviewer when implementation is requested. Do not add Optional `sac-deep-search` unless
  the request genuinely requires disputed, cross-domain, multi-source research.
- Small tasks do not require three subagents. Use the smallest sufficient role sequence.

Claude Code discovers the five core wrappers in `.claude/skills/`. Each wrapper points to the matching
canonical `skills/<name>/SKILL.md`; read only the Skill relevant to the current task. Optional and compatibility
Skills are not preloaded.

## Working rules

- Inspect `git status --short` first and preserve existing user changes.
- Make the smallest change that satisfies the frozen architecture contract.
- Do not change Terraform resource behavior, defaults, public exposure, or dependencies without explicit scope.
- Keep static validation distinct from user-provided real-cloud test evidence.
- Never write credentials, private endpoints, or secrets to source, output, or logs.
- External publishing, Git writes, local delivery packaging, and real cloud changes require separate authorization.
- Record each modification batch in `.var/log/internal-changelog.md`; `.var/` is local-only.

## Checks

- Node tests: `npm test`
- Python quality gate: `.venv-sac/bin/python -m scripts.tests.runner`
- Web: `npm --prefix web run lint` and `npm --prefix web run build`
- Package contents: `npm pack --dry-run`

Archived scripts under `scripts/archive/` are not formal workflow inputs.
<!-- SAC:END -->
