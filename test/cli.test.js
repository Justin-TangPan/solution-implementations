import assert from 'node:assert/strict';
import { access, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { diagnose } from '../src/doctor.js';
import { availablePractices, executeInstall, updateInstalled } from '../src/installer.js';

async function fixture(t) {
  const dir = await mkdtemp(join(tmpdir(), 'sac-cli-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  return dir;
}

test('formal practices come from project.config.json', async () => {
  const config = JSON.parse(await readFile('project.config.json', 'utf8'));
  assert.deepEqual(await availablePractices(), config.formal.practices);
});

test('init installs Codex, Claude Code, skills, and manifest', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: ['codex', 'claude', 'skills'] });
  assert.equal(result.manifest.components.codex, true);
  assert.equal(result.manifest.components.claude, true);
  assert.equal(result.manifest.components.skills, true);
  assert.match(await readFile(join(dir, 'AGENTS.md'), 'utf8'), /<!-- SAC:START -->/);
  assert.match(await readFile(join(dir, '.codex/agents/builder.toml'), 'utf8'), /name = "sac_builder"/);
  assert.match(await readFile(join(dir, 'skills/sac-quality/SKILL.md'), 'utf8'), /name: sac-quality/);
  assert.match(await readFile(join(dir, '.agents/skills/sac-quality/SKILL.md'), 'utf8'), /name: sac-quality/);
  assert.match(await readFile(join(dir, '.claude/CLAUDE.md'), 'utf8'), /SAC project instructions/);
  assert.match(await readFile(join(dir, '.claude/agents/builder.md'), 'utf8'), /name: builder/);
  assert.match(await readFile(join(dir, '.claude/skills/sac-quality/SKILL.md'), 'utf8'), /name: sac-quality/);
  assert.match(await readFile(join(dir, '.claude/agents/sac-architect.json'), 'utf8'), /sac-architect/);
  assert.match(await readFile(join(dir, '.claude/workflows/sac-full-pipeline.js'), 'utf8'), /sac-full-pipeline/);
  assert.match(await readFile(join(dir, 'docs/coding-agent-adapters.md'), 'utf8'), /SAC Core/);
  assert.match(await readFile(join(dir, '.sac/tooling/scripts/document_pipeline/__main__.py'), 'utf8'), /cli/);
  assert.match(await readFile(join(dir, '.sac/tooling/scripts/tests/runner.py'), 'utf8'), /SAC Solution Test Report/);
  const installedTemplate = await readFile(join(dir, '.sac/tooling/scripts/document_pipeline/templates/company-solution-guide.docx'));
  const sourceTemplate = await readFile(join(process.cwd(), 'scripts/document_pipeline/templates/company-solution-guide.docx'));
  assert.deepEqual(installedTemplate, sourceTemplate);
  const index = JSON.parse(await readFile(join(dir, 'skills-index.json'), 'utf8'));
  assert.ok(index.skills.some((skill) => skill.id === 'sac-testing'));
  const persisted = JSON.parse(await readFile(join(dir, '.sac/manifest.json'), 'utf8'));
  assert.equal(persisted.schemaVersion, 1);
  assert.ok(persisted.managedFiles['.codex/agents/architect.toml']);
  assert.ok(persisted.managedFiles['.claude/CLAUDE.md']);
});

test('init merges AGENTS.md idempotently and preserves user content', async (t) => {
  const dir = await fixture(t);
  await writeFile(join(dir, 'AGENTS.md'), '# User rules\n\nKeep this.\n');
  await executeInstall({ targetDir: dir, components: ['codex'] });
  await executeInstall({ targetDir: dir, components: ['codex'] });
  const content = await readFile(join(dir, 'AGENTS.md'), 'utf8');
  assert.match(content, /Keep this\./);
  assert.equal(content.match(/<!-- SAC:START -->/g)?.length, 1);
  assert.equal(content.match(/<!-- SAC:END -->/g)?.length, 1);
});

