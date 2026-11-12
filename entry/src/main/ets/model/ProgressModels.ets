/*
 * ProgressModels.ets — 学习进度与复习模型。
 */

/** 单字学习进度（对应 char_progress 表）。 */
export class CharProgress {
  character: string = '';
  /** 最近一次关联的课号；用于从复习卡回到字详情。 */
  lessonId: string = '';
  learned: boolean = false;
  attempts: number = 0;
  passes: number = 0;
  mistakes: number = 0;
  /** 毫秒时间戳。 */
  lastPracticed: number = 0;
  /** 毫秒时间戳；0 表示尚未安排。 */
  nextReview: number = 0;
}

/** 课文进度（对应 lesson_progress 表）。 */
export class LessonProgress {
  lessonId: string = '';
  learnedChars: number = 0;
  totalChars: number = 0;
  completed: boolean = false;
  lastStudied: number = 0;
}

/** 一次练习记录（对应 practice_log 表）。 */
export class PracticeLogEntry {
  character: string = '';
  lessonId: string = '';
  timestamp: number = 0;
  mistakes: number = 0;
  durationMs: number = 0;
  /** 0 = 普通练习，1 = 复习「会了」，2 = 复习「再来」。 */
  rating: number = 0;
}

/** 汇总统计。 */
export class PracticeStats {
  learnedCount: number = 0;
  totalChars: number = 0;
  dueCount: number = 0;
  mistakeCount: number = 0;
  todayCount: number = 0;
  streakDays: number = 0;
  accuracy: number = 0;
  /** 累计练习次数；0 时正确率显示占位符。 */
  attemptCount: number = 0;
}

/** 复习自评。 */
export enum ReviewRating {
  AGAIN = 0,
  GOOD = 1
}

/** 一张复习卡。 */
export class ReviewCard {
  char: string = '';
  pinyin: string = '';
  word: string = '';
  lessonId: string = '';
  /** 「再来」重排后的卡标记，避免无限重排。 */
  requeued: boolean = false;

  constructor(char: string = '', pinyin: string = '', word: string = '', lessonId: string = '',
    requeued: boolean = false) {
    this.char = char;
    this.pinyin = pinyin;
    this.word = word;
    this.lessonId = lessonId;
    this.requeued = requeued;
  }
}
