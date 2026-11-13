/*
 * StrokeRenderer.ets — 在 Canvas 上绘制田字格与笔画。
 *
 * 数据坐标 → 屏幕坐标统一用 setTransform(scale, 0, 0, -scale, padding, padding + 900 * scale)；
 * 网格 / 文字在屏幕坐标绘制，避免被 y 翻转。
 */

import { PathCommand, PathOp, Point, StrokeData, StrokeTheme } from '../model/StrokeModels';
import { StrokeGeometry } from './StrokeGeometry';
import { NumberAnchor, StrokeNumberLayout } from './StrokeNumberLayout';
import {
  ARROW_LENGTH_VP,
  ARROW_POSITION_RATIO,
  GridStyleId,
  NUMBER_MIN_CANVAS_VP,
  SKELETON_LINE_VP
} from '../common/constants/StrokeConstants';

export class StrokeRenderer {
  /** 数据坐标的缩放系数。 */
  static scaleFor(size: number, padding: number): number {
    return (size - 2 * padding) / 1024;
  }

  /** 套用数据坐标变换。 */
  static applyTransform(ctx: CanvasRenderingContext2D, size: number, padding: number): void {
    const scale: number = StrokeRenderer.scaleFor(size, padding);
    ctx.setTransform(scale, 0, 0, -scale, padding, padding + 900 * scale);
  }

  /** 恢复屏幕坐标。 */
  static resetTransform(ctx: CanvasRenderingContext2D): void {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
  }

  /** 字格：外框 + 十字 / 对角线 / 三等分线（屏幕坐标）。 */
  static drawGrid(ctx: CanvasRenderingContext2D, size: number, padding: number, theme: StrokeTheme,
    style: string = GridStyleId.TIAN): void {
    if (style === GridStyleId.NONE) {
      return;
    }
    ctx.save();
    StrokeRenderer.resetTransform(ctx);
    ctx.strokeStyle = theme.grid;
    ctx.lineWidth = 1;
    const inner: number = size - 2 * padding;
    ctx.strokeRect(padding, padding, inner, inner);
    if (style !== GridStyleId.NINE) {
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(size / 2, padding);
      ctx.lineTo(size / 2, size - padding);
      ctx.moveTo(padding, size / 2);
      ctx.lineTo(size - padding, size / 2);
      if (style === GridStyleId.MI) {
        ctx.moveTo(padding, padding);
        ctx.lineTo(size - padding, size - padding);
        ctx.moveTo(size - padding, padding);
        ctx.lineTo(padding, size - padding);
      }
      ctx.stroke();
      ctx.setLineDash([]);
    } else {
      const third: number = inner / 3;
      ctx.beginPath();
      for (let i = 1; i < 3; i += 1) {
        const x: number = padding + third * i;
        ctx.moveTo(x, padding);
        ctx.lineTo(x, size - padding);
        const y: number = padding + third * i;
        ctx.moveTo(padding, y);
        ctx.lineTo(size - padding, y);
      }
      ctx.stroke();
    }
    ctx.restore();
  }

  /** 重放命令流，构建当前路径。 */
  static buildPath(ctx: CanvasRenderingContext2D, commands: PathCommand[]): void {
    for (let i = 0; i < commands.length; i += 1) {
      const command: PathCommand = commands[i];
      const v: number[] = command.values;
      if (command.op === PathOp.MOVE) {
        ctx.moveTo(v[0], v[1]);
      } else if (command.op === PathOp.LINE) {
        ctx.lineTo(v[0], v[1]);
      } else if (command.op === PathOp.QUAD) {
        ctx.quadraticCurveTo(v[0], v[1], v[2], v[3]);
      } else if (command.op === PathOp.CUBIC) {
        ctx.bezierCurveTo(v[0], v[1], v[2], v[3], v[4], v[5]);
      } else if (command.op === PathOp.CLOSE) {
        ctx.closePath();
      }
    }
  }

  /** 填充某一笔（数据坐标）。 */
  static fillStroke(ctx: CanvasRenderingContext2D, data: StrokeData, index: number, color: string): void {
    if (index < 0 || index >= data.commands.length) {
      return;
    }
    ctx.save();
    ctx.fillStyle = color;
    ctx.beginPath();
    StrokeRenderer.buildPath(ctx, data.commands[index]);
    ctx.fill();
    ctx.restore();
  }