test('Claude install merges CLAUDE.md idempotently and preserves user content', async (t) => {
  const dir = await fixture(t);
  await mkdir(join(dir, '.claude'), { recursive: true });
  await writeFile(join(dir, '.claude/CLAUDE.md'), '# User Claude rules\n\nKeep this.\n');
  await executeInstall({ targetDir: dir, components: ['claude'] });
  await executeInstall({ targetDir: dir, components: ['claude'] });
  const content = await readFile(join(dir, '.claude/CLAUDE.md'), 'utf8');
  assert.match(content, /Keep this\./);
  assert.equal(content.match(/<!-- SAC:START -->/g)?.length, 1);
  assert.equal(content.match(/<!-- SAC:END -->/g)?.length, 1);
});

test('Codex-only and Claude-only installs are self-contained and isolated', async (t) => {
  const codexDir = await fixture(t);
  const claudeDir = await fixture(t);

  const codex = await executeInstall({ targetDir: codexDir, components: ['codex'] });
  assert.equal(codex.manifest.components.codex, true);
  assert.equal(codex.manifest.components.skills, true);
  await access(join(codexDir, '.agents/skills/sac-project/SKILL.md'));
  await assert.rejects(access(join(codexDir, '.claude/CLAUDE.md')));
  assert.equal((await diagnose(codexDir)).ok, true);

  const claude = await executeInstall({ targetDir: claudeDir, components: ['claude'] });
  assert.equal(claude.manifest.components.claude, true);
  assert.equal(claude.manifest.components.skills, true);
  await access(join(claudeDir, 'skills/sac-project/SKILL.md'));
  await access(join(claudeDir, '.claude/skills/sac-project/SKILL.md'));
  await assert.rejects(access(join(claudeDir, '.codex/config.toml')));
  await assert.rejects(access(join(claudeDir, '.agents/skills/sac-project/SKILL.md')));
  assert.equal((await diagnose(claudeDir)).ok, true);
});

test('all install is an explicit alias for the dual-platform init set', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: ['all'] });
  assert.equal(result.manifest.components.codex, true);
  assert.equal(result.manifest.components.claude, true);
  assert.equal(result.manifest.components.skills, true);
  assert.equal((await diagnose(dir)).ok, true);
});

test('update protects user-modified managed files', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex'] });
  const agent = join(dir, '.codex/agents/architect.toml');
  await writeFile(agent, `${await readFile(agent, 'utf8')}\n# user edit\n`);
  const result = await updateInstalled({ targetDir: dir });
  assert.ok(result.actions.some((item) => item.action === 'conflict' && item.path === '.codex/agents/architect.toml'));
  assert.match(await readFile(agent, 'utf8'), /# user edit/);
  assert.match(await readFile(`${agent}.sac-new`, 'utf8'), /name = "sac_architect"/);
});

test('update protects user-modified Claude Subagents with .sac-new', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['claude'] });
  const agent = join(dir, '.claude/agents/builder.md');
  await writeFile(agent, `${await readFile(agent, 'utf8')}\n# user edit\n`);
  const result = await updateInstalled({ targetDir: dir });
  assert.ok(result.actions.some((item) => item.action === 'conflict' && item.path === '.claude/agents/builder.md'));
  assert.match(await readFile(agent, 'utf8'), /# user edit/);
  assert.match(await readFile(`${agent}.sac-new`, 'utf8'), /name: builder/);
});

test('update removes obsolete managed skills but preserves modified ones', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['skills'] });
  const manifestPath = join(dir, '.sac/manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  for (const name of ['obsolete', 'modified']) {
    const path = `skills/${name}/SKILL.md`;
    const content = name === 'obsolete' ? 'old\n' : 'user edit\n';
    await mkdir(join(dir, 'skills', name), { recursive: true });
    await writeFile(join(dir, path), content);
    manifest.managedFiles[path] = {
      checksum: name === 'obsolete'
        ? '01d09d19c2139a46aebfb577780d123d7396e97201bc7ead210a2ebff8239dee'
        : 'outdated',
      component: 'skills',
      mode: 'managed',
    };
  }
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  const result = await updateInstalled({ targetDir: dir });
  await assert.rejects(access(join(dir, 'skills/obsolete/SKILL.md')));
  assert.equal(await readFile(join(dir, 'skills/modified/SKILL.md'), 'utf8'), 'user edit\n');
  assert.ok(result.actions.some((item) => item.action === 'remove-stale'));
  assert.ok(result.actions.some((item) => item.action === 'preserve-stale'));
});

