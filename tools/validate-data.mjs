import path from 'node:path';
import { stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { exists, readTsv, readText, shardName, SHARD_COUNT } from './lib.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {
    data: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full')
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--data') args.data = path.resolve(process.cwd(), argv[++i]);
  }
  return args;
}

function check(condition, message, errors) {
  if (!condition) errors.push(message);
}

function isHan(char) {
  const code = char.codePointAt(0) ?? 0;
  return code >= 0x4e00 && code <= 0x9fff;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const curriculum = path.join(args.data, 'curriculum');
  const errors = [];
  const warnings = [];

  const books = await readTsv(path.join(curriculum, 'books.tsv'));
  const lessons = await readTsv(path.join(curriculum, 'lessons.tsv'));
  const lessonChars = await readTsv(path.join(curriculum, 'lesson_chars.tsv'));
  const characters = await readTsv(path.join(curriculum, 'characters.tsv'));
  const meta = await readTsv(path.join(curriculum, 'meta.tsv'));

  check(books.length > 0, 'books.tsv is empty', errors);
  check(lessons.length > 0, 'lessons.tsv is empty', errors);
  check(lessonChars.length > 0, 'lesson_chars.tsv is empty', errors);
  check(characters.length > 0, 'characters.tsv is empty', errors);

  const bookIds = new Set(books.map((row) => row[0]));
  const lessonIds = new Set();
  for (const row of lessons) {
    check(row.length >= 5, `bad lesson row: ${row.join('\t')}`, errors);
    if (row[0]) {
      check(!lessonIds.has(row[0]), `duplicate lesson id: ${row[0]}`, errors);
      lessonIds.add(row[0]);
    }
    check(bookIds.has(row[1]), `lesson ${row[0]} references unknown book ${row[1]}`, errors);
  }

  const charPinyin = new Map();
  for (const row of characters) {
    check(row.length >= 2, `bad character row: ${row.join('\t')}`, errors);
    if (row[0]) {
      check(!charPinyin.has(row[0]), `duplicate character: ${row[0]}`, errors);
      charPinyin.set(row[0], row[1] ?? '');
    }
  }

  let missingPinyin = 0;
  for (const row of lessonChars) {
    check(row.length >= 4, `bad lesson_char row: ${row.join('\t')}`, errors);
    if (!row[2]) missingPinyin += 1;
    check(charPinyin.has(row[1]), `lesson_char char not in characters.tsv: ${row[1]}`, errors);
  }
  if (missingPinyin > 0) warnings.push(`${missingPinyin} lesson chars have empty pinyin`);

  const strokeChars = new Set();
  const strokeCountByChar = new Map();
  let strokeFiles = 0;
  let badStrokeLines = 0;
  let strokeBytes = 0;
  for (let i = 0; i < SHARD_COUNT; i += 1) {
    const file = path.join(args.data, 'strokes', shardName(i));
    if (!(await exists(file))) continue;
    strokeFiles += 1;
    const info = await stat(file);
    strokeBytes += info.size;
    const text = await readText(file);
    for (const line of text.split(/\r?\n/)) {
      if (!line.trim()) continue;
      const fields = line.split('\t');
      if (fields.length < 4) {
        badStrokeLines += 1;
        continue;
      }
      const char = fields[0];
      const count = Number(fields[1]);
      const paths = fields.slice(2, 2 + count);
      const medians = fields[2 + count];
      if (!char || !Number.isInteger(count) || count <= 0) {
        badStrokeLines += 1;
        continue;
      }
      if (paths.length !== count || !paths.every((value) => value.trim().startsWith('M'))) {
        badStrokeLines += 1;
        continue;
      }
      const medianParts = (medians ?? '').split('|');
      if (medianParts.length !== count || medianParts.some((part) => part.split(';').length < 2)) {
        badStrokeLines += 1;
        continue;
      }
      strokeChars.add(char);
      strokeCountByChar.set(char, count);
    }
  }

  check(strokeFiles > 0, 'no stroke shard files found', errors);
  check(badStrokeLines === 0, `${badStrokeLines} malformed stroke lines`, errors);
  const missingStrokes = [...charPinyin.keys()].filter((char) => !strokeChars.has(char));
  if (missingStrokes.length > 0) {
    errors.push(`${missingStrokes.length} chars have no stroke data: ${missingStrokes.slice(0, 30).join(' ')}`);
  }

  let missingStrokeCount = 0;
  let mismatchStrokeCount = 0;
  for (const row of characters) {
    const declared = Number(row[4]);
    if (!row[4]) {
      missingStrokeCount += 1;
      continue;
    }
    const actual = strokeCountByChar.get(row[0]);
    if (!Number.isInteger(declared) || declared !== actual) {
      mismatchStrokeCount += 1;
    }
  }
  if (missingStrokeCount > 0) warnings.push(`${missingStrokeCount} character rows have no strokeCount column`);
  check(mismatchStrokeCount === 0, `${mismatchStrokeCount} character rows have strokeCount != stroke data`, errors);
  const strokeMb = strokeBytes / (1024 * 1024);
  if (strokeMb > 24) {
    warnings.push(`stroke shards are ${strokeMb.toFixed(1)} MB; consider --no-common or --common-limit`);
  }

  const metaMap = new Map(meta.filter((row) => row.length >= 2).map((row) => [row[0], row[1]]));
  const dataMode = metaMap.get('dataMode') ?? 'unknown';
  if (dataMode === 'full') {
    check(books.length === 12, `full data should have 12 books, got ${books.length}`, errors);
    const catalogChars = Number(metaMap.get('catalogChars') ?? 0);
    check(catalogChars === charPinyin.size,
      `meta catalogChars=${catalogChars} but characters.tsv has ${charPinyin.size} rows`, errors);
  }
  const commonChars = Number(metaMap.get('commonChars') ?? 0);
  if (dataMode === 'full' && commonChars > 0) {
    check(charPinyin.size > commonChars,
      `catalog (${charPinyin.size}) should exceed common charset (${commonChars})`, errors);
  }

  // 识字短文（阅读）：文件可选，旧数据缺文件只提示。
  const passagesFile = path.join(curriculum, 'passages.tsv');
  const manualFile = path.join(__dirname, 'passages/manual.json');
  if (!(await exists(passagesFile))) {
    warnings.push('passages.tsv not found; reading section will be hidden');
  } else {
    let extraChars = new Set();
    if (await exists(manualFile)) {
      const manual = JSON.parse(await readText(manualFile));
      extraChars = new Set();
      for (const char of Array.from(String(manual.extraChars ?? ''))) {
        if (isHan(char)) extraChars.add(char);
      }
    }

    const rank = new Map();
    [...books]
      .sort((a, b) => Number(a[1]) - Number(b[1]) || String(a[2] ?? '').localeCompare(String(b[2] ?? '')))
      .forEach((row, index) => rank.set(row[0], index));
    const orderedLessons = [...lessons].sort((a, b) => {
      const left = rank.get(a[1]) ?? 0;
      const right = rank.get(b[1]) ?? 0;
      if (left !== right) return left - right;
      return Number(a[3]) - Number(b[3]);
    });

    const lessonCharMap = new Map();
    for (const row of lessonChars) {
      const list = lessonCharMap.get(row[0]) ?? [];
      if (!list.includes(row[1])) list.push(row[1]);
      lessonCharMap.set(row[0], list);
    }
    const allowedByLesson = new Map();
    const learned = new Set();
    for (const lesson of orderedLessons) {
      const focus = lessonCharMap.get(lesson[0]) ?? [];
      allowedByLesson.set(lesson[0], new Set([...learned, ...focus, ...extraChars]));
      for (const char of focus) learned.add(char);
    }

    const passages = await readTsv(path.join(curriculum, 'passages.tsv'));
    const passageIds = new Set();
    const passageLessons = new Set();
    for (const row of passages) {
      if (row[0] === 'passageId') continue;
      const id = row[0];
      const lessonId = row[1];
      const text = row[4] ?? '';
      check(row.length >= 5, `bad passage row: ${row.join('\t')}`, errors);
      if (id) {
        check(!passageIds.has(id), `duplicate passage id: ${id}`, errors);
        passageIds.add(id);
      }
      check(lessonIds.has(lessonId), `passage ${id} references unknown lesson ${lessonId}`, errors);
      check(text.length > 0, `passage ${id} has empty text`, errors);
      if (text.length > 160) {
        check(false, `passage ${id} text is too long (${text.length})`, errors);
      } else if (text.length > 120) {
        warnings.push(`passage ${id} text is ${text.length} chars`);
      }
      if (text.includes('\t')) {
        check(false, `passage ${id} text contains a tab`, errors);
      }
      passageLessons.add(lessonId);

      const allowed = allowedByLesson.get(lessonId) ?? new Set();
      const focus = lessonCharMap.get(lessonId) ?? [];
      const outside = [];
      let hasFocus = false;
      for (const char of Array.from(text)) {
        if (!isHan(char)) continue;
        if (focus.includes(char)) hasFocus = true;
        if (!allowed.has(char)) outside.push(char);
      }
      if (outside.length > 0) {
        check(false, `passage ${id} uses chars outside learned set: ${[...new Set(outside)].join('')}`, errors);
      }
      if (!hasFocus) {
        warnings.push(`passage ${id} contains no chars from lesson ${lessonId}`);
      }
    }
    console.log(`[validate] passages=${passageIds.size} lessonsCovered=${passageLessons.size}`);
  }

  for (const name of ['ARPHICPL.txt', 'COPYING.txt', 'LGPL.txt', 'LICENSE-hanzi-writer.txt']) {
    if (!(await exists(path.join(args.data, 'licenses', name)))) {
      warnings.push(`license missing: ${name}`);
    }
  }

  console.log(`[validate] mode=${dataMode} books=${books.length} lessons=${lessons.length} chars=${charPinyin.size} strokeChars=${strokeChars.size} shards=${strokeMb.toFixed(1)}MB`);
  for (const warning of warnings) console.warn(`[validate] WARN ${warning}`);
  if (errors.length > 0) {
    for (const error of errors) console.error(`[validate] ERROR ${error}`);
    process.exitCode = 1;
    return;
  }
  console.log('[validate] OK');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
