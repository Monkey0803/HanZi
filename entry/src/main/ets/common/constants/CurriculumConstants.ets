/*
 * CurriculumConstants.ets — 课程展示用纯常量与纯函数。
 *
 * 只放与 UI 无关的映射逻辑，供首页册卡与册详情页共用，避免年级字规则两处维护。
 */

import { Book } from '../../model/CurriculumModels';

/** 年级 → 田字格展示字（一 ~ 六）。 */
export const GRADE_GLYPHS: string[] = ['一', '二', '三', '四', '五', '六'];

/** 取册对应的年级展示字；异常数据回退到册名首字。 */
export function gradeGlyphOf(book: Book): string {
  const index: number = book.grade - 1;
  if (index >= 0 && index < GRADE_GLYPHS.length) {
    return GRADE_GLYPHS[index];
  }
  return book.title.length > 0 ? book.title.substring(0, 1) : '';
}
