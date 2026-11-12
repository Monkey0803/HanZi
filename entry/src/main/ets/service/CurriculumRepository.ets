/*
 * CurriculumRepository.ets — 课程 TSV 仓库。
 *
 * 启动时一次性把 curriculum/*.tsv 读进内存（约 1 MB），之后全部走内存索引。
 * 同音字 / 同部首字由本地索引计算，不额外抓字详情页。
 */

import { common } from '@kit.AbilityKit';
import { CharacterEntry, Book, Lesson, LessonChar, Reading, Unit, WordEntry } from '../model/CurriculumModels';
import { dataRootResolver } from './DataRootResolver';
import { PinyinUtils } from './PinyinUtils';
import { TsvUtil } from './TsvUtil';

export class CurriculumRepository {
  private loaded: boolean = false;
  private bookList: Book[] = [];
  private bookMap: Map<string, Book> = new Map();
  private lessonList: Lesson[] = [];
  private lessonMap: Map<string, Lesson> = new Map();
  private unitMap: Map<string, Unit[]> = new Map();
  private charMap: Map<string, CharacterEntry> = new Map();
  private charList: CharacterEntry[] = [];
  private lessonCharsMap: Map<string, LessonChar[]> = new Map();
  private wordMap: Map<string, WordEntry[]> = new Map();
  private readingMap: Map<string, Reading[]> = new Map();
  private metaMap: Map<string, string> = new Map();
  private pinyinIndex: Map<string, string[]> = new Map();
  private radicalIndex: Map<string, string[]> = new Map();
  private indexesBuilt: boolean = false;

  /** 读取全部课程数据；重复调用直接返回。 */
  async load(context: common.Context): Promise<void> {
    if (this.loaded) {
      return;
    }
    if (dataRootResolver.currentRoot().length === 0) {
      throw new Error('课程数据根尚未解析');
    }
    const booksText: string = await dataRootResolver.readRootText(context, 'curriculum/books.tsv');
    const lessonsText: string = await dataRootResolver.readRootText(context, 'curriculum/lessons.tsv');
    const lessonCharsText: string = await dataRootResolver.readRootText(context, 'curriculum/lesson_chars.tsv');
    const charactersText: string = await dataRootResolver.readRootText(context, 'curriculum/characters.tsv');
    const wordsText: string = await dataRootResolver.readRootText(context, 'curriculum/words.tsv');
    const readingsText: string = await dataRootResolver.readRootText(context, 'curriculum/readings.tsv');
    const metaText: string = await dataRootResolver.readRootText(context, 'curriculum/meta.tsv');

    this.parseCharacters(charactersText);
    this.parseLessons(lessonsText);
    this.parseLessonChars(lessonCharsText);
    this.parseBooks(booksText);
    this.parseWords(wordsText);
    this.parseReadings(readingsText);
    this.parseMeta(metaText);
    this.buildUnits();
    this.markCurriculumFlags();
    this.loaded = true;
  }

  isLoaded(): boolean {
    return this.loaded;
  }

  /** 全部册，按年级学期排序。 */
  books(): Book[] {
    return this.bookList;
  }

  book(id: string): Book | undefined {
    return this.bookMap.get(id);
  }

  lesson(id: string): Lesson | undefined {
    return this.lessonMap.get(id);
  }

  unitsOfBook(bookId: string): Unit[] {
    return this.unitMap.get(bookId) ?? [];
  }

  lessonsOfBook(bookId: string): Lesson[] {
    const result: Lesson[] = [];
    const units: Unit[] = this.unitsOfBook(bookId);
    for (let i = 0; i < units.length; i += 1) {
      const lessons: Lesson[] = units[i].lessons;
      for (let j = 0; j < lessons.length; j += 1) {
        result.push(lessons[j]);
      }
    }
    return result;
  }

  charsOfLesson(lessonId: string): LessonChar[] {
    return this.lessonCharsMap.get(lessonId) ?? [];
  }

