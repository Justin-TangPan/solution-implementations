import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const PACKAGE_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
export const MANIFEST_SCHEMA_VERSION = 1;
export const MANIFEST_PATH = '.sac/manifest.json';
export const AGENTS_START = '<!-- SAC:START -->';
export const AGENTS_END = '<!-- SAC:END -->';
export const CLAUDE_START = '<!-- SAC:START -->';
export const CLAUDE_END = '<!-- SAC:END -->';

export const HELP = `SAC Solution Practices CLI

Usage:
  sac init [--dry-run] [--force]
  sac install codex|claude|all|skills [--dry-run] [--force]
  sac install practice <name> [--dry-run] [--force]
  sac update [--dry-run] [--force]
  sac list [--json]
  sac doctor [--json]
  sac help

Commands:
  init       Install both Coding Agent adapters, SAC Core skills, and isolated local tooling.
  install    Install one self-contained adapter, all adapters, shared skills, or one named practice.
  update     Update components recorded in .sac/manifest.json.
  list       List practices and installable components.
  doctor     Validate the local installation without modifying files.

Safety:
  Existing user-modified managed files are never overwritten by default. SAC writes a
  sibling .sac-new file for review. Use --force only when replacement is intentional.
`;
