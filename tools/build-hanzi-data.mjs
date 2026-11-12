import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { copyFile, mkdir } from 'node:fs/promises';
import {
  ensureDir,
  exists,
  loadDictionary,
  loadGraphics,
  nowIso,
  readTsv,
  tsvRow,
  writeStrokeShards,
  writeText
} from './lib.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {
    cache: path.join(__dirname, 'cache'),
    curriculum: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full/curriculum'),
    out: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full'),
    graphics: '',
    dictionary: ''
  };
  for (let i = 0; i < argv.length; i += 1) {
    const value = argv[i];
    if (value === '--cache') args.cache = path.resolve(process.cwd(), argv[++i]);
    else if (value === '--curriculum') args.curriculum = path.resolve(process.cwd(), argv[++i]);
    else if (value === '--out') args.out = path.resolve(process.cwd(), argv[++i]);
    else if (value === '--graphics') args.graphics = path.resolve(process.cwd(), argv[++i]);
    else if (value === '--dictionary') args.dictionary = path.resolve(process.cwd(), argv[++i]);
  }
  args.graphics = args.graphics || path.join(args.cache, 'graphics.txt');
  args.dictionary = args.dictionary || path.join(args.cache, 'dictionary.txt');
  return args;
}

async function copyLicenses(outDir) {
  const source = path.join(__dirname, 'licenses');
  const target = path.join(outDir, 'licenses');
  await ensureDir(target);
  const files = [
    ['ARPHICPL.txt', 'ARPHICPL.txt'],
    ['COPYING.txt', 'COPYING.txt'],
    ['LGPL.txt', 'LGPL.txt'],
    ['LICENSE-hanzi-writer.txt', 'LICENSE-hanzi-writer.txt']
  ];
  for (const [from, to] of files) {
    const src = path.join(source, from);
    if (await exists(src)) {
      await copyFile(src, path.join(target, to));
    } else {
      console.warn(`[build] license missing: ${src}`);
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  console.log(`[build] graphics=${args.graphics}`);
  console.log(`[build] dictionary=${args.dictionary}`);
  console.log(`[build] curriculum=${args.curriculum}`);
  console.log(`[build] out=${args.out}`);

  const characterRows = await readTsv(path.join(args.curriculum, 'characters_base.tsv'));
  const pinyinByChar = new Map();
  for (const row of characterRows) {
    if (row.length < 2) continue;
    pinyinByChar.set(row[0], row[1] ?? '');
  }
  const keep = new Set(pinyinByChar.keys());
  console.log(`[build] curriculum chars=${keep.size}`);

  const graphics = await loadGraphics(args.graphics, keep);
  const dictionary = await loadDictionary(args.dictionary, keep);
  const missing = [...keep].filter((char) => !graphics.has(char));
  console.log(`[build] graphics=${graphics.size} dictionary=${dictionary.size} missing=${missing.length}`);
  if (missing.length > 0) {
    console.warn(`[build] missing stroke data: ${missing.slice(0, 40).join(' ')}`);
  }

  const outStrokes = path.join(args.out, 'strokes');
  await ensureDir(outStrokes);
  await writeStrokeShards(outStrokes, graphics);

  const dictionaryRows = [...keep]
    .sort((a, b) => (a.codePointAt(0) ?? 0) - (b.codePointAt(0) ?? 0))
    .map((char) => {
      const info = dictionary.get(char);
      const own = pinyinByChar.get(char) ?? '';
      const fallback = info?.pinyin.length ? info.pinyin.join(';') : '';
      return [
        char,
        own || fallback,
        info?.radical ?? '',
        info?.decomposition ?? ''
      ];
    });
  await writeText(
    path.join(args.curriculum, 'characters.tsv'),
    ['# char\tpinyins\tradical\tdecomposition', ...dictionaryRows.map(tsvRow)].join('\n') + '\n'
  );

  const primaryPinyin = new Map();
  for (const row of dictionaryRows) {
    primaryPinyin.set(row[0], row[1].split(';')[0] ?? '');
  }
  const lessonCharFile = path.join(args.curriculum, 'lesson_chars.tsv');
  if (await exists(lessonCharFile)) {
    const lessonCharRows = await readTsv(lessonCharFile);
    const filled = lessonCharRows.map((row) => {
      const char = row[1] ?? '';
      const pinyin = row[2] || primaryPinyin.get(char) || '';
      return [row[0] ?? '', char, pinyin, row[3] ?? '0'];
    });
    await writeText(
      lessonCharFile,
      ['# lessonId\tchar\tpinyin\tisWrite', ...filled.map(tsvRow)].join('\n') + '\n'
    );
  }

  await copyLicenses(args.out);

  const metaFile = path.join(args.curriculum, 'meta.tsv');
  const metaRows = (await exists(metaFile)) ? await readTsv(metaFile) : [];
  const meta = new Map(metaRows.filter((row) => row.length >= 2).map((row) => [row[0], row[1]]));
  meta.set('strokeChars', String(graphics.size));
  meta.set('missingStrokes', String(missing.length));
  meta.set('generatedAt', nowIso());
  await writeText(
    metaFile,
    [...meta.entries()].map(([key, value]) => tsvRow([key, value])).join('\n') + '\n'
  );

  console.log('[build] done');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