  /** 填充 [0, count) 的笔画。 */
  static fillStrokes(ctx: CanvasRenderingContext2D, data: StrokeData, count: number, color: string): void {
    const limit: number = Math.min(count, data.commands.length);
    for (let i = 0; i < limit; i += 1) {
      StrokeRenderer.fillStroke(ctx, data, i, color);
    }
  }

  /** 用 median 裁剪出当前笔画的前 progress 段并填充（书写动画）。 */
  static fillStrokeProgress(ctx: CanvasRenderingContext2D, data: StrokeData, index: number,
    progress: number, color: string, halfWidth: number): void {
    if (index < 0 || index >= data.commands.length) {
      return;
    }
    const median: Point[] = index < data.medians.length ? data.medians[index] : [];
    if (median.length < 2) {
      if (progress > 0) {
        StrokeRenderer.fillStroke(ctx, data, index, color);
      }
      return;
    }
    const clamped: number = Math.max(0, Math.min(1, progress));
    StrokeRenderer.fillClip(ctx, data, index, median, clamped, color, halfWidth);
  }

  /** 裁剪填充实现。 */
  static fillClip(ctx: CanvasRenderingContext2D, data: StrokeData, index: number, median: Point[],
    progress: number, color: string, halfWidth: number): void {
    const polygon: Point[] = StrokeGeometry.clipPolygon(median, halfWidth, 0, progress);
    ctx.save();
    ctx.beginPath();
    if (polygon.length > 0) {
      ctx.moveTo(polygon[0].x, polygon[0].y);
      for (let i = 1; i < polygon.length; i += 1) {
        ctx.lineTo(polygon[i].x, polygon[i].y);
      }
      ctx.closePath();
      ctx.clip();
    }
    ctx.fillStyle = color;
    ctx.beginPath();
    StrokeRenderer.buildPath(ctx, data.commands[index]);
    ctx.fill();
    ctx.restore();
  }

  /** 笔顺序号：每笔起笔处画圆圈 + 数字（屏幕坐标）。 */
  static drawNumbers(ctx: CanvasRenderingContext2D, data: StrokeData, size: number, padding: number,
    theme: StrokeTheme, currentIndex: number, fontPx: number): void {
    if (size < NUMBER_MIN_CANVAS_VP) {
      return;
    }
    const radius: number = StrokeNumberLayout.radiusFor(size);
    StrokeRenderer.resetTransform(ctx);
    ctx.save();
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    for (let i = 0; i < data.medians.length; i += 1) {
      const median: Point[] = data.medians[i];
      const anchor: NumberAnchor = StrokeNumberLayout.anchor(median, size, padding, radius);
      const active: boolean = i === currentIndex;
      const numberFontPx: number = i >= 9 ? Math.round(fontPx * 0.88) : fontPx;
      ctx.font = `${numberFontPx}px sans-serif`;
      ctx.beginPath();
      ctx.arc(anchor.x, anchor.y, radius, 0, Math.PI * 2);
      ctx.fillStyle = active ? theme.numberActiveBg : theme.numberBg;
      ctx.fill();
      ctx.lineWidth = 1;
      ctx.strokeStyle = active ? theme.numberActiveBg : theme.numberBorder;
      ctx.stroke();
      ctx.fillStyle = active ? theme.numberActiveText : theme.numberText;
      ctx.fillText(`${i + 1}`, anchor.x, anchor.y);
    }
    ctx.restore();
  }

  /** 全部笔画的 median 骨架（数据坐标）。 */
  static drawSkeleton(ctx: CanvasRenderingContext2D, data: StrokeData, size: number, padding: number,
    theme: StrokeTheme, highlightIndex: number): void {
    const scale: number = StrokeRenderer.scaleFor(size, padding);
    if (scale <= 0) {
      return;
    }
    const lineWidth: number = SKELETON_LINE_VP / scale;
    ctx.save();
    StrokeRenderer.applyTransform(ctx, size, padding);
    for (let i = 0; i < data.medians.length; i += 1) {
      const color: string = i === highlightIndex ? theme.skeletonActive : theme.skeleton;
      StrokeRenderer.strokeMedian(ctx, data.medians[i], color, lineWidth);
    }
    ctx.restore();
    StrokeRenderer.resetTransform(ctx);
    for (let i = 0; i < data.medians.length; i += 1) {
      const color: string = i === highlightIndex ? theme.skeletonActive : theme.skeleton;
      StrokeRenderer.drawMedianArrow(ctx, data.medians[i], size, padding, color);
    }
  }

