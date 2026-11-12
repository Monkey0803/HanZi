/*
 * StrokeGeometry.ets — 折线长度、采样、距离与描红裁剪多边形。
 *
 * 全部按 makemeahanzi 数据坐标（1024 基准）计算；屏幕坐标只在 toData 边界转换。
 */

import { Point } from '../model/StrokeModels';

export class StrokeGeometry {
  /** 折线总长。 */
  static polylineLength(points: Point[]): number {
    let total: number = 0;
    for (let i = 1; i < points.length; i += 1) {
      total += StrokeGeometry.distance(points[i - 1], points[i]);
    }
    return total;
  }

  /** 两点距离。 */
  static distance(a: Point, b: Point): number {
    const dx: number = a.x - b.x;
    const dy: number = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /** 按累计长度取点（距离超出范围时夹到端点）。 */
  static pointAtLength(points: Point[], distance: number): Point {
    if (points.length === 0) {
      return new Point();
    }
    if (distance <= 0) {
      return new Point(points[0].x, points[0].y);
    }
    let travelled: number = 0;
    for (let i = 1; i < points.length; i += 1) {
      const segment: number = StrokeGeometry.distance(points[i - 1], points[i]);
      if (travelled + segment >= distance && segment > 0) {
        const ratio: number = (distance - travelled) / segment;
        return new Point(
          points[i - 1].x + (points[i].x - points[i - 1].x) * ratio,
          points[i - 1].y + (points[i].y - points[i - 1].y) * ratio
        );
      }
      travelled += segment;
    }
    const last: Point = points[points.length - 1];
    return new Point(last.x, last.y);
  }

  /** 沿折线均匀采样 count 个点。 */
  static sample(points: Point[], count: number): Point[] {
    const result: Point[] = [];
    if (points.length === 0 || count <= 0) {
      return result;
    }
    const total: number = StrokeGeometry.polylineLength(points);
    for (let i = 0; i < count; i += 1) {
      const ratio: number = count === 1 ? 0 : i / (count - 1);
      result.push(StrokeGeometry.pointAtLength(points, total * ratio));
    }
    return result;
  }

  /** 点到线段的距离。 */
  static distanceToSegment(p: Point, a: Point, b: Point): number {
    const dx: number = b.x - a.x;
    const dy: number = b.y - a.y;
    const lengthSquared: number = dx * dx + dy * dy;
    if (lengthSquared === 0) {
      return StrokeGeometry.distance(p, a);
    }
    let t: number = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared;
    if (t < 0) {
      t = 0;
    } else if (t > 1) {
      t = 1;
    }
    const closest: Point = new Point(a.x + dx * t, a.y + dy * t);
    return StrokeGeometry.distance(p, closest);
  }

  /** 点到折线的最短距离。 */
  static distanceToPolyline(p: Point, polyline: Point[]): number {
    if (polyline.length === 0) {
      return Number.MAX_VALUE;
    }
    if (polyline.length === 1) {
      return StrokeGeometry.distance(p, polyline[0]);
    }
    let best: number = Number.MAX_VALUE;
    for (let i = 1; i < polyline.length; i += 1) {
      const value: number = StrokeGeometry.distanceToSegment(p, polyline[i - 1], polyline[i]);
      if (value < best) {
        best = value;
      }
    }
    return best;
  }

  /** 采样点到标准轨迹的平均距离。 */
  static averageDistance(samples: Point[], polyline: Point[]): number {
    if (samples.length === 0 || polyline.length === 0) {
      return Number.MAX_VALUE;
    }
    let sum: number = 0;
    for (let i = 0; i < samples.length; i += 1) {
      sum += StrokeGeometry.distanceToPolyline(samples[i], polyline);
    }
    return sum / samples.length;
  }

  /** 两端整体方向余弦。 */
  static directionCosine(a: Point[], b: Point[]): number {
    if (a.length < 2 || b.length < 2) {
      return 0;
    }
    const ax: number = a[a.length - 1].x - a[0].x;
    const ay: number = a[a.length - 1].y - a[0].y;
    const bx: number = b[b.length - 1].x - b[0].x;
    const by: number = b[b.length - 1].y - b[0].y;
    const lengthA: number = Math.sqrt(ax * ax + ay * ay);
    const lengthB: number = Math.sqrt(bx * bx + by * by);
    if (lengthA === 0 || lengthB === 0) {
      return 0;
    }
    return (ax * bx + ay * by) / (lengthA * lengthB);
  }

  /** 屏幕坐标 → 数据坐标（scale / padding 与渲染层一致）。 */
  static toData(point: Point, scale: number, padding: number): Point {
    if (scale <= 0) {
      return new Point();
    }
    return new Point(
      (point.x - padding) / scale,
      900 - (point.y - padding) / scale
    );
  }

  /**
   * 按进度截取 median 并生成裁剪多边形：两侧偏移 halfWidth，两端加半圆帽。
   * from / to ∈ [0, 1]。
   */
  static clipPolygon(median: Point[], halfWidth: number, from: number, to: number): Point[] {
    if (median.length < 2 || halfWidth <= 0) {
      return [];
    }
    const total: number = StrokeGeometry.polylineLength(median);
    if (total === 0) {
      return [];
    }
    let startRatio: number = Math.max(0, Math.min(1, from));
    let endRatio: number = Math.max(0, Math.min(1, to));
    if (endRatio < startRatio) {
      const swap: number = startRatio;
      startRatio = endRatio;
      endRatio = swap;
    }
    if (endRatio - startRatio < 0.001) {
      endRatio = Math.min(1, startRatio + 0.001);
    }

    const startDistance: number = total * startRatio;
    const endDistance: number = total * endRatio;
    const slice: Point[] = [StrokeGeometry.pointAtLength(median, startDistance)];
    let travelled: number = 0;
    for (let i = 1; i < median.length; i += 1) {
      const segment: number = StrokeGeometry.distance(median[i - 1], median[i]);
      const segmentEnd: number = travelled + segment;
      if (segmentEnd > startDistance && segmentEnd < endDistance) {
        slice.push(median[i]);
      }
      travelled = segmentEnd;
    }
    slice.push(StrokeGeometry.pointAtLength(median, endDistance));

    const left: Point[] = [];
    const right: Point[] = [];
    for (let i = 0; i < slice.length; i += 1) {
      const prev: Point = slice[i === 0 ? 0 : i - 1];
      const next: Point = slice[i === slice.length - 1 ? i : i + 1];
      const nx: number = -(next.y - prev.y);
      const ny: number = next.x - prev.x;
      const normalLength: number = Math.sqrt(nx * nx + ny * ny);
      const ux: number = normalLength === 0 ? 0 : nx / normalLength;
      const uy: number = normalLength === 0 ? 0 : ny / normalLength;
      left.push(new Point(slice[i].x + ux * halfWidth, slice[i].y + uy * halfWidth));
      right.push(new Point(slice[i].x - ux * halfWidth, slice[i].y - uy * halfWidth));
    }

    const polygon: Point[] = [];
    for (let i = 0; i < left.length; i += 1) {
      polygon.push(left[i]);
    }

    const endPoint: Point = slice[slice.length - 1];
    const endPrev: Point = slice[slice.length - 2];
    const endForward: number = Math.atan2(endPoint.y - endPrev.y, endPoint.x - endPrev.x);
    const capSteps: number = 8;
    for (let i = 1; i < capSteps; i += 1) {
      const angle: number = endForward + Math.PI / 2 - Math.PI * (i / capSteps);
      polygon.push(new Point(endPoint.x + Math.cos(angle) * halfWidth, endPoint.y + Math.sin(angle) * halfWidth));
    }

    for (let i = right.length - 1; i >= 0; i -= 1) {
      polygon.push(right[i]);
    }

    const startPoint: Point = slice[0];
    const startNext: Point = slice[1];
    const startForward: number = Math.atan2(startNext.y - startPoint.y, startNext.x - startPoint.x);
    for (let i = 1; i < capSteps; i += 1) {
      const angle: number = startForward - Math.PI / 2 + Math.PI * (i / capSteps);
      polygon.push(new Point(startPoint.x + Math.cos(angle) * halfWidth, startPoint.y + Math.sin(angle) * halfWidth));
    }
    return polygon;
  }
}
