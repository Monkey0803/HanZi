/*
 * StrokeNumberLayout.ets — 笔顺序号锚点计算（纯函数，1024 数据坐标 → 屏幕坐标）。
 *
 * 参考 animCJK 的序号摆放：从起笔点沿书写方向内移半个徽标，
 * 再夹到字格内，避免序号越界或压住起笔。
 */

import { Point } from '../model/StrokeModels';
import { StrokeGeometry } from './StrokeGeometry';
import {
  NUMBER_DIRECTION_MIN_LENGTH,
  NUMBER_MAX_RADIUS,
  NUMBER_MIN_RADIUS,
  NUMBER_OFFSET_RATIO,
  NUMBER_RADIUS_RATIO
} from '../common/constants/StrokeConstants';

/** 序号徽标圆心（屏幕坐标）。 */
export class NumberAnchor {
  x: number = 0;
  y: number = 0;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }
}

export class StrokeNumberLayout {
  /** 徽标半径随画布大小变化，并夹到可读区间。 */
  static radiusFor(size: number): number {
    const raw: number = size * NUMBER_RADIUS_RATIO;
    return Math.max(NUMBER_MIN_RADIUS, Math.min(NUMBER_MAX_RADIUS, raw));
  }

  /** 第 index 笔（给定 median）的序号圆心。 */
  static anchor(median: Point[], size: number, padding: number, radius: number): NumberAnchor {
    const min: number = padding + radius;
    const max: number = size - padding - radius;
    const fallback: NumberAnchor = new NumberAnchor(StrokeNumberLayout.clamp(min, min, max),
      StrokeNumberLayout.clamp(min, min, max));
    if (median.length === 0 || size <= 0) {
      return fallback;
    }
    const scale: number = (size - 2 * padding) / 1024;
    if (scale <= 0) {
      return fallback;
    }
    const start: Point = median[0];
    const startX: number = padding + start.x * scale;
    const startY: number = padding + (900 - start.y) * scale;
    const target: Point = StrokeGeometry.pointAtLength(median, NUMBER_DIRECTION_MIN_LENGTH);
    const dx: number = (target.x - start.x) * scale;
    const dy: number = -(target.y - start.y) * scale;
    const length: number = Math.sqrt(dx * dx + dy * dy);
    if (length < 0.001) {
      return new NumberAnchor(StrokeNumberLayout.clamp(startX, min, max),
        StrokeNumberLayout.clamp(startY, min, max));
    }
    const offset: number = radius * NUMBER_OFFSET_RATIO;
    const centerX: number = startX + (dx / length) * offset;
    const centerY: number = startY + (dy / length) * offset;
    return new NumberAnchor(StrokeNumberLayout.clamp(centerX, min, max),
      StrokeNumberLayout.clamp(centerY, min, max));
  }

  private static clamp(value: number, min: number, max: number): number {
    if (max < min) {
      return (min + max) / 2;
    }
    return Math.max(min, Math.min(max, value));
  }
}
