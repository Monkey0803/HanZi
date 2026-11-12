/*
 * ReadingViewModel.ets — 按课的阅读状态（短文 + 逐字 glyph 缓存）。
 *
 * 一个课详情页持有一个实例；数据在 load() 时一次性构建，之后只读，
 * 拼音开关只影响渲染，不重复构建 glyph。
 */

import { CharacterEntry, LessonChar } from '../model/CurriculumModels';
import { Passage, PassageGlyph } from '../model/ReadingModels';
import { curriculumRepository } from '../service/CurriculumRepository';
import { readingRepository } from '../service/ReadingRepository';
import { ReadingTextBuilder } from '../service/ReadingTextBuilder';

@ObservedV2
export class ReadingViewModel {
  @Trace passages: Passage[] = [];

  private glyphCache: Map<string, PassageGlyph[]> = new Map();
  private focusPinyin: Map<string, string> = new Map();

  /** 载入某课的短文；无数据时 passages 为空数组。 */
  load(lessonId: string): void {
    this.glyphCache = new Map();
    const focusPinyin: Map<string, string> = new Map();
    const chars: LessonChar[] = curriculumRepository.charsOfLesson(lessonId);
    for (let i = 0; i < chars.length; i += 1) {
      if (chars[i].char.length > 0) {
        focusPinyin.set(chars[i].char, chars[i].pinyin);
      }
    }
    const list: Passage[] = readingRepository.passagesOfLesson(lessonId);
    const allPinyin: Map<string, string> = this.collectPinyin(list);
    const result: Passage[] = [];
    for (let i = 0; i < list.length; i += 1) {
      const passage: Passage = list[i];
      this.glyphCache.set(passage.id,
        ReadingTextBuilder.build(passage.text, focusPinyin, allPinyin, passage.overrides));
      result.push(passage);
    }
    this.focusPinyin = focusPinyin;
    this.passages = result;
  }

  hasReading(): boolean {
    return this.passages.length > 0;
  }

  glyphsOf(passageId: string): PassageGlyph[] {
    return this.glyphCache.get(passageId) ?? [];
  }

  /** 小测候选：本课生字（保持课文顺序）。 */
  focusChars(): string[] {
    const result: string[] = [];
    this.focusPinyin.forEach((_pinyin: string, char: string) => {
      result.push(char);
    });
    return result;
  }

  pinyinOf(char: string): string {
    return this.focusPinyin.get(char) ?? '';
  }

  /** 只为短文里出现过的字建读音表，避免整册遍历。 */
  private collectPinyin(list: Passage[]): Map<string, string> {
    const result: Map<string, string> = new Map();
    for (let i = 0; i < list.length; i += 1) {
      const chars: string[] = Array.from(list[i].text);
      for (let j = 0; j < chars.length; j += 1) {
        const char: string = chars[j];
        if (!ReadingTextBuilder.isHan(char) || result.has(char)) {
          continue;
        }
        const entry: CharacterEntry | undefined = curriculumRepository.character(char);
        if (entry !== undefined && entry.pinyins.length > 0) {
          result.set(char, entry.pinyins[0]);
        }
      }
    }
    return result;
  }
}
