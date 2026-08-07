# Legacy DOCX migrations (2026-06)

- Original purpose: generate or patch fixed LiteLLM, Headroom, and AiToEarn DOCX files, including scripts
  with personal Windows paths.
- Current callers: none; repository-wide reference search found only historical presentation labels.
- Replacement: edit the Markdown source and use `python -m scripts.document_pipeline` for generation,
  conversion, rendering, and validation.
- Formal workflow use: prohibited.
- Expected removal: a later compatibility-cleanup stage after historical outputs no longer need comparison.