  character(char: string): CharacterEntry | undefined {
    return this.charMap.get(char);
  }

  allCharacters(): CharacterEntry[] {
    return this.charList;
  }

  wordsFor(char: string): WordEntry[] {
    return this.wordMap.get(char) ?? [];
  }

  readingsFor(char: string): Reading[] {
    return this.readingMap.get(char) ?? [];
  }

  /** 同音字（按该字的每个读音分组匹配，去重）。 */
  homophones(char: string): CharacterEntry[] {
    this.ensureIndexes();
    const entry: CharacterEntry | undefined = this.charMap.get(char);
    if (entry === undefined) {
      return [];
    }
    const result: CharacterEntry[] = [];
    const seen: Set<string> = new Set<string>();
    for (let i = 0; i < entry.pinyins.length; i += 1) {
      const samePinyin: string[] = this.pinyinIndex.get(entry.pinyins[i]) ?? [];
      for (let j = 0; j < samePinyin.length; j += 1) {
        const other: string = samePinyin[j];
        if (other === char || seen.has(other)) {
          continue;
        }
        const otherEntry: CharacterEntry | undefined = this.charMap.get(other);
        if (otherEntry !== undefined) {
          seen.add(other);
          result.push(otherEntry);
        }
        if (result.length >= 30) {
          return result;
        }
      }
    }
    return result;
  }

  /** 同部首字。 */
  sameRadical(char: string): CharacterEntry[] {
    this.ensureIndexes();
    const entry: CharacterEntry | undefined = this.charMap.get(char);
    if (entry === undefined || entry.radical.length === 0) {
      return [];
    }
    const chars: string[] = this.radicalIndex.get(entry.radical) ?? [];
    const result: CharacterEntry[] = [];
    for (let i = 0; i < chars.length; i += 1) {
      if (chars[i] === char) {
        continue;
      }
      const otherEntry: CharacterEntry | undefined = this.charMap.get(chars[i]);
      if (otherEntry !== undefined) {
        result.push(otherEntry);
      }
      if (result.length >= 30) {
        break;
      }
    }
    return result;
  }

  /** meta.tsv 单项。 */
  meta(key: string, fallback: string = ''): string {
    return this.metaMap.get(key) ?? fallback;
  }

  /** 全量字表（教材字 + 通用字），未做过滤。 */
  catalogCharacters(): CharacterEntry[] {
    return this.charList;
  }

  /** 指定口径的字表数量；带笔画分段时按分段统计。 */
  catalogCount(scope: string, band: string): number {
    let count: number = 0;
    for (let i = 0; i < this.charList.length; i += 1) {
      if (this.inScope(this.charList[i], scope) && this.inBand(this.charList[i], band)) {
        count += 1;
      }
    }
    return count;
  }

  /** 字表中出现过的部首，按字符序排列。 */
  catalogRadicals(): string[] {
    this.ensureIndexes();
    const radicals: string[] = [];
    this.radicalIndex.forEach((_chars: string[], radical: string) => {
      if (radical.length > 0) {
        radicals.push(radical);
      }
    });
    radicals.sort((a: string, b: string) => a.localeCompare(b));
    return radicals;
  }

