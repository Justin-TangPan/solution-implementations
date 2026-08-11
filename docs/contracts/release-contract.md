# Release Contract

Formal release automation must use the following inputs in order:

1. `project.config.json` for skills registry.
2. `skills/` for canonical skill definitions.
3. `scripts/tests/` for validation.
4. `CHANGELOG.md` for release history.

`.claude/agents/` and `.claude/workflows/` are not release authorities.

Before release:

- All skills must pass `npm test` and the quality gate.
- Credentials must not be committed or written into generated artifacts.
- Git, external publication, and real cloud-resource changes are separate explicitly authorized actions.
- Formal releases use three-level versions (`X.Y.Z`).
