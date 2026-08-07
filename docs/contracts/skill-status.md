# Skill Status Contract

Skills are project knowledge assets. The five Core `SKILL.md` files own business behavior. Core/Optional/
Compatibility/Deprecated classification and capability-role binding are defined by `project.config.json`;
`skills-index.json` is a manually maintained display index validated against that configuration by `npm test`.

Runtime routing remains in the Codex and Claude Code adapters. The index is a discovery and audit view, not an
Agent Runtime. Core Skill frontmatter contains only portable metadata; platform fields belong in Adapter wrappers.

Formal skills must not assume that historical or removed practices still exist. The current formal list comes from `project.config.json`.

`sac-documentation` is the sole Core documentation entry for maintenance, generation, translation,
optional DOCX rendering, conversion, and quality gates. `sac-document-pipeline` is a compatibility alias
and is never loaded beside it. `sac-page-enhance` is loaded only for explicit page-copy work.
