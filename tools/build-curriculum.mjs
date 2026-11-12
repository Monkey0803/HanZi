/*
 * build-curriculum.mjs — 把公开教材生字表 JSON 转成 App 使用的 TSV。
 *
 * 输入：tools/cache/chinese_textbook.json（人教版部编版 12 册）。
 * 输出：curriculum/books.tsv、lessons.tsv、lesson_chars.tsv、characters_base.tsv、
 *       words.tsv、readings.tsv、meta.tsv。
 * 拼音/部首/部件由 makemeahanzi 的 dictionary.txt 补齐（见 build-hanzi-data.mjs 再次合并）。
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  ensureDir,
  loadDictionary,
  nowIso,
  readText,
  tsvRow,
  writeText
} from './lib.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const GRADE_NUMBERS = {
  一: 1,
  二: 2,
  三: 3,
  四: 4,
  五: 5,
  六: 6
};

function parseArgs(argv) {
  const args = {
    cache: path.join(__dirname, 'cache'),
    out: path.join(__dirname, '../entry/src/main/resources/rawfile/data/full')
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--cache') args.cache = path.resolve(process.cwd(), argv[++i]);
    else if (argv[i] === '--out') args.out = path.resolve(process.cwd(), argv[++i]);
  }
  return args;
}

function isHan(char) {
  const code = char.codePointAt(0) ?? 0;
  return code >= 0x4e00 && code <= 0x9fff;
}

/** '一年级上册' → { grade: 1, term: 'a', id: '1a' }。 */
function parseGrade(label) {
  const gradeChar = label.charAt(0);
  const grade = GRADE_NUMBERS[gradeChar];
  if (!grade) {
    throw new Error(`无法解析册名：${label}`);
  }
  const term = label.includes('上册') ? 'a' : 'b';
  return { grade, term, id: `${grade}${term}` };
}

