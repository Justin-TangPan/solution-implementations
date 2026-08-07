import assert from 'node:assert/strict';
import { access, readFile, readdir } from 'node:fs/promises';
import test from 'node:test';

const config = JSON.parse(await readFile('project.config.json', 'utf8'));
const capabilities = config.agent_capabilities;
const core = capabilities.skills.core;

function frontmatter(source) {
  const match = source.match(/^---\n([\s\S]*?)\n---/);
  assert.ok(match, 'missing YAML frontmatter');
  const values = {};
  let list;
  for (const line of match[1].split('\n')) {
    const item = line.match(/^\s+-\s+(.+)$/);
    if (item && list) values[list].push(item[1]);
    else {
      const field = line.match(/^([a-z][A-Za-z-]*):(?:\s*(.*))?$/);
      if (!field) continue;
      list = field[2] ? undefined : field[1];
      values[field[1]] = field[2] || [];
    }
  }
  return values;
}

function wordSet(value) {
  return new Set(value.toLowerCase().match(/[a-z0-9_-]+/g) ?? []);
}

function similarity(left, right) {
  const intersection = [...left].filter((word) => right.has(word)).length;
  return intersection / new Set([...left, ...right]).size;
}

test('Claude project memory is lightweight and Core wrappers are distinct thin adapters', async () => {
  const memory = await readFile('.claude/CLAUDE.md', 'utf8');
  assert.ok(memory.split('\n').length < 100);
  assert.equal(memory.match(/<!-- SAC:START -->/g)?.length, 1);
  assert.equal(memory.match(/<!-- SAC:END -->/g)?.length, 1);

  const adapterDirs = (await readdir('.claude/skills', { withFileTypes: true }))
    .filter((entry) => entry.isDirectory() && [...core, ...capabilities.skills.optional].includes(entry.name))
    .map((entry) => entry.name)
    .sort();
  assert.deepEqual(adapterDirs, [...core, ...capabilities.skills.optional].sort());

  const descriptions = [];
  for (const id of core) {
    const source = await readFile(`.claude/skills/${id}/SKILL.md`, 'utf8');
    const metadata = frontmatter(source);
    assert.equal(metadata.name, id);
    assert.match(source, new RegExp(`skills/${id}/SKILL\\.md`));
    assert.ok(source.split('\n').length < 16, `${id} wrapper duplicates business rules`);
    descriptions.push([id, wordSet(metadata.description)]);
  }
  for (let left = 0; left < descriptions.length; left += 1) {
    for (let right = left + 1; right < descriptions.length; right += 1) {
      assert.ok(similarity(descriptions[left][1], descriptions[right][1]) < 0.55,
        `${descriptions[left][0]} and ${descriptions[right][0]} descriptions overlap too much`);
    }
  }
});

test('Claude Subagents preload only their two mandatory Core Skills', async () => {
  const names = new Set();
  for (const [role, definition] of Object.entries(capabilities.core_roles)) {
    const source = await readFile(`.claude/agents/${role}.md`, 'utf8');
    const metadata = frontmatter(source);
    assert.equal(metadata.name, role);
    assert.ok(!names.has(metadata.name), `duplicate Claude agent ${metadata.name}`);
    names.add(metadata.name);
    assert.deepEqual(metadata.skills, definition.mandatory_skills);
    assert.equal(metadata.skills.length, 2);
  }
  const builder = await readFile('.claude/agents/builder.md', 'utf8');
  assert.match(builder, /sac-documentation.*on demand|Load `sac-documentation` on demand/s);

  for (const id of capabilities.skills.optional) {
    const source = await readFile(`.claude/skills/${id}/SKILL.md`, 'utf8');
    assert.match(source, new RegExp(`skills/${id}/SKILL\\.md`));
    for (const role of Object.keys(capabilities.core_roles)) {
      assert.doesNotMatch(await readFile(`.claude/agents/${role}.md`, 'utf8'), new RegExp(`^\\s+- ${id}$`, 'm'));
    }
  }
  for (const id of Object.keys(capabilities.skills.deprecated)) await assert.rejects(access(`.claude/skills/${id}/SKILL.md`));
});

test('legacy Claude JSON and workflow DSL remain explicit compatibility assets', async () => {
  for (const file of (await readdir('.claude/agents')).filter((name) => name.endsWith('.json'))) {
    const legacy = JSON.parse(await readFile(`.claude/agents/${file}`, 'utf8'));
    assert.equal(legacy.status, 'deprecated');
    const replacements = [...legacy.replacement.matchAll(/\.claude\/agents\/(architect|builder|reviewer)\.md/g)];
    assert.ok(replacements.length >= 1, `${file} has no native replacement`);
    for (const replacement of replacements) await access(replacement[0]);
  }
  for (const file of (await readdir('.claude/workflows')).filter((name) => name.endsWith('.js'))) {
    const source = await readFile(`.claude/workflows/${file}`, 'utf8');
    assert.match(source, /status: 'deprecated'/);
    assert.match(source, /runtime: 'legacy-custom-workflow-dsl'/);
  }
});

test('five shared routing cases preserve the same SAC decisions in both adapters', async () => {
  const cases = [
    { task: '修改 LiteLLM Terraform 的一个变量描述', flow: 'small-change', roles: ['builder'], trigger: ['sac-implementation', /variables/] },
    { task: '检查这个方案有没有安全问题', flow: 'review-practice', roles: ['reviewer'], trigger: ['sac-quality', /security audit/] },
    { task: '从单机改成高可用', flow: 'architecture-change', roles: ['architect', 'builder', 'reviewer'], trigger: ['sac-architecture', /high availability/] },
    { task: '增加部署文档中的参数说明', flow: 'documentation-change', roles: ['builder'], trigger: ['sac-documentation', /parameter/] },
    { task: '把新的开源项目做成 Solution Practice', flow: 'new-practice', roles: ['architect', 'builder', 'reviewer', 'builder'], trigger: ['sac-architecture', /new Practice/] },
  ];

  for (const route of cases) {
    assert.deepEqual(capabilities.task_flows[route.flow], route.roles, route.task);
    const [skill, pattern] = route.trigger;
    const claude = frontmatter(await readFile(`.claude/skills/${skill}/SKILL.md`, 'utf8'));
    assert.match(claude.description, pattern, `${route.task} cannot match ${skill}`);
    await access(`.agents/skills/${skill}/SKILL.md`);
    for (const role of new Set(route.roles)) {
      await access(`.codex/agents/${role}.toml`);
      await access(`.claude/agents/${role}.md`);
    }
  }

  const claudeMemory = await readFile('.claude/CLAUDE.md', 'utf8');
  assert.match(claudeMemory, /Terraform field description is implementation work, not documentation work/);
  assert.match(claudeMemory, /Never select compatibility names such as `sac-security` or `sac-testing`/);
  assert.match(claudeMemory, /Do not add Optional `sac-deep-search` unless/);
  assert.match(await readFile('.claude/skills/sac-deep-search/SKILL.md', 'utf8'), /disable-model-invocation: true/);
});

test('adapter Skill and role references are not dangling', async () => {
  const sources = [];
  for (const directory of ['.codex/agents', '.codex/workflows', '.claude/agents', '.claude/skills']) {
    for (const file of await readdir(directory, { recursive: true })) {
      if (/\.(md|toml|json)$/.test(file)) sources.push(await readFile(`${directory}/${file}`, 'utf8'));
    }
  }
  for (const source of sources) {
    for (const match of source.matchAll(/skills\/(sac-[a-z0-9-]+)\/SKILL\.md/g)) {
      await access(`skills/${match[1]}/SKILL.md`);
    }
  }
});
