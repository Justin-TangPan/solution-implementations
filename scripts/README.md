# Scripts

Scripts are classified before they are used by release automation.

## Formal

实例级固定 RFS 约束写入 `project.config.json` 的 `quality_gate.practice_policies`，由统一门禁中的 `rfs_policy` 检查：

```bash
.venv-sac/bin/python -m scripts.tests.runner --practice <project> --check rfs_policy
```

- `tests/`: quality gate for formal practices listed in `project.config.json`.
- `document_pipeline/`: offline-first document analysis, structured model, Markdown/Word rendering,
  translation protection, bilingual checks, and the document CLI. Formal acceptance still runs through
  `python -m scripts.tests.runner`.

Document CLI examples:

```bash
python -m scripts.document_pipeline analyze --project litellm
python -m scripts.document_pipeline generate --project litellm
python -m scripts.document_pipeline translate --project litellm
python -m scripts.document_pipeline render-word --project litellm
python -m scripts.document_pipeline validate --project litellm
python -m scripts.document_pipeline convert --input legacy.docx
```

Analysis, parsing, rendering, and deterministic checks work offline. Semantic generation or translation uses
only the explicitly configured internal, local, or external backend. Templates, style maps, glossaries, model
selection, and output paths are configuration values; secrets must come from approved runtime configuration
and must never be logged or copied into documents.

## Optional

- `obs/`: OBS upload flow. Credentials must come from environment variables only. Object keys are
  site/locale-aware, and uploaded zip/manifest objects are read back for SHA-256 verification.
- `obs_upload_supabase.py` / `.bat`: compatibility wrappers for the generic OBS uploader; they contain no credentials and require an explicit test version.
- `generate_extension.py`: RFS extension helper.
- `validate_template.py`: template validation helper.

## General development tools

- `gen-practices-index.mjs`: generates the auxiliary Web catalog from `project.config.json` and
  `practices/`. CI validates the generated index and Web build, but Web is not a release authority.
- `skills-vector-index.py`: skill search/index helper.

## Archived historical scripts

Confirmed one-off DOCX migration scripts are under `archive/docx-migrations-2026-06/`; the one-time security
migration is under `archive/security-migration-2026-07/`. Formal workflows and Agents must not scan or call
`scripts/archive/`. See each directory's README for the original purpose, replacement, and deletion stage.

`package_solution.sh`, `generate_extension.py`, `validate_template.py`, and the OBS compatibility wrappers
remain in place pending compatibility confirmation; they are not part of the formal quality gate.
