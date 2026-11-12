/*
 * make-seed.mjs — 从 full 数据裁剪出演示数据（随仓库提交）。
 *
 * 取一年级上册前两课，保留对应生字、课次与笔画分片，生成同样目录结构的 data/seed。
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { copyFile } from 'node:fs/promises';
import {
  ensureDir,
  exists,
  loadGraphics,
  nowIso,
  readTsv,
  tsvRow,
  writeStrokeShards,
  writeText
} from './lib.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SEED_BOOK = '1a';
const SEED_LESSONS = 2;

function parseArgs(argv) {
  const args = {
    full: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full'),
    out: path.join(__dirname, '../entry/src/main/resources/rawfile/data/seed'),
    cache: path.join(__dirname, 'cache')
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--full') args.full = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--out') args.out = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--cache') args.cache = path.resolve(process.cwd(), argv[++i]);
  }
  return args;
}

async function copyLicenses(outDir) {
  const target = path.join(outDir, 'licenses');
  await ensureDir(target);
  for (const name of ['ARPHICPL.txt', 'COPYING.txt', 'LGPL.txt', 'LICENSE-hanzi-writer.txt', 'CHINESE_TEXTBOOK_MIT.txt']) {
    const source = path.join(__dirname, 'licenses', name);
    if (await exists(source)) {
      await copyFile(source, path.join(target, name));
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const fullCurriculum = path.join(args.full, 'curriculum');
  const curriculum = path.join(args.out, 'curriculum');
  await ensureDir(curriculum);

  const lessons = await readTsv(path.join(fullCurriculum, 'lessons.tsv'));
  const seedLessons = lessons.filter((row) => row[1] === SEED_BOOK).slice(0, SEED_LESSONS);
  if (seedLessons.length === 0) {
    throw new Error(`full 数据中找不到 ${SEED_BOOK} 的课文，请先运行 data:all`);
  }
  const lessonIds = new Set(seedLessons.map((row) => row[0]));

  const lessonChars = (await readTsv(path.join(fullCurriculum, 'lesson_chars.tsv'))).filter((row) =>
    lessonIds.has(row[0])
  );
  const keep = new Set(lessonChars.map((row) => row[1]));

  const characters = (await readTsv(path.join(fullCurriculum, 'characters.tsv'))).filter((row) =>
    keep.has(row[0])
  );
  const words = (await readTsv(path.join(fullCurriculum, 'words.tsv'))).filter((row) => keep.has(row[0]));
  const readings = (await readTsv(path.join(fullCurriculum, 'readings.tsv'))).filter((row) =>
    keep.has(row[0])
  );

  const graphics = await loadGraphics(path.join(args.cache, 'graphics.txt'), keep);
  const missing = [...keep].filter((char) => !graphics.has(char));
  if (missing.length > 0) {
    console.warn(`[seed] missing stroke data: ${missing.join(' ')}`);
  }

  await writeText(
    path.join(curriculum, 'books.tsv'),
    [
      tsvRow(['id', 'grade', 'term', 'title', 'lessonCount', 'charCount', 'writeCount']),
      tsvRow([SEED_BOOK, '1', 'a', '一年级上册', String(seedLessons.length), String(keep.size), String(keep.size)])
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'lessons.tsv'),
    [
      tsvRow(['lessonId', 'bookId', 'unit', 'order', 'title']),
      ...seedLessons.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'lesson_chars.tsv'),
    [
      tsvRow(['lessonId', 'char', 'pinyin', 'isWrite']),
      ...lessonChars.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'characters_base.tsv'),
    [
      tsvRow(['char', 'pinyins']),
      ...characters.map((row) => tsvRow([row[0], row[1] ?? '']))
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'characters.tsv'),
    [
      tsvRow(['char', 'pinyins', 'radical', 'decomposition', 'strokeCount']),
      ...characters.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'words.tsv'),
    [tsvRow(['char', 'word', 'readingPinyin']), ...words.map(tsvRow)].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'readings.tsv'),
    [tsvRow(['char', 'pinyin', 'lessonId', 'words']), ...readings.map(tsvRow)].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculum, 'meta.tsv'),
    [
      tsvRow(['dataMode', 'seed']),
      tsvRow(['dataSource', 'PEP primary school Chinese word lists (MIT dataset)']),
      tsvRow(['dataSourceUrl', 'https://github.com/athenayan123-web/dictation-robot']),
      tsvRow(['dataLicense', 'MIT']),
      tsvRow(['books', '1']),
      tsvRow(['lessons', String(seedLessons.length)]),
      tsvRow(['uniqueChars', String(keep.size)]),
      tsvRow(['strokeChars', String(graphics.size)]),
      tsvRow(['generatedAt', nowIso()])
    ].join('\n') + '\n'
  );

  await writeStrokeShards(path.join(args.out, 'strokes'), graphics);
  await copyLicenses(args.out);
  console.log(`[seed] wrote ${keep.size} chars / ${seedLessons.length} lessons to ${args.out}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
