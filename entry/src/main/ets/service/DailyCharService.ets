/*
 * DailyCharService.ets — 「每日一字」数据装配。
 *
 * 字表口径：**第一册**（一年级上册）里标记为「会写」的生字（lesson_chars 的 isWrite === 1），
 * 按课顺序去重 —— 首页面向刚起步的学习者，不把六年级的字推到首屏。
 * 选取：DailyCharPicker 用当天日期对字表长度取模，同一天稳定、跨天轮换。
 * 缓存：按 dayKey 记忆，避免每次 build 都遍历课本；数据未就绪时返回 undefined，
 *       页面（首页）此时不渲染该卡片，不抛错。
 */

import { Book, CharacterEntry, LessonChar, WordEntry } from '../model/CurriculumModels';
import { DailyCharPicker } from '../common/utils/DailyCharPicker';
import { curriculumRepository } from './CurriculumRepository';

/** 每日一字的展示数据。 */
export class DailyChar {
  char: string = '';
  pinyin: string = '';
  radical: string = '';
  strokeCount: number = 0;
  /** 出处册名，如「一年级上册」。 */
  bookTitle: string = '';
  /** 出处课 id，用于跳转字详情。 */
  lessonId: string = '';
  /** 组词示例（可能为空串）。 */
  word: string = '';
}

class DailyCharSource {
  char: string = '';
  lessonId: string = '';
  bookTitle: string = '';
}

export class DailyCharService {
  private sources: DailyCharSource[] = [];
  private built: boolean = false;
  private cachedDayKey: number = -1;
  private cached: DailyChar | undefined = undefined;

  private ensureSources(): void {
    if (this.built) {
      return;
    }
    this.built = true;
    const books: Book[] = curriculumRepository.books();
    if (books.length === 0) {
      return;
    }
    const book: Book = books[0];
    const seen: Set<string> = new Set<string>();
    const lessons = curriculumRepository.lessonsOfBook(book.id);
    for (let i = 0; i < lessons.length; i += 1) {
      const chars: LessonChar[] = curriculumRepository.charsOfLesson(lessons[i].id);
      for (let j = 0; j < chars.length; j += 1) {
        const item: LessonChar = chars[j];
        if (item.isWrite !== 1 || seen.has(item.char)) {
          continue;
        }
        seen.add(item.char);
        const source: DailyCharSource = new DailyCharSource();
        source.char = item.char;
        source.lessonId = item.lessonId;
        source.bookTitle = book.title;
        this.sources.push(source);
      }
    }
  }

  /** 当天要展示的字；字表为空（启动加载中 / 失败）时返回 undefined。 */
  current(now: Date = new Date()): DailyChar | undefined {
    this.ensureSources();
    const dayKey: number = DailyCharPicker.dayKeyOf(now);
    if (this.cachedDayKey === dayKey && this.cached !== undefined) {
      return this.cached;
    }
    const index: number = DailyCharPicker.dailyIndex(dayKey, this.sources.length);
    if (index < 0) {
      return undefined;
    }
    const source: DailyCharSource = this.sources[index];
    const entry: CharacterEntry | undefined = curriculumRepository.character(source.char);
    const result: DailyChar = new DailyChar();
    result.char = source.char;
    result.lessonId = source.lessonId;
    result.bookTitle = source.bookTitle;
    if (entry !== undefined) {
      result.pinyin = entry.pinyins.length > 0 ? entry.pinyins[0] : '';
      result.radical = entry.radical;
      result.strokeCount = entry.strokeCount;
    }
    const words: WordEntry[] = curriculumRepository.wordsFor(source.char);
    result.word = words.length > 0 ? words[0].word : '';
    this.cachedDayKey = dayKey;
    this.cached = result;
    return result;
  }
}

export const dailyCharService: DailyCharService = new DailyCharService();
