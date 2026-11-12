/*
 * StrokeMatcher.ets — 描红判分（纯几何，可在单测中直接跑）。
 *
 * 阈值以 1024 数据坐标为单位，与 hanzi-writer 的判定思路一致：
 * 起笔 / 收笔位置、长度比例、平均偏离、整体方向。
 */

import { Point, StrokeMatchResult, StrokeMatcherOptions } from '../model/StrokeModels';
import { StrokeGeometry } from './StrokeGeometry';

const SAMPLE_COUNT: number = 20;

export class StrokeMatcher {
  static match(userPoints: Point[], median: Point[], options: StrokeMatcherOptions): StrokeMatchResult {
    const result: StrokeMatchResult = new StrokeMatchResult();
    if (userPoints.length < 2) {
      result.reason = 'too-few-points';
      return result;
    }
    if (median.length < 2) {
      result.reason = 'no-median';
      return result;
    }
    const standardLength: number = StrokeGeometry.polylineLength(median);
    if (standardLength === 0) {
      result.reason = 'zero-length-median';
      return result;
    }
    const userLength: number = StrokeGeometry.polylineLength(userPoints);

    result.startDistance = StrokeGeometry.distance(userPoints[0], median[0]);
    result.endDistance = StrokeGeometry.distance(userPoints[userPoints.length - 1], median[median.length - 1]);
    result.lengthRatio = userLength / standardLength;
    const samples: Point[] = StrokeGeometry.sample(userPoints, SAMPLE_COUNT);
    result.averageDistance = StrokeGeometry.averageDistance(samples, median);
    result.directionCosine = standardLength < options.minDirectionLength
      ? 1
      : StrokeGeometry.directionCosine(userPoints, median);

    if (result.startDistance > options.maxStartDistance) {
      result.reason = 'start-far';
      return result;
    }
    if (result.endDistance > options.maxEndDistance) {
      result.reason = 'end-far';
      return result;
    }
    if (result.lengthRatio < options.minLengthRatio) {
      result.reason = 'too-short';
      return result;
    }
    if (result.lengthRatio > options.maxLengthRatio) {
      result.reason = 'too-long';
      return result;
    }
    if (result.averageDistance > options.maxAverageDistance) {
      result.reason = 'far-from-median';
      return result;
    }
    if (result.directionCosine < options.minDirectionCosine) {
      result.reason = 'wrong-direction';
      return result;
    }
    result.passed = true;
    result.reason = 'ok';
    return result;
  }
}
