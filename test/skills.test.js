import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import test from 'node:test';

const config = JSON.parse(await readFile('project.config.json', 'utf8'));
const capabilities = config.agent_capabilities;

function frontmatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(match, 'missing frontmatter');
  return Object.fromEntries(match[1].split('\n').filter(Boolean).map((line) => {
    const separator = line.indexOf(':');
    return [line.slice(0, separator), line.slice(separator + 1).trim()];
  }));
}

test('project.config.json defines core roles and skills', async () => {
  assert.deepEqual(capabilities.supported_runtimes, ['claude-code']);
  assert.deepEqual(Object.keys(capabilities.core_roles), ['architect', 'builder', 'reviewer']);
  assert.ok(capabilities.skills.core.length >= 5, 'at least 5 core skills');
  assert.ok(capabilities.skills.optional.length >= 1, 'at least 1 optional skill');
});

test('canonical skills exist on disk with valid frontmatter', async () => {
  const allSkillIds = [...capabilities.skills.core, ...capabilities.skills.optional];
  const skillDirs = (await readdir('skills', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory() && entry.name !== 'reference')
    .map((entry) => entry.name)
    .sort();

  for (const id of allSkillIds) {
    assert.ok(skillDirs.includes(id), `skills/${id}/ directory missing`);
    const source = await readFile(`skills/${id}/SKILL.md`, 'utf8');
    const fm = frontmatter(source);
    assert.ok(fm.name, `${id} missing name in frontmatter`);
    assert.ok(fm.description, `${id} missing description in frontmatter`);
    assert.doesNotMatch(source, /Codex|\.codex/, `${id} contains Codex-specific rules`);
  }
});

test('Claude Code adapter skills mirror canonical skills', async () => {
  const allSkillIds = [...capabilities.skills.core, ...capabilities.skills.optional];
  const claudeSkills = (await readdir('.claude/skills', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();

  for (const id of allSkillIds) {
    assert.ok(claudeSkills.includes(id), `.claude/skills/${id}/ wrapper missing`);
  }
});
