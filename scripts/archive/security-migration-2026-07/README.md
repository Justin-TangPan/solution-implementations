# Legacy security migration (2026-07)

- Original purpose: perform a one-time broad `sed` migration against obsolete demo scripts and print a
  repository scan.
- Current callers: none; only a historical CHANGELOG entry remains.
- Replacement: use the read-only `sac-security` review and `python -m scripts.tests.runner`, then apply
  narrowly scoped fixes through the normal development workflow.
- Formal workflow use: prohibited.
- Expected removal: a later compatibility-cleanup stage after the historical migration no longer needs
  regression reference.
