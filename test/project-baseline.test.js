import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
import test from 'node:test';

const config = JSON.parse(await readFile('project.config.json', 'utf8'));
const packageData = JSON.parse(await readFile('package.json', 'utf8'));

test('release version is synchronized with locks, Web, and changelog', async () => {
  const [lock, webPackage, webLock, changelog] = await Promise.all([
    readFile('package-lock.json', 'utf8').then(JSON.parse),
    readFile('web/package.json', 'utf8').then(JSON.parse),
    readFile('web/package-lock.json', 'utf8').then(JSON.parse),
    readFile('CHANGELOG.md', 'utf8'),
  ]);
  for (const metadata of [lock, lock.packages[''], webPackage, webLock, webLock.packages['']]) {
    assert.equal(metadata.version, packageData.version);
  }
  assert.ok(changelog.includes(`## v${packageData.version} (`));
});

test('formal practice scope has source assets and one npm package glob', async () => {
  await Promise.all(config.formal.practices.map(name => access(`practices/${name}`)));
  assert.ok(packageData.files.includes('practices/**/*'));
  assert.equal(packageData.files.some(path => /^practices\/[^*]+/.test(path)), false);
});

test('project metadata does not duplicate npm-native metadata', () => {
  for (const key of ['npm_package', 'node_minimum', 'manifest_schema_version', 'content_version']) {
    assert.equal(key in config.distribution, false, key);
  }
  assert.equal(config.asset_status.web, 'auxiliary');
});

test('CI covers pull requests and main while releases reuse the same gate', async () => {
  const ci = await readFile('.github/workflows/ci.yml', 'utf8');
  const release = await readFile('.github/workflows/release.yml', 'utf8');
  assert.match(ci, /pull_request:/);
  assert.match(ci, /branches:\s*\n\s*- main/);
  assert.match(ci, /npm test/);
  assert.match(ci, /python -m scripts\.tests\.runner/);
  assert.match(ci, /npm run lint --prefix web/);
  assert.match(ci, /npm run build --prefix web/);
  assert.match(ci, /npm run pack:check/);
  assert.match(release, /uses: \.\/\.github\/workflows\/ci\.yml/);
});

test('historical scripts are isolated from formal script paths', async () => {
  await access('scripts/archive/docx-migrations-2026-06/fix_one_docx.py');
  await access('scripts/archive/security-migration-2026-07/fix_security_issues.sh');
  await assert.rejects(access('scripts/fix_one_docx.py'));
  assert.equal(packageData.files.some(path => path.startsWith('scripts/archive')), false);
});
