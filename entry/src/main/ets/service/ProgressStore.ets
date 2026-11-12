/*
 * ProgressStore.ets — 学习进度可观察状态（@ObservedV2 单例）。
 *
 * 视图只读这里的 @Trace 字段；所有写操作先同步更新内存 map，再落库并刷新统计，
 * 避免连续点击时读到旧值互相覆盖。
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CharProgress, PracticeLogEntry, ReviewRating } from '../model/ProgressModels';
import { ReviewConstants } from '../common/constants/ReviewConstants';
import { ProgressRepository, progressRepository } from './ProgressRepository';
import { appDatabase } from './AppDatabase';
import { ReviewScheduler } from './ReviewScheduler';

@ObservedV2
export class ProgressStore {
  @Trace ready: boolean = false;
  @Trace loading: boolean = false;
  @Trace errorMessage: string = '';
  @Trace learnedChars: string[] = [];
  @Trace dueChars: string[] = [];
  @Trace mistakeChars: string[] = [];
  @Trace learnedCount: number = 0;
  @Trace dueCount: number = 0;
  @Trace mistakeCount: number = 0;
  @Trace todayCount: number = 0;
  @Trace streakDays: number = 0;
  @Trace accuracy: number = 0;
  @Trace attemptCount: number = 0;

  private progressMap: Map<string, CharProgress> = new Map();
  private repository: ProgressRepository = progressRepository;

  /** 打开数据库并加载进度；失败时置 errorMessage，不向外抛。 */
  async load(context: common.Context): Promise<void> {
    if (this.ready || this.loading) {
      return;
    }
    this.loading = true;
    this.errorMessage = '';
    try {
      await appDatabase.open(context);
      const items: CharProgress[] = await this.repository.loadAll();
      const map: Map<string, CharProgress> = new Map();
      for (let i = 0; i < items.length; i += 1) {
        map.set(items[i].character, items[i]);
      }
      this.progressMap = map;
      this.ready = true;
      await this.refresh();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      this.ready = false;
      this.errorMessage = error.message.length > 0 ? error.message : '学习进度加载失败';
      console.error(`ProgressStore.load failed: ${error.code} ${this.errorMessage}`);
    } finally {
      this.loading = false;
    }
  }

  /** 重新计算统计与列表；所有派生数组都用新数组赋值。 */
  async refresh(): Promise<void> {
    if (!this.ready) {
      return;
    }
    const now: number = Date.now();
    const start: Date = new Date(now);
    start.setHours(0, 0, 0, 0);
    try {
      const stats = await this.repository.stats(now, start.getTime());
      const due: string[] = await this.repository.dueChars(now, ReviewConstants.MAX_LIMIT * 10);
      const learned: string[] = await this.repository.learnedChars(ReviewConstants.MAX_LIMIT * 10);
      const mistakes: string[] = await this.repository.mistakeChars(ReviewConstants.MAX_LIMIT * 10);
      this.learnedCount = stats.learnedCount;
      this.dueCount = stats.dueCount;
      this.mistakeCount = stats.mistakeCount;
      this.todayCount = stats.todayCount;
      this.streakDays = stats.streakDays;
      this.accuracy = stats.accuracy;
      this.attemptCount = stats.attemptCount;
      this.dueChars = due;
      this.learnedChars = learned;
      this.mistakeChars = mistakes;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`ProgressStore.refresh failed: ${error.code}`);
    }
  }

  /** 跨天或回到前台时刷新今日统计。 */
  refreshToday(): void {
    if (!this.ready) {
      return;
    }
    this.refresh().catch((err: BusinessError) => {
      console.error(`ProgressStore.refreshToday failed: ${err.code}`);
    });
  }

  isLearned(char: string): boolean {
    return this.learnedChars.indexOf(char) >= 0;
  }

  lessonOf(char: string): string {
    const item: CharProgress | undefined = this.progressMap.get(char);
    return item !== undefined ? item.lessonId : '';
  }

  /** 描红练习完成：写进度与练习日志。 */
  async recordPractice(char: string, lessonId: string, mistakes: number, durationMs: number): Promise<void> {
    if (!this.ready || char.length === 0) {
      return;
    }
    const now: number = Date.now();
    const progress: CharProgress = this.progressMap.get(char) ?? new CharProgress();
    progress.character = char;
    if (lessonId.length > 0) {
      progress.lessonId = lessonId;
    }
    progress.attempts += 1;
    progress.mistakes = mistakes;
    progress.lastPracticed = now;
    if (mistakes <= ReviewConstants.PASS_MISTAKE_LIMIT) {
      progress.passes += 1;
      progress.learned = true;
      progress.nextReview = ReviewScheduler.nextAfterPass(progress.passes, now);
    } else {
      progress.nextReview = ReviewScheduler.nextAfterAgain(now);
    }
    this.progressMap.set(char, progress);
    await this.persist(progress, 0, durationMs);
  }

  /** 手动标记 / 取消已学会。 */
  async toggleLearned(char: string, lessonId: string): Promise<void> {
    if (!this.ready || char.length === 0) {
      return;
    }
    const now: number = Date.now();
    const progress: CharProgress = this.progressMap.get(char) ?? new CharProgress();
    progress.character = char;
    if (lessonId.length > 0) {
      progress.lessonId = lessonId;
    }
    progress.learned = !progress.learned;
    progress.lastPracticed = now;
    progress.nextReview = progress.learned ? ReviewScheduler.nextAfterLearned(now) : 0;
    this.progressMap.set(char, progress);
    await this.persist(progress, 0, 0);
  }

  /** 复习自评：会了 / 再来。 */
  async rateReview(char: string, lessonId: string, rating: ReviewRating): Promise<void> {
    if (!this.ready || char.length === 0) {
      return;
    }
    const now: number = Date.now();
    const progress: CharProgress = this.progressMap.get(char) ?? new CharProgress();
    progress.character = char;
    if (lessonId.length > 0) {
      progress.lessonId = lessonId;
    }
    progress.attempts += 1;
    progress.lastPracticed = now;
    if (rating === ReviewRating.GOOD) {
      progress.passes += 1;
      progress.learned = true;
      progress.mistakes = 0;
      progress.nextReview = ReviewScheduler.nextAfterPass(progress.passes, now);
    } else {
      progress.mistakes += 1;
      progress.nextReview = ReviewScheduler.nextAfterAgain(now);
    }
    this.progressMap.set(char, progress);
    await this.persist(progress, rating === ReviewRating.GOOD ? 1 : 2, 0);
  }

  private async persist(progress: CharProgress, rating: number, durationMs: number): Promise<void> {
    try {
      await this.repository.save(progress);
      const entry: PracticeLogEntry = new PracticeLogEntry();
      entry.character = progress.character;
      entry.lessonId = progress.lessonId;
      entry.timestamp = progress.lastPracticed;
      entry.mistakes = progress.mistakes;
      entry.durationMs = durationMs;
      entry.rating = rating;
      await this.repository.log(entry);
      await this.refresh();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`ProgressStore.persist failed: ${error.code}`);
    }
  }
}

export const progressStore: ProgressStore = new ProgressStore();