function normalizeLabel(label) {
  return String(label ?? '').replace(/\s+/g, ' ').trim();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const curriculumDir = path.join(args.out, 'curriculum');
  await ensureDir(curriculumDir);

  const raw = JSON.parse(await readText(path.join(args.cache, 'chinese_textbook.json')));
  if (!raw || !Array.isArray(raw.grades)) {
    throw new Error('chinese_textbook.json 缺少 grades 数组');
  }

  const dictionary = await loadDictionary(path.join(args.cache, 'dictionary.txt'), null);
  const bookRows = [];
  const lessonRows = [];
  const lessonCharRows = [];
  const charPinyin = new Map();
  const wordRows = [];
  const wordSeen = new Set();
  const bookStats = [];

  const grades = [...raw.grades].sort((a, b) => {
    const left = parseGrade(a.grade);
    const right = parseGrade(b.grade);
    return left.grade === right.grade ? left.term.localeCompare(right.term) : left.grade - right.grade;
  });

  for (const gradeData of grades) {
    const book = parseGrade(gradeData.grade);
    const units = Array.isArray(gradeData.units) ? gradeData.units : [];
    let order = 0;
    let bookChars = 0;
    for (const unit of units) {
      const unitIndex = Number(unit.unit) || 0;
      const lessons = Array.isArray(unit.lessons) ? unit.lessons : [];
      for (const lesson of lessons) {
        order += 1;
        const lessonId = `G${book.grade}${book.term.toUpperCase()}${String(order).padStart(2, '0')}`;
        lessonRows.push([lessonId, book.id, unitIndex, order, normalizeLabel(lesson.title)]);

        const seen = new Set();
        const entries = Array.isArray(lesson.words) ? lesson.words : [];
        for (const value of entries) {
          const entry = String(value ?? '').replace(/\s+/g, '');
          if (entry.length === 0) {
            continue;
          }
          const entryChars = Array.from(entry);
          const allHan = entryChars.every((char) => isHan(char));
          for (const char of entryChars) {
            if (!isHan(char) || seen.has(char)) {
              continue;
            }
            seen.add(char);
            bookChars += 1;
            const info = dictionary.get(char);
            const pinyin = info && info.pinyin.length > 0 ? info.pinyin.join(';') : '';
            lessonCharRows.push([lessonId, char, pinyin, '1']);
            if (!charPinyin.has(char)) {
              charPinyin.set(char, pinyin);
            } else if (pinyin && !charPinyin.get(char)) {
              charPinyin.set(char, pinyin);
            }
          }
          if (entryChars.length >= 2 && allHan) {
            for (const char of entryChars) {
              const key = `${char}\t${entry}`;
              if (wordSeen.has(key)) {
                continue;
              }
              wordSeen.add(key);
              const info = dictionary.get(char);
              const pinyin = info && info.pinyin.length > 0 ? info.pinyin[0] : '';
              wordRows.push([char, entry, pinyin]);
            }
          }
        }
      }
    }
    const uniqueInBook = new Set(
      lessonCharRows.filter((row) => row[0].startsWith(`G${book.grade}${book.term.toUpperCase()}`)).map((row) => row[1])
    );
    const lessonCount = order;
    bookRows.push([
      book.id,
      book.grade,
      book.term,
      normalizeLabel(gradeData.grade),
      lessonCount,
      uniqueInBook.size,
      uniqueInBook.size
    ]);
    bookStats.push({ id: book.id, lessons: lessonCount, chars: uniqueInBook.size, rows: bookChars });
  }

  const characterRows = [...charPinyin.entries()]
    .sort((a, b) => (a[0].codePointAt(0) ?? 0) - (b[0].codePointAt(0) ?? 0))
    .map(([char, pinyin]) => {
      const info = dictionary.get(char);
      return [char, pinyin, info?.radical ?? '', info?.decomposition ?? ''];
    });

  await writeText(
    path.join(curriculumDir, 'books.tsv'),
    [
      tsvRow(['id', 'grade', 'term', 'title', 'lessonCount', 'charCount', 'writeCount']),
      ...bookRows.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculumDir, 'lessons.tsv'),
    [
      tsvRow(['lessonId', 'bookId', 'unit', 'order', 'title']),
      ...lessonRows.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculumDir, 'lesson_chars.tsv'),
    [
      tsvRow(['lessonId', 'char', 'pinyin', 'isWrite']),
      ...lessonCharRows.map(tsvRow)
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculumDir, 'characters_base.tsv'),
    [
      tsvRow(['char', 'pinyins']),
      ...characterRows.map((row) => tsvRow([row[0], row[1]]))
    ].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculumDir, 'characters.tsv'),
    [
      tsvRow(['char', 'pinyins', 'radical', 'decomposition']),
      ...characterRows.map(tsvRow)
    ].join('\n') + '\n'
  );

  // 组词直接来自教材词语表；多音字例句暂缺，readings 先写空表。
  await writeText(
    path.join(curriculumDir, 'words.tsv'),
    [tsvRow(['char', 'word', 'readingPinyin']), ...wordRows.map(tsvRow)].join('\n') + '\n'
  );
  await writeText(
    path.join(curriculumDir, 'readings.tsv'),
    ['char', 'pinyin', 'lessonId', 'words'].join('\t') + '\n'
  );

  await writeText(
    path.join(curriculumDir, 'meta.tsv'),
    [
      tsvRow(['dataMode', 'full']),
      tsvRow(['dataSource', 'PEP primary school Chinese word lists (MIT dataset)']),
      tsvRow(['dataSourceUrl', 'https://github.com/athenayan123-web/dictation-robot']),
      tsvRow(['dataLicense', 'MIT']),
      tsvRow(['books', String(bookRows.length)]),
      tsvRow(['lessons', String(lessonRows.length)]),
      tsvRow(['uniqueChars', String(characterRows.length)]),
      tsvRow(['generatedAt', nowIso()])
    ].join('\n') + '\n'
  );

  console.log(
    `[curriculum] books=${bookRows.length} lessons=${lessonRows.length} chars=${characterRows.length} words=${wordRows.length}`
  );
  for (const stat of bookStats) {
    console.log(`[curriculum] ${stat.id}: lessons=${stat.lessons} chars=${stat.chars}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
