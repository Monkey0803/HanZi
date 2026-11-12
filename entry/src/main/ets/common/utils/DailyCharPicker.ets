/*
 * DailyCharPicker.ets — 「每日一字」的纯选取逻辑（可单测，不依赖设备 / Context）。
 *
 * 目标：同一天稳定返回同一个字、跨天自然轮换，且不引入随机数（重启后仍然一致）。
 * 做法：把日期压成整数 dayKey（y*10000+m*100+d），对字表长度取模。
 */

export class DailyCharPicker {
  /** 本地日期 → 整数 key（20261112）。 */
  static dayKeyOf(date: Date): number {
    return date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();
  }

  /** 取下标；空字表返回 -1（调用方据此不渲染该卡片）。 */
  static dailyIndex(dayKey: number, size: number): number {
    if (size <= 0) {
      return -1;
    }
    const key: number = dayKey < 0 ? -dayKey : dayKey;
    return key % size;
  }
}
