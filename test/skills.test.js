import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import test from 'node:test';

const config = JSON.parse(await readFile('project.config.json', 'utf8'));
const index = JSON.parse(await readFile('skills-index.json', 'utf8'));
const capabilities = config.agent_capabilities;

function frontmatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(match, 'missing frontmatter');
  return Object.fromEntries(match[1].split('\n').filter(Boolean).map((line) => {
    const separator = line.indexOf(':');
    return [line.slice(0, separator), line.slice(separator + 1).trim()];
  }));
}

test('project.config.json owns the capability model and skills-index mirrors it', async () => {
  assert.deepEqual(capabilities.supported_runtimes, ['codex', 'claude-code']);
  assert.deepEqual(Object.keys(capabilities.core_roles), ['architect', 'builder', 'reviewer']);

  const expectedStatuses = new Map([
    ...capabilities.skills.core.map((id) => [id, 'core']),
    ...capabilities.skills.optional.map((id) => [id, 'optional']),
    ...Object.keys(capabilities.skills.compatibility).map((id) => [id, 'compatibility']),
    ...Object.keys(capabilities.skills.deprecated).map((id) => [id, 'deprecated']),
  ]);
  assert.equal(expectedStatuses.size, index.skills.length);
  for (const skill of index.skills) assert.equal(skill.status, expectedStatuses.get(skill.id), skill.id);

  for (const [role, definition] of Object.entries(capabilities.core_roles)) {
    assert.deepEqual(index.agent_skill_bindings[role], {
      mandatory: definition.mandatory_skills,
      conditional: definition.conditional_skills,
    });
  }
});

test('canonical Core is portable and compatibility Skills stay thin', async () => {
  const ids = new Set(index.skills.map((skill) => skill.id));
  const skillDirs = (await readdir('skills', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory() && entry.name !== 'reference')
    .map((entry) => entry.name)
    .sort();
  assert.deepEqual([...ids].sort(), skillDirs);

  for (const id of capabilities.skills.core) {
    const source = await readFile(`skills/${id}/SKILL.md`, 'utf8');
    assert.deepEqual(Object.keys(frontmatter(source)), ['name', 'description']);
    assert.ok(source.split('\n').length <= 180, `${id} is too large for progressive disclosure`);
    assert.doesNotMatch(source, /Codex|Claude|Anthropic|\.codex|\.claude/, `${id} contains Runtime-specific rules`);
  }

  const aliases = {
    ...capabilities.skills.compatibility,
    ...Object.fromEntries(Object.entries(capabilities.skills.deprecated).map(([id, target]) => [id, [target]])),
  };
  for (const [id, targets] of Object.entries(aliases)) {
    const source = await readFile(`skills/${id}/SKILL.md`, 'utf8');
    assert.ok(source.split('\n').length <= 20, `${id} duplicates Core content`);
    for (const target of targets) assert.match(source, new RegExp(`skills/${target}/SKILL\\.md`), `${id} omits ${target}`);
  }
});

test('Codex native roles bind exactly the configured Core Skills', async () => {
  const runtimeNames = { architect: 'sac_architect', builder: 'sac_builder', reviewer: 'sac_reviewer' };
  for (const [role, definition] of Object.entries(capabilities.core_roles)) {
    const contract = await readFile(`.codex/agents/${role}.toml`, 'utf8');
    assert.match(contract, new RegExp(`name = "${runtimeNames[role]}"`));
    for (const id of definition.mandatory_skills) assert.match(contract, new RegExp(id), `${role} omits ${id}`);
  }

  const codexFiles = [
    'AGENTS.md',
    'templates/codex/AGENTS.block.md',
    ...((await readdir('.codex/agents')).map((name) => `.codex/agents/${name}`)),
    ...((await readdir('.codex/workflows')).map((name) => `.codex/workflows/${name}`)),
  ];
  const source = (await Promise.all(codexFiles.map((path) => readFile(path, 'utf8')))).join('\n');
  assert.doesNotMatch(source, /\.claude\//, 'Codex Adapter depends on Claude assets');
});
