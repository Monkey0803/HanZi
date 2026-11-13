/*
 * PracticeLayoutPolicy.ets — 练字页纯布局策略。
 *
 * 页面只把真实可用区域传入本策略；策略不依赖 ArkUI，可直接覆盖边界单测。
 */

export class PracticeLayoutPolicy {
  /** 小方外屏：窗口两边均不大于 600vp，且宽高比接近 1:1。 */
  static isCompactWindow(width: number, height: number): boolean {
    if (!PracticeLayoutPolicy.isValidSize(width, height)) {
      return false;
    }
    const ratio: number = width / height;
    return width <= 600 && height <= 600 && ratio >= 0.8 && ratio <= 1.25;
  }

  /**
   * 按区域短边计算等边画布。区域不足最小值时优先保证不溢出；空间充足时钳位在设计范围内。
   */
  static canvasSize(width: number, height: number, compact: boolean, normalMin: number = 220,
    compactMin: number = 144, cap: number = 480, areaMargin: number = 32): number {
    if (!PracticeLayoutPolicy.isValidSize(width, height) || normalMin <= 0 || compactMin <= 0 || cap <= 0) {
      return 0;
    }
    const available: number = Math.floor(Math.min(width, height) - Math.max(0, areaMargin));
    if (available <= 0) {
      return 0;
    }
    const minimum: number = compact ? compactMin : normalMin;
    if (available < minimum) {
      return available;
    }
    return Math.round(Math.min(cap, Math.max(minimum, available)));
  }

  private static isValidSize(width: number, height: number): boolean {
    return Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0;
  }
}
