import { readFile, readdir, rm } from 'node:fs/promises';
import { isAbsolute, join, relative, resolve, sep } from 'node:path';
import {
  AGENTS_END,
  AGENTS_START,
  CLAUDE_END,
  CLAUDE_START,
  MANIFEST_SCHEMA_VERSION,
  PACKAGE_ROOT,
} from './constants.js';
import { exists, readText, sha256, toPosix, writeText } from './fs-utils.js';
import { loadManifest, saveManifest } from './manifest.js';

const packageData = JSON.parse(await readFile(join(PACKAGE_ROOT, 'package.json'), 'utf8'));
export const packageVersion = packageData.version;
export const contentVersion = packageData.sac.contentVersion;

async function walkFiles(root) {
  const output = [];
  if (!(await exists(root))) return output;
  for (const entry of await readdir(root, { withFileTypes: true })) {
    const path = join(root, entry.name);
    if (entry.isDirectory()) output.push(...(await walkFiles(path)));
    else if (entry.isFile()) output.push(path);
  }
  return output;
}

function record(manifest, relativePath, content, component, mode = 'managed') {
  manifest.managedFiles[toPosix(relativePath)] = {
    checksum: sha256(content),
    component,
    mode,
  };
}

async function installManagedFile({ source, destination, relativePath, component, manifest, dryRun, force, actions }) {
  const incoming = await readFile(source);
  if (!(await exists(destination))) {
    await writeText(destination, incoming, { dryRun });
    record(manifest, relativePath, incoming, component);
    actions.push({ action: 'create', path: relativePath });
    return;
  }

  const current = await readFile(destination);
  if (current.equals(incoming)) {
    record(manifest, relativePath, incoming, component);
    actions.push({ action: 'unchanged', path: relativePath });
    return;
  }

  const previous = manifest.managedFiles[toPosix(relativePath)];
  const safeToReplace = force || (previous?.mode === 'managed' && previous.checksum === sha256(current));
  if (safeToReplace) {
    await writeText(destination, incoming, { dryRun });
    record(manifest, relativePath, incoming, component);
    actions.push({ action: force ? 'replace-forced' : 'update', path: relativePath });
    return;
  }

  const candidate = `${destination}.sac-new`;
  await writeText(candidate, incoming, { dryRun });
  actions.push({ action: 'conflict', path: relativePath, candidate: `${relativePath}.sac-new` });
}

async function installTree({ sourceRoot, targetRoot, targetDir, component, manifest, dryRun, force, actions, filter }) {
  for (const source of await walkFiles(sourceRoot)) {
    const local = relative(sourceRoot, source);
    if (filter && !filter(local)) continue;
    const destination = join(targetRoot, local);
    const relativePath = relative(targetDir, destination);
    await installManagedFile({
      source,
      destination,
      relativePath,
      component,
      manifest,
      dryRun,
      force,
      actions,
    });
  }
}

function mergeMarkedBlock(current, block, startMarker, endMarker, label) {
  const normalized = block.trim();
  const replacement = `${startMarker}\n${normalized}\n${endMarker}`;
  const start = current.indexOf(startMarker);
  const end = current.indexOf(endMarker);
  if (start === -1 && end === -1) {
    const prefix = current.trimEnd();
    return `${prefix}${prefix ? '\n\n' : ''}${replacement}\n`;
  }
  if (start === -1 || end === -1 || end < start) {
    throw new Error(`${label} contains an incomplete SAC marker block`);
  }
  return `${current.slice(0, start)}${replacement}${current.slice(end + endMarker.length)}`;
}

async function installAgentsBlock(targetDir, manifest, options, actions) {
  const source = join(PACKAGE_ROOT, 'templates/codex/AGENTS.block.md');
  const destination = join(targetDir, 'AGENTS.md');
  const current = (await exists(destination)) ? await readText(destination) : '';
  const merged = mergeMarkedBlock(current, await readText(source), AGENTS_START, AGENTS_END, 'AGENTS.md');
  await writeText(destination, merged, options);
  record(manifest, 'AGENTS.md', merged, 'codex', 'merge-block');
  actions.push({ action: current ? 'merge' : 'create', path: 'AGENTS.md' });
}

async function installCodexConfig(targetDir, manifest, options, actions) {
  const destination = join(targetDir, '.codex/config.toml');
  const source = join(PACKAGE_ROOT, '.codex/config.toml');
  if ((await exists(destination)) && !manifest.managedFiles['.codex/config.toml']) {
    actions.push({ action: 'preserve', path: '.codex/config.toml', note: 'existing project config' });
    return;
  }
  await installManagedFile({
    source,
    destination,
    relativePath: '.codex/config.toml',
    component: 'codex',
    manifest,
    ...options,
    actions,
  });
}

