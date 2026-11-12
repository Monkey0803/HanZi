/*
 * fetch-textbook.mjs — 下载公开的小学语文教材生字表。
 *
 * 数据源：athenayan123-web/dictation-robot（MIT），人教版（部编版）12 册，
 * 按「册 → 单元 → 课 → 生字」组织。只缓存到 tools/cache/，不进入 HAP。
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { writeText, ensureDir, exists, readText } from './lib.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_URL =
  'https://raw.githubusercontent.com/athenayan123-web/dictation-robot/HEAD/server/data/chinese_textbook.json';
const LICENSE_URL =
  'https://raw.githubusercontent.com/athenayan123-web/dictation-robot/HEAD/LICENSE';

function parseArgs(argv) {
  const args = {
    cache: path.join(__dirname, 'cache'),
    refresh: false
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--cache') args.cache = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--refresh') args.refresh = true;
  }
  return args;
}

async function download(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`GET ${url} failed: ${response.status}`);
  }
  return response.text();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  await ensureDir(args.cache);
  await ensureDir(path.join(__dirname, 'licenses'));

  const dataFile = path.join(args.cache, 'chinese_textbook.json');
  if (args.refresh || !(await exists(dataFile))) {
    const text = await download(DATA_URL);
    JSON.parse(text);
    await writeText(dataFile, text);
    console.log(`[fetch] wrote ${dataFile}`);
  } else {
    const text = await readText(dataFile);
    JSON.parse(text);
    console.log(`[fetch] cache hit ${dataFile}`);
  }

  const licenseFile = path.join(__dirname, 'licenses', 'CHINESE_TEXTBOOK_MIT.txt');
  if (args.refresh || !(await exists(licenseFile))) {
    await writeText(licenseFile, await download(LICENSE_URL));
    console.log(`[fetch] wrote ${licenseFile}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
