# Script Policy

Scripts are classified by role before they are used in release automation.

## Formal

- `scripts/tests/`: static validation and quality gate.

## Optional

- `scripts/generate_extension.py`: extension generation helper.
- `scripts/validate_template.py`: template validation helper.

## General development tools

- `scripts/gen-practices-index.mjs`: generates the auxiliary Web catalog from `project.config.json` and
  `practices/`; it never defines formal release state.

## Archived historical scripts

Confirmed one-off scripts live under `scripts/archive/`. Formal workflows and Agents must not import, scan,
or execute that directory. Each archive directory documents the original purpose, replacement, and removal
stage.

Scripts with uncertain compatibility remain in place until their callers are confirmed.

Legacy external-publication helpers are local developer utilities and are outside the formal workflow and delivery package.
