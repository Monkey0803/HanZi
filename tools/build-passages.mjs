/*
 * build-passages.mjs — 生成识字短文（阅读功能数据）。
 *
 * 输入：curriculum/books.tsv、lessons.tsv、lesson_chars.tsv、words.tsv + 可选 manual.json。
 * 输出：curriculum/passages.tsv
 *
 * 生成原则：一篇短文只允许出现「本课之前所有课的生字 + 本课生字」里的字，
 * 保证不超纲；人工覆盖篇目允许额外使用 manual.json 的 extraChars 常用功能字。
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ensureDir, exists, readText, readTsv, tsvRow, writeText } from './lib.mjs';
import { composeWordPractice } from './passages/compose.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MAX_TEXT_LENGTH = 120;
const MAX_CANDIDATE_WORDS = 24;

function parseArgs(argv) {
  const args = {
    curriculum: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full/curriculum'),
    manual: path.join(__dirname, 'passages/manual.json'),
    out: ''
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--curriculum') args.curriculum = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--manual') args.manual = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--out') args.out = path.resolve(process.cwd(), argv[++i]);
  }
  if (!args.out) args.out = path.join(args.curriculum, 'passages.tsv');
  return args;
}

function isHan(char) {
  const code = char.codePointAt(0) ?? 0;
  return code >= 0x4e00 && code <= 0x9fff;
}

/** 首列是 id 的册排序：年级升序，上学期在前。 */
function sortBooks(books) {
  return [...books].sort((a, b) => {
    const gradeDiff = Number(a[1]) - Number(b[1]);
    if (gradeDiff !== 0) return gradeDiff;
    return String(a[2] ?? '').localeCompare(String(b[2] ?? ''));
  });
}

/** 按「册顺序 → 课 order」展开课文。 */
function flattenLessons(books, lessons) {
  const rank = new Map();
  sortBooks(books).forEach((row, index) => rank.set(row[0], index));
  return [...lessons].sort((a, b) => {
    const left = rank.get(a[1]) ?? 0;
    const right = rank.get(b[1]) ?? 0;
    if (left !== right) return left - right;
    return Number(a[3]) - Number(b[3]);
  });
}

function groupByLesson(rows) {
  const map = new Map();
  for (const row of rows) {
    const key = row[0];
    if (!key) continue;
    const list = map.get(key) ?? [];
    list.push(row);
    map.set(key, list);
  }
  return map;
}

function loadManual(file) {
  return readText(file).then((text) => {
    const parsed = JSON.parse(text);
    const extraChars = new Set();
    const extra = String(parsed.extraChars ?? '');
    for (const char of Array.from(extra)) {
      if (isHan(char)) extraChars.add(char);
    }
    const lessons = parsed.lessons && typeof parsed.lessons === 'object' ? parsed.lessons : {};
    return { extraChars, lessons };
  });
}

function uniqueChars(values) {
  const seen = new Set();
  const result = [];
  for (const value of values) {
    if (isHan(value) && !seen.has(value)) {
      seen.add(value);
      result.push(value);
    }
  }
  return result;
}

/** 人工覆盖的读音覆盖串：'地:dì;人:rén' → '地:dì;人:rén'（原样输出，去掉空白）。 */
function normalizeOverrides(value) {
  return String(value ?? '')
    .split(';')
    .map((part) => part.trim())
    .filter((part) => part.includes(':'))
    .join(';');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  await ensureDir(path.dirname(args.out));

  const books = await readTsv(path.join(args.curriculum, 'books.tsv'));
  const lessons = await readTsv(path.join(args.curriculum, 'lessons.tsv'));
  const lessonChars = groupByLesson(await readTsv(path.join(args.curriculum, 'lesson_chars.tsv')));
  const wordRows = await readTsv(path.join(args.curriculum, 'words.tsv'));

  const manual = (await exists(args.manual))
    ? await loadManual(args.manual)
    : { extraChars: new Set(), lessons: {} };

  const ordered = flattenLessons(books, lessons);
  const learned = new Set();
  const rows = [];
  let manualCount = 0;
  let skipped = 0;
  let longest = 0;

  for (const lesson of ordered) {
    const lessonId = lesson[0];
    const focus = uniqueChars((lessonChars.get(lessonId) ?? []).map((row) => row[1]));
    const usable = new Set([...learned, ...focus]);

    const handwritten = manual.lessons[lessonId];
    if (Array.isArray(handwritten) && handwritten.length > 0) {
      handwritten.forEach((item, index) => {
        const text = String(item.text ?? '').replace(/\s+/g, ' ').trim();
        const title = String(item.title ?? '').trim();
        if (!text || text.length > MAX_TEXT_LENGTH) {
          skipped += 1;
          return;
        }
        rows.push([
          `${lessonId}-P${index + 1}`,
          lessonId,
          index + 1,
          title,
          text,
          normalizeOverrides(item.overrides)
        ]);
        manualCount += 1;
        longest = Math.max(longest, text.length);
      });
    } else {
      const seen = new Set();
      const candidates = [];
      for (const row of wordRows) {
        const word = row[1] ?? '';
        const chars = Array.from(word);
        if (chars.length < 2 || chars.length > 4 || seen.has(word)) continue;
        if (!chars.every((char) => usable.has(char))) continue;
        if (!chars.some((char) => focus.includes(char))) continue;
        seen.add(word);
        candidates.push(word);
        if (candidates.length >= MAX_CANDIDATE_WORDS) break;
      }
      const text = composeWordPractice(candidates);
      if (text.length === 0) {
        skipped += 1;
      } else {
        rows.push([`${lessonId}-P1`, lessonId, 1, '', text, '']);
        longest = Math.max(longest, text.length);
      }
    }

    for (const char of focus) learned.add(char);
  }

  await writeText(
    args.out,
    [
      tsvRow(['passageId', 'lessonId', 'order', 'title', 'text', 'pinyinOverrides']),
      ...rows.map(tsvRow)
    ].join('\n') + '\n'
  );

  const covered = new Set(rows.map((row) => row[1])).size;
  console.log(
    `[passages] lessons=${covered}/${ordered.length} passages=${rows.length} manual=${manualCount} skipped=${skipped} longest=${longest}`
  );
  console.log(`[passages] wrote ${args.out}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
