import { HELP } from './constants.js';
import { availablePractices, executeInstall, packageVersion, updateInstalled } from './installer.js';
import { diagnose } from './doctor.js';

function flags(args) {
  return {
    dryRun: args.includes('--dry-run'),
    force: args.includes('--force'),
    json: args.includes('--json'),
  };
}

function printActions(result) {
  const prefix = result.dryRun ? '[dry-run] ' : '';
  for (const item of result.actions) {
    const extra = item.candidate ? ` -> ${item.candidate}` : item.note ? ` (${item.note})` : '';
    console.log(`${prefix}${item.action.padEnd(14)} ${item.path}${extra}`);
  }
  const conflicts = result.actions.filter((item) => item.action === 'conflict').length;
  console.log(`${prefix}SAC ${result.manifest.packageVersion}: ${result.actions.length} actions, ${conflicts} conflicts.`);
}

export async function run(args, { targetDir = process.cwd() } = {}) {
  if (args.includes('--help') || args.includes('-h')) {
    console.log(HELP);
    return;
  }
  if (args.includes('--version') || args.includes('-v')) {
    console.log(packageVersion);
    return;
  }
  const [command = 'help', subject, name] = args.filter((arg) => !arg.startsWith('--'));
  const options = flags(args);
  if (command === 'help') {
    console.log(HELP);
    return;
  }
  if (command === 'version') {
    console.log(packageVersion);
    return;
  }
  if (command === 'init') {
    printActions(await executeInstall({ targetDir, components: ['codex', 'claude', 'skills'], ...options }));
    return;
  }
  if (command === 'install') {
    if (subject === 'codex' || subject === 'claude' || subject === 'all' || subject === 'skills') {
      printActions(await executeInstall({ targetDir, components: [subject], ...options }));
      return;
    }
    if (subject === 'practice' && name) {
      printActions(await executeInstall({ targetDir, components: [], practices: [name], ...options }));
      return;
    }
    throw new Error('Usage: sac install codex|claude|all|skills OR sac install practice <name>');
  }
  if (command === 'update') {
    printActions(await updateInstalled({ targetDir, ...options }));
    return;
  }
  if (command === 'list') {
    const data = { version: packageVersion, components: ['codex', 'claude', 'skills'], practices: await availablePractices() };
    if (options.json) console.log(JSON.stringify(data, null, 2));
    else {
      console.log(`solution-practices ${data.version}`);
      console.log(`Components: ${data.components.join(', ')}`);
      console.log(`Practices: ${data.practices.join(', ')}`);
    }
    return;
  }
  if (command === 'doctor') {
    const report = await diagnose(targetDir);
    if (options.json) console.log(JSON.stringify(report, null, 2));
    else for (const item of report.results) console.log(`${item.level.toUpperCase().padEnd(7)} ${item.code}: ${item.message}`);
    if (!report.ok) process.exitCode = 1;
    return report;
  }
  throw new Error(`Unknown command "${command}". Run "sac help".`);
}
