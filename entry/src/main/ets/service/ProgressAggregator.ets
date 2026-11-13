/*
 * ProgressAggregator.ets — 不依赖 RDB 的学习进度聚合纯函数。
 */

import { Lesson } from '../model/CurriculumModels';
import { CharProgress } from '../model/ProgressModels';

export class ProgressAggregator {
  static byLesson(items: CharProgress[], lessons: Lesson[]): Map<string, number> {
    const validLessons: Set<string> = new Set<string>();
    const seen: Set<string> = new Set<string>();
    const result: Map<string, number> = new Map<string, number>();
    for (let i = 0; i < lessons.length; i += 1) {
      validLessons.add(lessons[i].id);
    }
    for (let i = 0; i < items.length; i += 1) {
      const item: CharProgress = items[i];
      const key: string = `${item.lessonId}\t${item.character}`;
      if (!item.learned || item.lessonId.length === 0 || !validLessons.has(item.lessonId) || seen.has(key)) {
        continue;
      }
      seen.add(key);
      result.set(item.lessonId, (result.get(item.lessonId) ?? 0) + 1);
    }
    return result;
  }

  static byBook(items: CharProgress[], lessons: Lesson[]): Map<string, number> {
    const lessonBooks: Map<string, string> = new Map<string, string>();
    const seen: Set<string> = new Set<string>();
    const result: Map<string, number> = new Map<string, number>();
    for (let i = 0; i < lessons.length; i += 1) {
      lessonBooks.set(lessons[i].id, lessons[i].bookId);
    }
    for (let i = 0; i < items.length; i += 1) {
      const item: CharProgress = items[i];
      const bookId: string = lessonBooks.get(item.lessonId) ?? '';
      const key: string = `${bookId}\t${item.character}`;
      if (!item.learned || item.lessonId.length === 0 || bookId.length === 0 || seen.has(key)) {
        continue;
      }
      seen.add(key);
      result.set(bookId, (result.get(bookId) ?? 0) + 1);
    }
    return result;
  }

  static mistakeCounts(items: CharProgress[]): Map<string, number> {
    const result: Map<string, number> = new Map<string, number>();
    for (let i = 0; i < items.length; i += 1) {
      if (items[i].character.length > 0 && items[i].mistakes > 0) {
        result.set(items[i].character, items[i].mistakes);
      }
    }
    return result;
  }
}