test('update migrates legacy managed Codex skills to .agents/skills', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex'] });
  const manifestPath = join(dir, '.sac/manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const legacy = '.codex/skills/sac-testing/SKILL.md';
  const content = await readFile(join(dir, '.agents/skills/sac-testing/SKILL.md'));
  await mkdir(join(dir, '.codex/skills/sac-testing'), { recursive: true });
  await writeFile(join(dir, legacy), content);
  manifest.managedFiles[legacy] = {
    checksum: manifest.managedFiles['.agents/skills/sac-testing/SKILL.md'].checksum,
    component: 'skills',
    mode: 'managed',
  };
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);

  const result = await updateInstalled({ targetDir: dir });
  await assert.rejects(access(join(dir, legacy)));
  assert.ok(result.actions.some((item) => item.action === 'remove-stale' && item.path === legacy));
});

test('update rejects stale managed paths outside the project', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['skills'] });
  const manifestPath = join(dir, '.sac/manifest.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  manifest.managedFiles['../outside'] = { checksum: 'irrelevant', component: 'skills', mode: 'managed' };
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  await assert.rejects(updateInstalled({ targetDir: dir }), /Invalid managed path outside the project/);
});

test('doctor reports a healthy initialized project', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex', 'claude', 'skills'] });
  const report = await diagnose(dir);
  assert.equal(report.ok, true);
  assert.deepEqual(report.results, [{ level: 'ok', code: 'healthy', message: 'SAC installation is healthy.' }]);
});

test('doctor detects a missing SAC AGENTS block', async (t) => {
  const dir = await fixture(t);
  await executeInstall({ targetDir: dir, components: ['codex'] });
  await writeFile(join(dir, 'AGENTS.md'), '# User rules\n');
  const report = await diagnose(dir);
  assert.equal(report.ok, false);
  assert.ok(report.results.some((item) => item.code === 'agents-block-invalid'));
});

test('practice installation rejects non-formal names', async (t) => {
  const dir = await fixture(t);
  await assert.rejects(
    executeInstall({ targetDir: dir, components: [], practices: ['missing'] }),
    /Unknown or non-formal practice/,
  );
});

test('formal practice installation records and copies the selected practice', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: [], practices: ['openjiuwen'] });
  assert.deepEqual(result.manifest.components.practices, ['openjiuwen']);
  for (const template of [
    'practices/openjiuwen/cn/cn-north-4/agent-studio/deploying-openjiuwen.tf',
    'practices/openjiuwen/cn/cn-north-4/jiuwenswarm/deploying-jiuwenswarm_v7.tf',
  ]) {
    assert.match(await readFile(join(dir, template), 'utf8'), /resource\s+"huaweicloud_compute_instance"/);
  }
});

test('Codex install preserves a pre-existing config owned by the host project', async (t) => {
  const dir = await fixture(t);
  const configDir = join(dir, '.codex');
  await mkdir(configDir, { recursive: true });
  await writeFile(join(configDir, 'config.toml'), 'model_reasoning_effort = "medium"\n');
  const result = await executeInstall({ targetDir: dir, components: ['codex'] });
  assert.equal(await readFile(join(configDir, 'config.toml'), 'utf8'), 'model_reasoning_effort = "medium"\n');
  assert.ok(result.actions.some((item) => item.action === 'preserve' && item.path === '.codex/config.toml'));
});

test('dry run does not write files', async (t) => {
  const dir = await fixture(t);
  const result = await executeInstall({ targetDir: dir, components: ['codex'], dryRun: true });
  assert.ok(result.actions.length > 0);
  await assert.rejects(readFile(join(dir, '.sac/manifest.json')), /ENOENT/);
});