  /**
   * 查字：汉字子串优先，其次拼音前缀，再次部首完全匹配。
   * 结果按「教材字优先 → 笔画数 → 字符码」排序。
   */
  searchCatalog(query: string, scope: string, band: string, radical: string, limit: number): CharacterEntry[] {
    const trimmed: string = query.trim();
    const normalizedQuery: string = PinyinUtils.normalize(trimmed);
    const matched: CharacterEntry[] = [];
    for (let i = 0; i < this.charList.length; i += 1) {
      const entry: CharacterEntry = this.charList[i];
      if (!this.inScope(entry, scope) || !this.inBand(entry, band)) {
        continue;
      }
      if (radical.length > 0 && entry.radical !== radical) {
        continue;
      }
      if (trimmed.length === 0) {
        matched.push(entry);
        continue;
      }
      if (entry.char.indexOf(trimmed) >= 0 || PinyinUtils.matches(entry.pinyins, normalizedQuery)) {
        matched.push(entry);
      }
    }
    matched.sort((a: CharacterEntry, b: CharacterEntry) => {
      if (a.inCurriculum !== b.inCurriculum) {
        return a.inCurriculum ? -1 : 1;
      }
      if (a.strokeCount !== b.strokeCount) {
        return a.strokeCount - b.strokeCount;
      }
      return a.char.localeCompare(b.char);
    });
    return limit > 0 && matched.length > limit ? matched.slice(0, limit) : matched;
  }

  private inScope(entry: CharacterEntry, scope: string): boolean {
    if (scope === 'curriculum') {
      return entry.inCurriculum;
    }
    if (scope === 'common') {
      return !entry.inCurriculum;
    }
    return true;
  }

  private inBand(entry: CharacterEntry, band: string): boolean {
    const count: number = entry.strokeCount;
    if (band === '1-4') {
      return count >= 1 && count <= 4;
    }
    if (band === '5-8') {
      return count >= 5 && count <= 8;
    }
    if (band === '9-12') {
      return count >= 9 && count <= 12;
    }
    if (band === '13+') {
      return count >= 13;
    }
    return true;
  }

  private markCurriculumFlags(): void {
    this.lessonCharsMap.forEach((items: LessonChar[]) => {
      for (let i = 0; i < items.length; i += 1) {
        const entry: CharacterEntry | undefined = this.charMap.get(items[i].char);
        if (entry !== undefined) {
          entry.inCurriculum = true;
        }
      }
    });
  }

