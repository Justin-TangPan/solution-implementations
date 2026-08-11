# npm Distribution Contract

`solution-practices` is distributed as a skills-core package.

## Stable interfaces

- npm package: `solution-practices`
- canonical Skills: root `skills/`
- Claude Code discovery wrappers: `.claude/skills/`
- capability roles: `architect`, `builder`, `reviewer`
- Claude Code native assets: `.claude/CLAUDE.md`, `.claude/skills/`, `.claude/agents/*.md`

Renaming or removing one of these requires a major npm version or a documented compatibility alias and
deprecation period.

## Versions

- `package.json.version` is the npm SemVer package version.
- `package.json.sac.contentVersion` versions bundled Skills and agent contracts.

## File ownership

- `managed`: SAC may update the file only when its current checksum matches the previous manifest.
- `merge-block`: SAC owns only the text between explicit SAC markers.
- `user-owned`: SAC never replaces the file.

## Publication gate

Before `npm publish`:

1. Run `npm test`.
2. Run the formal SAC project gate.
3. Verify `npm pack --dry-run` lists only intended files.
