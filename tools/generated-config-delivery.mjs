import { execFileSync } from 'node:child_process';
import { mkdirSync, writeFileSync, realpathSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { generatedBranch, generatedFiles, generatedFileResources, matchingContent, protectedRepository } from './generated-config.mjs';

const repository = `mahn-ke/${protectedRepository}`;
const prefix = `module.general["${protectedRepository}"]`;

export function migrationEntries(state, manifest) {
  const result = [];
  for (const resource of state.resources || []) {
    if (resource.module !== prefix || resource.type !== 'github_repository_file') continue;
    for (const instance of resource.instances || []) {
      const attributes = instance.attributes || {};
      if (!Object.hasOwn(manifest, attributes.file)) throw new Error('Unknown generated path in state');
      if (attributes.repository !== protectedRepository || !['main', generatedBranch].includes(attributes.branch)) {
        throw new Error('Unexpected generated-file identity');
      }
      const index = instance.index_key === undefined ? '' : `[${JSON.stringify(instance.index_key)}]`;
      result.push({ address: `${prefix}.github_repository_file.${resource.name}${index}`,
        path: attributes.file, migrate: attributes.branch === 'main' });
    }
  }
  return result;
}

export function adoptEntry(entry, runTerraform) {
  runTerraform(['state', 'rm', '-lock-timeout=5m', entry.address]);
  try {
    runTerraform(['import', '-input=false', '-lock-timeout=5m', entry.address, `${protectedRepository}:${entry.path}:${generatedBranch}`]);
  } catch {
    try {
      runTerraform(['import', '-input=false', '-lock-timeout=5m', entry.address, `${protectedRepository}:${entry.path}:main`]);
    } catch { throw new Error(`Adoption and original-identity recovery failed for ${entry.address}; stop and restore association manually`); }
    throw new Error(`Adoption failed for ${entry.address}; original main association restored`);
  }
}

export function prepareBranch(api, manifest) {
  const main = api(`repos/${repository}/git/ref/heads/main`);
  let branch;
  try { branch = api(`repos/${repository}/git/ref/heads/${generatedBranch}`); }
  catch (error) { if (error.status !== 404) throw error; }
  if (!branch) {
    api(`repos/${repository}/git/refs`, 'POST', { ref: `refs/heads/${generatedBranch}`, sha: main.object.sha });
    return 'created';
  }
  const comparison = api(`repos/${repository}/compare/main...${generatedBranch}`);
  if (comparison.files?.some(file => !Object.hasOwn(manifest, file.filename) || ['removed', 'renamed'].includes(file.status))) {
    throw new Error('Unrelated edits on generated branch; refusing preparation');
  }
  if (comparison.behind_by > 0) {
    if (comparison.ahead_by === 0) {
      api(`repos/${repository}/git/refs/heads/${generatedBranch}`, 'PATCH', { sha: main.object.sha, force: false });
    } else {
      api(`repos/${repository}/merges`, 'POST', { base: generatedBranch, head: 'main', commit_message: 'Refresh generated configuration base' });
    }
  }
  return 'prepared';
}

export function publishPR(api, pages, directory, revision) {
  if (!/^[a-f0-9]{40}$/.test(revision)) throw new Error('Missing generator revision');
  const manifest = generatedFiles(directory);
  const comparison = api(`repos/${repository}/compare/main...${generatedBranch}`);
  if (comparison.behind_by !== 0) throw new Error('Generated branch is behind main');
  if (!comparison.files?.length) return 'no-change';
  if (comparison.files.length >= 300) throw new Error('Generated diff may be truncated');
  for (const entry of comparison.files) {
    if (!Object.hasOwn(manifest, entry.filename) || ['removed', 'renamed'].includes(entry.status)) throw new Error('Unrelated edits on generated branch');
    const file = api(`repos/${repository}/contents/${entry.filename}?ref=${generatedBranch}`);
    if (!matchingContent(entry.filename, Buffer.from(file.content, 'base64').toString(), manifest[entry.filename])) throw new Error('Generated branch differs from trusted templates');
  }
  const body = `Generated configuration from mahn-ke/repos revision \`${revision}\`.\n\nAll changed files match the trusted generator. Merge only after current required checks and Infrastructure review pass.\n\n<!-- mahn-ke-generated-config:${revision} -->`;
  const prs = pages(`repos/${repository}/pulls?state=open&head=mahn-ke:${generatedBranch}&base=main&per_page=100`);
  if (prs.length > 1) throw new Error('Multiple generated configuration PRs');
  if (prs.length) {
    api(`repos/${repository}/pulls/${prs[0].number}`, 'PATCH', { body });
    return 'updated';
  }
  api(`repos/${repository}/pulls`, 'POST', { title: 'chore: reconcile Terraform-generated configuration', head: generatedBranch, base: 'main', body });
  return 'created';
}

function invoke(args, input) {
  return execFileSync(process.env.GH_BINARY || 'gh', args, { input, encoding: 'utf8', timeout: 120000, maxBuffer: 16000000, stdio: ['pipe', 'pipe', 'pipe'] });
}
function api(endpoint, method = 'GET', body) {
  const args = ['api', endpoint, '--method', method];
  if (body) args.push('--input', '-');
  try { return JSON.parse(invoke(args, body ? JSON.stringify(body) : undefined) || 'null'); }
  catch (error) {
    if (String(error.stderr).includes('HTTP 404')) error.status = 404;
    throw error;
  }
}
function terraform(args) {
  return execFileSync('terraform', ['-chdir=infrastructure', ...args], { encoding: 'utf8', timeout: 300000, maxBuffer: 20000000, stdio: ['pipe', 'pipe', 'pipe'] });
}

if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(resolve(process.argv[1]))).href) {
  if (process.env.GITHUB_REPOSITORY !== 'mahn-ke/repos' || process.env.GITHUB_EVENT_NAME === 'pull_request' || process.env.GITHUB_REF !== 'refs/heads/main') {
    throw new Error('Delivery is restricted to trusted repos main builds');
  }
  const [mode] = process.argv.slice(2);
  if (mode === 'prepare') console.log(prepareBranch(api, generatedFiles(process.cwd())));
  else if (mode === 'adopt-state') {
    const stateText = terraform(['state', 'pull']);
    const state = JSON.parse(stateText);
    const entries = migrationEntries(state, generatedFiles(process.cwd()));
    const legacy = entries.filter(entry => entry.migrate);
    if (legacy.length && process.env.ADOPT_GENERATED_STATE !== 'true') throw new Error('Legacy main-file state requires explicit approved adoption');
    if (process.env.ADOPT_GENERATED_STATE === 'true') {
      if (!process.env.RUNNER_TEMP) throw new Error('Secure runner backup directory required');
      writeFileSync(`${process.env.RUNNER_TEMP}/gdq-generator-state-before-adoption.json`, stateText, { mode: 0o600 });
    }
    if (legacy.length) {
      const backup = process.env.RUNNER_TEMP;
      if (!backup) throw new Error('Secure runner backup directory required');
      mkdirSync(backup, { recursive: true });
      writeFileSync(`${backup}/gdq-generator-state-before-adoption.json`, stateText, { mode: 0o600 });
      for (const entry of legacy) {
        const file = api(`repos/${repository}/contents/${entry.path}?ref=${generatedBranch}`);
        if (!file.sha) throw new Error('Staging copy missing; refusing state removal');
        adoptEntry(entry, terraform);
      }
      console.log(`Adopted ${legacy.length} GDQ generated-file state entries; no remote files deleted`);
    }
    if (process.env.ADOPT_GENERATED_STATE === 'true') {
      for (const entry of generatedFileResources(process.cwd()).filter(resource => !entries.some(existing => existing.address === resource.address))) {
        let file;
        try { file = api(`repos/${repository}/contents/${entry.path}?ref=${generatedBranch}`); }
        catch (error) { if (error.status === 404) continue; throw error; }
        if (file.sha) terraform(['import', '-input=false', '-lock-timeout=5m', entry.address, `${protectedRepository}:${entry.path}:${generatedBranch}`]);
      }
    }
    const tracked = state.resources?.some(resource => resource.module === prefix && resource.type === 'github_branch' && resource.name === 'generated_config');
    if (!tracked) {
      if (process.env.ADOPT_GENERATED_STATE !== 'true') throw new Error('Generated branch adoption requires explicit approval');
      terraform(['import', '-input=false', '-lock-timeout=5m', `${prefix}.github_branch.generated_config[0]`, `${protectedRepository}:${generatedBranch}:main`]);
    }
  } else if (mode === 'publish') {
    const revision = execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
    console.log(publishPR(api, endpoint => JSON.parse(invoke(['api', endpoint, '--paginate', '--slurp'])).flat(), process.cwd(), revision));
  } else if (mode === 'assert-state') {
    const entries = migrationEntries(JSON.parse(terraform(['state', 'pull'])), generatedFiles(process.cwd()));
    if (entries.some(entry => entry.migrate)) throw new Error('Run the production-approved generated-state adoption workflow before applying branch replacements');
    console.log('Protected generated-file state is ready');
  } else throw new Error('Unknown generated delivery mode');
}