  private parseBooks(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const book: Book = new Book();
      book.id = TsvUtil.at(row, 0);
      book.grade = TsvUtil.numberAt(row, 1);
      // books.tsv 的 term 是 'a'（上册）/ 'b'（下册），对外统一成 1 / 2。
      const rawTerm: string = TsvUtil.at(row, 2);
      book.term = rawTerm === 'a' ? 1 : (rawTerm === 'b' ? 2 : TsvUtil.numberAt(row, 2));
      book.title = TsvUtil.at(row, 3);
      book.lessonCount = TsvUtil.numberAt(row, 4);
      book.charCount = TsvUtil.numberAt(row, 5);
      book.writeCount = TsvUtil.numberAt(row, 6);
      if (book.id.length === 0) {
        continue;
      }
      this.bookList.push(book);
      this.bookMap.set(book.id, book);
    }
  }

  private parseLessons(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const lesson: Lesson = new Lesson();
      lesson.id = TsvUtil.at(row, 0);
      lesson.bookId = TsvUtil.at(row, 1);
      lesson.unit = TsvUtil.numberAt(row, 2);
      lesson.order = TsvUtil.numberAt(row, 3);
      lesson.title = TsvUtil.at(row, 4);
      if (lesson.id.length === 0) {
        continue;
      }
      this.lessonList.push(lesson);
      this.lessonMap.set(lesson.id, lesson);
    }
  }

  private parseLessonChars(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const item: LessonChar = new LessonChar();
      item.lessonId = TsvUtil.at(row, 0);
      item.char = TsvUtil.at(row, 1);
      item.pinyin = TsvUtil.at(row, 2);
      item.isWrite = TsvUtil.numberAt(row, 3);
      if (item.lessonId.length === 0 || item.char.length === 0) {
        continue;
      }
      const list: LessonChar[] = this.lessonCharsMap.get(item.lessonId) ?? [];
      list.push(item);
      this.lessonCharsMap.set(item.lessonId, list);
      const lesson: Lesson | undefined = this.lessonMap.get(item.lessonId);
      if (lesson !== undefined) {
        lesson.chars.push(item);
      }
    }
  }

  private parseCharacters(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const entry: CharacterEntry = new CharacterEntry();
      entry.char = TsvUtil.at(row, 0);
      entry.pinyins = TsvUtil.splitList(TsvUtil.at(row, 1), ';');
      entry.radical = TsvUtil.at(row, 2);
      entry.decomposition = TsvUtil.at(row, 3);
      entry.strokeCount = TsvUtil.numberAt(row, 4);
      if (entry.char.length === 0) {
        continue;
      }
      this.charMap.set(entry.char, entry);
      this.charList.push(entry);
    }
  }

  private parseWords(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const entry: WordEntry = new WordEntry();
      entry.char = TsvUtil.at(row, 0);
      entry.word = TsvUtil.at(row, 1);
      entry.readingPinyin = TsvUtil.at(row, 2);
      if (entry.char.length === 0 || entry.word.length === 0) {
        continue;
      }
      const list: WordEntry[] = this.wordMap.get(entry.char) ?? [];
      list.push(entry);
      this.wordMap.set(entry.char, list);
    }
  }

  private parseReadings(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const reading: Reading = new Reading();
      reading.char = TsvUtil.at(row, 0);
      reading.pinyin = TsvUtil.at(row, 1);
      reading.lessonId = TsvUtil.at(row, 2);
      reading.words = TsvUtil.splitList(TsvUtil.at(row, 3), '|');
      if (reading.char.length === 0 || reading.pinyin.length === 0) {
        continue;
      }
      const list: Reading[] = this.readingMap.get(reading.char) ?? [];
      list.push(reading);
      this.readingMap.set(reading.char, list);
    }
  }

  private parseMeta(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      const key: string = TsvUtil.at(row, 0);
      if (key.length > 0) {
        this.metaMap.set(key, TsvUtil.at(row, 1));
      }
    }
  }

  private buildUnits(): void {
    for (let i = 0; i < this.bookList.length; i += 1) {
      this.unitMap.set(this.bookList[i].id, []);
    }
    for (let i = 0; i < this.lessonList.length; i += 1) {
      const lesson: Lesson = this.lessonList[i];
      let units: Unit[] = this.unitMap.get(lesson.bookId) ?? [];
      let unit: Unit | undefined = undefined;
      for (let j = 0; j < units.length; j += 1) {
        if (units[j].index === lesson.unit) {
          unit = units[j];
          break;
        }
      }
      if (unit === undefined) {
        unit = new Unit();
        unit.index = lesson.unit;
        units.push(unit);
        units.sort((a: Unit, b: Unit) => a.index - b.index);
        this.unitMap.set(lesson.bookId, units);
      }
      unit.lessons.push(lesson);
    }
    for (let i = 0; i < this.bookList.length; i += 1) {
      const units: Unit[] = this.unitMap.get(this.bookList[i].id) ?? [];
      for (let j = 0; j < units.length; j += 1) {
        units[j].lessons.sort((a: Lesson, b: Lesson) => a.order - b.order);
      }
    }
  }

  private ensureIndexes(): void {
    if (this.indexesBuilt) {
      return;
    }
    for (let i = 0; i < this.charList.length; i += 1) {
      const entry: CharacterEntry = this.charList[i];
      for (let j = 0; j < entry.pinyins.length; j += 1) {
        const pinyin: string = entry.pinyins[j];
        const chars: string[] = this.pinyinIndex.get(pinyin) ?? [];
        chars.push(entry.char);
        this.pinyinIndex.set(pinyin, chars);
      }
      if (entry.radical.length > 0) {
        const sameRadical: string[] = this.radicalIndex.get(entry.radical) ?? [];
        sameRadical.push(entry.char);
        this.radicalIndex.set(entry.radical, sameRadical);
      }
    }
    this.indexesBuilt = true;
  }
}

export const curriculumRepository: CurriculumRepository = new CurriculumRepository();
