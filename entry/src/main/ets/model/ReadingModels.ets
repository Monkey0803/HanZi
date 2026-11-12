/*
 * ReadingModels.ets — 识字短文（阅读）数据模型。
 *
 * 与 rawfile 的 curriculum/passages.tsv 一一对应；只放纯数据，不带 IO / UI 依赖。
 */

/** 一篇识字短文。 */
export class Passage {
  /** 全局唯一，如 'G1A01-P1'。 */
  id: string = '';
  lessonId: string = '';
  /** 课内顺序，从 1 开始。 */
  order: number = 0;
  title: string = '';
  /** 单行正文；不含制表符/换行。 */
  text: string = '';
  /** 多音字读音覆盖：char → pinyin。 */
  overrides: Map<string, string> = new Map();
}

/** 正文里的一格：一个汉字或一个标点。 */
export class PassageGlyph {
  char: string = '';
  /** 拼音；标点为空串。 */
  pinyin: string = '';
  /** 汉字：可点、可显示拼音。 */
  isHan: boolean = false;
  /** 本课生字：高亮。 */
  isFocus: boolean = false;
}