export async function installCodex(targetDir, manifest, options, actions) {
  await installAgentsBlock(targetDir, manifest, options, actions);
  await installCodexConfig(targetDir, manifest, options, actions);
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, '.codex/agents'),
    targetRoot: join(targetDir, '.codex/agents'),
    targetDir,
    component: 'codex', manifest, ...options, actions,
  });
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, '.codex/workflows'),
    targetRoot: join(targetDir, '.codex/workflows'),
    targetDir,
    component: 'codex', manifest, ...options, actions,
  });
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'skills'),
    targetRoot: join(targetDir, '.agents/skills'),
    targetDir,
    component: 'codex', manifest, ...options, actions,
    filter: (path) => !path.endsWith('skill-report.json'),
  });
  manifest.components.codex = true;
}

async function installClaudeMemory(targetDir, manifest, options, actions) {
  const relativePath = '.claude/CLAUDE.md';
  const source = join(PACKAGE_ROOT, relativePath);
  const destination = join(targetDir, relativePath);
  const incoming = await readText(source);
  const start = incoming.indexOf(CLAUDE_START);
  const end = incoming.indexOf(CLAUDE_END);
  if (start === -1 || end === -1 || end < start) throw new Error('Packaged CLAUDE.md has an invalid SAC marker block');
  const block = incoming.slice(start + CLAUDE_START.length, end);
  const current = (await exists(destination)) ? await readText(destination) : '';
  const previous = manifest.managedFiles[relativePath];
  const base = previous?.mode === 'managed' && previous.checksum === sha256(current) ? '' : current;
  const merged = mergeMarkedBlock(base, block, CLAUDE_START, CLAUDE_END, 'CLAUDE.md');
  await writeText(destination, merged, options);
  record(manifest, relativePath, merged, 'claude', 'merge-block');
  actions.push({ action: current ? 'merge' : 'create', path: relativePath });
}

export async function installClaude(targetDir, manifest, options, actions) {
  await installClaudeMemory(targetDir, manifest, options, actions);
  for (const directory of ['agents', 'skills', 'workflows']) {
    await installTree({
      sourceRoot: join(PACKAGE_ROOT, '.claude', directory),
      targetRoot: join(targetDir, '.claude', directory),
      targetDir,
      component: 'claude', manifest, ...options, actions,
      filter: directory === 'skills'
        ? (path) => /^(sac-|query-huawei-cloud-prices\/)/.test(toPosix(path))
        : undefined,
    });
  }
  manifest.components.claude = true;
}

export async function installSkills(targetDir, manifest, options, actions) {
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'skills'),
    targetRoot: join(targetDir, 'skills'),
    targetDir,
    component: 'skills', manifest, ...options, actions,
    filter: (path) => !path.endsWith('skill-report.json'),
  });
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'docs/contracts'),
    targetRoot: join(targetDir, 'docs/contracts'),
    targetDir,
    component: 'skills', manifest, ...options, actions,
  });
  for (const name of [
    'agent-skill-migration.md',
    'coding-agent-adapters.md',
    'project-boundaries.md',
    'project-state.md',
    'source-of-truth.md',
  ]) {
    await installManagedFile({
      source: join(PACKAGE_ROOT, 'docs', name),
      destination: join(targetDir, 'docs', name),
      relativePath: `docs/${name}`,
      component: 'skills', manifest, ...options, actions,
    });
  }
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'reference/docs'),
    targetRoot: join(targetDir, 'reference/docs'),
    targetDir,
    component: 'skills', manifest, ...options, actions,
  });
  const toolingFilter = (path) => !path.includes('__pycache__') && !path.endsWith('.pyc');
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'scripts/document_pipeline'),
    targetRoot: join(targetDir, '.sac/tooling/scripts/document_pipeline'),
    targetDir,
    component: 'skills', manifest, ...options, actions,
    filter: toolingFilter,
  });
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'scripts/tests'),
    targetRoot: join(targetDir, '.sac/tooling/scripts/tests'),
    targetDir,
    component: 'skills', manifest, ...options, actions,
    filter: toolingFilter,
  });
  await installManagedFile({
    source: join(PACKAGE_ROOT, 'requirements-document-pipeline.txt'),
    destination: join(targetDir, '.sac/tooling/requirements-document-pipeline.txt'),
    relativePath: '.sac/tooling/requirements-document-pipeline.txt',
    component: 'skills', manifest, ...options, actions,
  });
  await installManagedFile({
    source: join(PACKAGE_ROOT, 'skills-index.json'),
    destination: join(targetDir, 'skills-index.json'),
    relativePath: 'skills-index.json',
    component: 'skills', manifest, ...options, actions,
  });
  await installManagedFile({
    source: join(PACKAGE_ROOT, 'project.config.json'),
    destination: join(targetDir, '.sac/project.config.json'),
    relativePath: '.sac/project.config.json',
    component: 'skills', manifest, ...options, actions,
  });
  manifest.components.skills = true;
}

