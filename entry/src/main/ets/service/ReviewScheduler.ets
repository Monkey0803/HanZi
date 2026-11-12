/*
 * ReviewScheduler.ets — 复习间隔与连续天数计算（纯函数）。
 *
 * 不依赖数据库 / UI，便于单元测试。所有时间都是毫秒时间戳，日期按本地时区取。
 */

export class ReviewScheduler {
  /** 通过次数对应的下次复习间隔（天）。 */
  static readonly INTERVALS_DAYS: number[] = [1, 2, 4, 7, 15, 30];
  static readonly DAY_MS: number = 24 * 60 * 60 * 1000;
  /** 「再来」10 分钟后重新出现。 */
  static readonly AGAIN_DELAY_MS: number = 10 * 60 * 1000;
  /** 手动标记已学会后，1 天后再复习。 */
  static readonly LEARNED_DELAY_MS: number = 24 * 60 * 60 * 1000;

  /** 第 passes 次通过后的下次复习时间。 */
  static nextAfterPass(passes: number, now: number): number {
    let index: number = passes - 1;
    if (index < 0) {
      index = 0;
    }
    if (index >= ReviewScheduler.INTERVALS_DAYS.length) {
      index = ReviewScheduler.INTERVALS_DAYS.length - 1;
    }
    return now + ReviewScheduler.INTERVALS_DAYS[index] * ReviewScheduler.DAY_MS;
  }

  /** 自评「再来」后的下次复习时间。 */
  static nextAfterAgain(now: number): number {
    return now + ReviewScheduler.AGAIN_DELAY_MS;
  }

  /** 手动标记已学会后的下次复习时间。 */
  static nextAfterLearned(now: number): number {
    return now + ReviewScheduler.LEARNED_DELAY_MS;
  }

  /** 本地日期文本：YYYY-MM-DD。 */
  static localDateText(ts: number): string {
    const date: Date = new Date(ts);
    const year: string = `${date.getFullYear()}`;
    const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
    const day: string = `${date.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /** 把 YYYY-MM-DD 转成 UTC 天序号，便于比较相邻日期。 */
  static dayIndex(dateText: string): number {
    const parts: string[] = dateText.split('-');
    if (parts.length !== 3) {
      return Number.NaN;
    }
    const year: number = Number.parseInt(parts[0], 10);
    const month: number = Number.parseInt(parts[1], 10);
    const day: number = Number.parseInt(parts[2], 10);
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day)) {
      return Number.NaN;
    }
    return Math.floor(Date.UTC(year, month - 1, day) / ReviewScheduler.DAY_MS);
  }

  /**
   * 连续学习天数。
   * datesDesc 为按日期倒序的本地日期文本；允许以今天或昨天结尾，断档即停止。
   */
  static streak(datesDesc: string[], now: number): number {
    if (datesDesc.length === 0) {
      return 0;
    }
    const today: number = ReviewScheduler.dayIndex(ReviewScheduler.localDateText(now));
    const newest: number = ReviewScheduler.dayIndex(datesDesc[0]);
    if (Number.isNaN(newest) || Number.isNaN(today)) {
      return 0;
    }
    if (newest !== today && newest !== today - 1) {
      return 0;
    }
    let count: number = 1;
    let cursor: number = newest;
    for (let i = 1; i < datesDesc.length; i += 1) {
      const current: number = ReviewScheduler.dayIndex(datesDesc[i]);
      if (Number.isNaN(current)) {
        continue;
      }
      if (current === cursor - 1) {
        count += 1;
        cursor = current;
      } else if (current < cursor - 1) {
        break;
      }
    }
    return count;
  }
}
