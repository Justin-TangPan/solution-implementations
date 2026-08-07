import { join } from 'node:path';
import { readFile } from 'node:fs/promises';
import {
  AGENTS_END,
  AGENTS_START,
  CLAUDE_END,
  CLAUDE_START,
  MANIFEST_PATH,
  MANIFEST_SCHEMA_VERSION,
} from './constants.js';
import { exists, readText, sha256 } from './fs-utils.js';

function result(level, code, message) {
  return { level, code, message };
}

export async function diagnose(targetDir = process.cwd()) {
  const results = [];
  const manifestFile = join(targetDir, MANIFEST_PATH);
  if (!(await exists(manifestFile))) {
    return {
      ok: false,
      results: [result('error', 'manifest-missing', 'No .sac/manifest.json; run "sac init".')],
    };
  }

  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestFile, 'utf8'));
  } catch (error) {
    return { ok: false, results: [result('error', 'manifest-invalid', error.message)] };
  }
  if (manifest.schemaVersion !== MANIFEST_SCHEMA_VERSION) {
    results.push(result('error', 'schema-unsupported', `Manifest schema is ${manifest.schemaVersion}; expected ${MANIFEST_SCHEMA_VERSION}.`));
  }

  for (const [path, metadata] of Object.entries(manifest.managedFiles ?? {})) {
    const absolute = join(targetDir, path);
    if (!(await exists(absolute))) {
      results.push(result('error', 'managed-file-missing', path));
      continue;
    }
    if (metadata.mode === 'merge-block') continue;
    const checksum = sha256(await readFile(absolute));
    if (checksum !== metadata.checksum) {
      results.push(result('warning', 'managed-file-modified', path));
    }
  }

  if (manifest.components?.codex) {
    for (const required of [
      'AGENTS.md',
      '.codex/agents/architect.toml',
      '.codex/agents/builder.toml',
      '.codex/agents/reviewer.toml',
      '.codex/workflows/full-pipeline.md',
    ]) {
      if (!(await exists(join(targetDir, required)))) {
        results.push(result('error', 'codex-incomplete', required));
      }
    }
    const agentsPath = join(targetDir, 'AGENTS.md');
    if (await exists(agentsPath)) {
      const agents = await readText(agentsPath);
      if (agents.split(AGENTS_START).length !== 2 || agents.split(AGENTS_END).length !== 2) {
        results.push(result('error', 'agents-block-invalid', 'AGENTS.md must contain exactly one complete SAC marker block.'));
      }
    }
  }
  if (manifest.components?.claude) {
    for (const required of [
      '.claude/CLAUDE.md',
      '.claude/agents/architect.md',
      '.claude/agents/builder.md',
      '.claude/agents/reviewer.md',
    ]) {
      if (!(await exists(join(targetDir, required)))) results.push(result('error', 'claude-incomplete', required));
    }
    const claudePath = join(targetDir, '.claude/CLAUDE.md');
    if (await exists(claudePath)) {
      const claude = await readText(claudePath);
      if (claude.split(CLAUDE_START).length !== 2 || claude.split(CLAUDE_END).length !== 2) {
        results.push(result('error', 'claude-block-invalid', 'CLAUDE.md must contain exactly one complete SAC marker block.'));
      }
    }
  }
  if (manifest.components?.skills) {
    for (const required of [
      '.sac/tooling/scripts/document_pipeline/__main__.py',
      '.sac/tooling/scripts/tests/runner.py',
      '.sac/tooling/requirements-document-pipeline.txt',
    ]) {
      if (!(await exists(join(targetDir, required)))) results.push(result('error', 'tooling-incomplete', required));
    }
    const indexPath = join(targetDir, 'skills-index.json');
    if (!(await exists(indexPath))) {
      results.push(result('error', 'skills-index-missing', 'skills-index.json'));
    } else {
      try {
        const index = JSON.parse(await readText(indexPath));
        for (const skill of index.skills.filter((item) => item.owner === 'project')) {
          if (!/^skills\/[a-z0-9-]+\/SKILL\.md$/.test(skill.path)) {
            results.push(result('error', 'skills-index-invalid', `Invalid project Skill path: ${skill.path}`));
            continue;
          }
          if (!(await exists(join(targetDir, skill.path)))) results.push(result('error', 'skills-incomplete', skill.path));
          if (manifest.components?.codex) {
            const discoveryPath = `.agents/${skill.path}`;
            if (!(await exists(join(targetDir, discoveryPath)))) results.push(result('error', 'codex-skills-incomplete', discoveryPath));
          }
        }
        if (manifest.components?.claude) {
          for (const skill of index.skills.filter((item) => item.status === 'core')) {
            const adapterPath = `.claude/skills/${skill.id}/SKILL.md`;
            if (!(await exists(join(targetDir, adapterPath)))) results.push(result('error', 'claude-skills-incomplete', adapterPath));
          }
        }
      } catch (error) {
        results.push(result('error', 'skills-index-invalid', error.message));
      }
    }
  }

  if (!results.length) results.push(result('ok', 'healthy', 'SAC installation is healthy.'));
  return { ok: !results.some((item) => item.level === 'error'), results, manifest };
}