async function pruneStaleManagedFiles(targetDir, manifest, updatedComponents, activePaths, actions, { dryRun }) {
  for (const [path, metadata] of Object.entries(manifest.managedFiles)) {
    if (!updatedComponents.has(metadata.component) || activePaths.has(path)) continue;
    const absolute = resolve(targetDir, path);
    const local = relative(resolve(targetDir), absolute);
    if (local === '..' || local.startsWith(`..${sep}`) || isAbsolute(local)) {
      throw new Error(`Invalid managed path outside the project: ${path}`);
    }
    const present = await exists(absolute);
    const unchanged = present && metadata.mode === 'managed'
      && metadata.checksum === sha256(await readFile(absolute));
    if (unchanged) {
      if (!dryRun) await rm(absolute);
      actions.push({ action: 'remove-stale', path });
    } else if (!present) {
      actions.push({ action: 'forget-stale', path, note: 'already absent' });
    } else {
      actions.push({ action: 'preserve-stale', path, note: 'modified or merged user content' });
    }
    if (!dryRun) delete manifest.managedFiles[path];
  }
}

export async function availablePractices() {
  const config = JSON.parse(await readText(join(PACKAGE_ROOT, 'project.config.json')));
  return config.formal.practices;
}

export async function installPractice(name, targetDir, manifest, options, actions) {
  const available = await availablePractices();
  if (!available.includes(name)) {
    throw new Error(`Unknown or non-formal practice "${name}". Available: ${available.join(', ')}`);
  }
  await installTree({
    sourceRoot: join(PACKAGE_ROOT, 'practices', name),
    targetRoot: join(targetDir, 'practices', name),
    targetDir,
    component: `practice:${name}`, manifest, ...options, actions,
  });
  if (!manifest.components.practices.includes(name)) manifest.components.practices.push(name);
  manifest.components.practices.sort();
}

export async function executeInstall({ targetDir = process.cwd(), components, practices = [], dryRun = false, force = false }) {
  components = [...new Set(components.flatMap((component) => {
    if (component === 'all') return ['codex', 'claude', 'skills'];
    if (component === 'codex' || component === 'claude') return [component, 'skills'];
    return [component];
  }))];
  const manifest = await loadManifest(targetDir, packageVersion, contentVersion);
  const actions = [];
  const options = { dryRun, force };
  if (components.includes('codex')) await installCodex(targetDir, manifest, options, actions);
  if (components.includes('claude')) await installClaude(targetDir, manifest, options, actions);
  if (components.includes('skills')) await installSkills(targetDir, manifest, options, actions);
  for (const practice of practices) await installPractice(practice, targetDir, manifest, options, actions);
  const updatedComponents = new Set([
    ...components,
    ...practices.map((name) => `practice:${name}`),
  ]);
  await pruneStaleManagedFiles(
    targetDir,
    manifest,
    updatedComponents,
    new Set(actions.map((item) => toPosix(item.path))),
    actions,
    options,
  );
  manifest.schemaVersion = MANIFEST_SCHEMA_VERSION;
  manifest.packageVersion = packageVersion;
  manifest.contentVersion = contentVersion;
  manifest.updatedAt = new Date().toISOString();
  await saveManifest(targetDir, manifest, { dryRun });
  return { manifest, actions, dryRun };
}

export async function updateInstalled({ targetDir = process.cwd(), dryRun = false, force = false }) {
  const manifest = await loadManifest(targetDir, packageVersion, contentVersion);
  const components = [];
  if (manifest.components.codex) components.push('codex');
  if (manifest.components.claude) components.push('claude');
  if (manifest.components.skills) components.push('skills');
  if (!components.length && !manifest.components.practices.length) {
    throw new Error('Nothing to update. Run "sac init" first.');
  }
  return executeInstall({
    targetDir,
    components,
    practices: manifest.components.practices,
    dryRun,
    force,
  });
}
