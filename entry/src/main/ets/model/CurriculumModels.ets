/*
 * CurriculumModels.ets — 课程数据模型（与 rawfile TSV 字段一一对应）。
 *
 * 只放纯数据类，不带任何 IO / UI 依赖；构造时给全默认值，避免 ArkTS 的
 * 「属性未初始化」与对象字面量类型推断问题。
 */

/** 册（一年级上册 … 六年级下册）。 */
export class Book {
  /** 册 id：'1a' … '6b'。 */
  id: string = '';
  /** 年级：1 … 6。 */
  grade: number = 0;
  /** 学期：1 = 上册，2 = 下册。 */
  term: number = 0;
  /** 册名：'一年级上册'。 */
  title: string = '';
  lessonCount: number = 0;
  charCount: number = 0;
  writeCount: number = 0;
}

/** 课文。 */
export class Lesson {
  id: string = '';
  bookId: string = '';
  unit: number = 0;
  order: number = 0;
  title: string = '';
  /** 本课生字（由 lesson_chars.tsv 回填）。 */
  chars: LessonChar[] = [];
}

/** 单元（由课文按 unit 聚合而成）。 */
export class Unit {
  index: number = 0;
  lessons: Lesson[] = [];
}

/** 课内某个生字。 */
export class LessonChar {
  lessonId: string = '';
  char: string = '';
  pinyin: string = '';
  /** 1 = 会写，0 = 只认读。 */
  isWrite: number = 0;
}

/** 字条：拼音、部首、部件拆解。 */
export class CharacterEntry {
  char: string = '';
  /** 多音字按 ';' 拆分后的读音。 */
  pinyins: string[] = [];
  radical: string = '';
  decomposition: string = '';
}

/** 词语（组词）。 */
export class WordEntry {
  char: string = '';
  word: string = '';
  readingPinyin: string = '';
}

/** 多音字读音及其例词、出处课号。 */
export class Reading {
  char: string = '';
  pinyin: string = '';
  lessonId: string = '';
  words: string[] = [];
}