  /** 单笔骨架（描红提示用）。 */
  static drawSkeletonStroke(ctx: CanvasRenderingContext2D, data: StrokeData, index: number, size: number,
    padding: number, theme: StrokeTheme): void {
    if (index < 0 || index >= data.medians.length) {
      return;
    }
    const scale: number = StrokeRenderer.scaleFor(size, padding);
    if (scale <= 0) {
      return;
    }
    ctx.save();
    StrokeRenderer.applyTransform(ctx, size, padding);
    StrokeRenderer.strokeMedian(ctx, data.medians[index], theme.skeletonActive, SKELETON_LINE_VP / scale);
    ctx.restore();
    StrokeRenderer.resetTransform(ctx);
    StrokeRenderer.drawMedianArrow(ctx, data.medians[index], size, padding, theme.skeletonActive);
  }

  /** 描一条 median 折线（数据坐标）。 */
  private static strokeMedian(ctx: CanvasRenderingContext2D, median: Point[], color: string,
    lineWidth: number): void {
    if (median.length < 2) {
      return;
    }
    ctx.strokeStyle = color;
    ctx.lineWidth = lineWidth;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(median[0].x, median[0].y);
    for (let i = 1; i < median.length; i += 1) {
      ctx.lineTo(median[i].x, median[i].y);
    }
    ctx.stroke();
  }

  /** 在 median 的 ARROW_POSITION_RATIO 处画运笔方向箭头（屏幕坐标）。 */
  private static drawMedianArrow(ctx: CanvasRenderingContext2D, median: Point[], size: number, padding: number,
    color: string): void {
    if (median.length < 2) {
      return;
    }
    const total: number = StrokeGeometry.polylineLength(median);
    if (total <= 0) {
      return;
    }
    const scale: number = StrokeRenderer.scaleFor(size, padding);
    const at: number = total * ARROW_POSITION_RATIO;
    const before: Point = StrokeGeometry.pointAtLength(median, Math.max(0, at - 12));
    const after: Point = StrokeGeometry.pointAtLength(median, Math.min(total, at + 12));
    const tip: Point = StrokeGeometry.pointAtLength(median, at);
    const dx: number = (after.x - before.x) * scale;
    const dy: number = -(after.y - before.y) * scale;
    const length: number = Math.sqrt(dx * dx + dy * dy);
    if (length < 0.001) {
      return;
    }
    const angle: number = Math.atan2(dy, dx);
    const tipX: number = padding + tip.x * scale;
    const tipY: number = padding + (900 - tip.y) * scale;
    ctx.save();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.8;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(tipX, tipY);
    ctx.lineTo(tipX - Math.cos(angle - Math.PI / 6) * ARROW_LENGTH_VP,
      tipY - Math.sin(angle - Math.PI / 6) * ARROW_LENGTH_VP);
    ctx.moveTo(tipX, tipY);
    ctx.lineTo(tipX - Math.cos(angle + Math.PI / 6) * ARROW_LENGTH_VP,
      tipY - Math.sin(angle + Math.PI / 6) * ARROW_LENGTH_VP);
    ctx.stroke();
    ctx.restore();
  }

  /** 在屏幕坐标画一条用户描红轨迹。 */
  static drawUserTrail(ctx: CanvasRenderingContext2D, points: Point[], color: string, width: number): void {
    if (points.length < 2) {
      return;
    }
    ctx.save();
    StrokeRenderer.resetTransform(ctx);
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    for (let i = 1; i < points.length; i += 1) {
      ctx.lineTo(points[i].x, points[i].y);
    }
    ctx.stroke();
    ctx.restore();
  }
}
