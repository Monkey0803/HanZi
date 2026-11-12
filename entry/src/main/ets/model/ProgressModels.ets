/*
 * ProgressModels.ets — 学习进度与复习模型。
 */

/** 单字学习进度（对应 char_progress 表）。 */
export class CharProgress {
  character: string = '';
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
}

/** 复习自评。 */
export enum ReviewRating {
  AGAIN = 0,
  GOOD = 1
}
