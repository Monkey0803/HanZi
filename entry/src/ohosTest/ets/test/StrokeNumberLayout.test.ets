import { describe, it, expect } from '@ohos/hypium';
import { Point } from '../../../main/ets/model/StrokeModels';
import { NumberAnchor, StrokeNumberLayout } from '../../../main/ets/service/StrokeNumberLayout';
import { NUMBER_MAX_RADIUS, NUMBER_MIN_RADIUS } from '../../../main/ets/common/constants/StrokeConstants';

const SIZE: number = 280;
const PADDING: number = 20;

function almostEqual(actual: number, expected: number, tolerance: number = 0.5): boolean {
  return Math.abs(actual - expected) <= tolerance;
}

function polyline(points: number[]): Point[] {
  const result: Point[] = [];
  for (let i = 0; i + 1 < points.length; i += 2) {
    result.push(new Point(points[i], points[i + 1]));
  }
  return result;
}

export default function strokeNumberLayoutTest() {
  describe('StrokeNumberLayout', () => {
    it('clamps_radius_to_readable_range', 0, () => {
      expect(StrokeNumberLayout.radiusFor(100)).assertEqual(NUMBER_MIN_RADIUS);
      expect(StrokeNumberLayout.radiusFor(800)).assertEqual(NUMBER_MAX_RADIUS);
      const mid: number = StrokeNumberLayout.radiusFor(SIZE);
      expect(mid > NUMBER_MIN_RADIUS && mid < NUMBER_MAX_RADIUS).assertTrue();
    });

    it('keeps_anchor_inside_cell', 0, () => {
      const radius: number = StrokeNumberLayout.radiusFor(SIZE);
      const anchor: NumberAnchor = StrokeNumberLayout.anchor(polyline([10, 890, 80, 890]), SIZE, PADDING, radius);
      expect(anchor.x >= PADDING + radius - 0.001).assertTrue();
      expect(anchor.y >= PADDING + radius - 0.001).assertTrue();
      expect(anchor.x <= SIZE - PADDING - radius + 0.001).assertTrue();
      expect(anchor.y <= SIZE - PADDING - radius + 0.001).assertTrue();
    });

    it('offsets_along_writing_direction', 0, () => {
      const radius: number = StrokeNumberLayout.radiusFor(SIZE);
      const anchor: NumberAnchor = StrokeNumberLayout.anchor(polyline([100, 800, 300, 800]), SIZE, PADDING, radius);
      const scale: number = (SIZE - 2 * PADDING) / 1024;
      const startX: number = PADDING + 100 * scale;
      const startY: number = PADDING + 100 * scale;
      expect(anchor.x > startX).assertTrue();
      expect(almostEqual(anchor.y, startY)).assertTrue();
    });

    it('handles_single_point_median', 0, () => {
      const radius: number = StrokeNumberLayout.radiusFor(SIZE);
      const anchor: NumberAnchor = StrokeNumberLayout.anchor(polyline([200, 400]), SIZE, PADDING, radius);
      const scale: number = (SIZE - 2 * PADDING) / 1024;
      expect(almostEqual(anchor.x, PADDING + 200 * scale)).assertTrue();
      expect(almostEqual(anchor.y, PADDING + 500 * scale)).assertTrue();
    });

    it('falls_back_to_cell_corner_for_empty_median', 0, () => {
      const radius: number = StrokeNumberLayout.radiusFor(SIZE);
      const anchor: NumberAnchor = StrokeNumberLayout.anchor([], SIZE, PADDING, radius);
      expect(almostEqual(anchor.x, PADDING + radius)).assertTrue();
      expect(almostEqual(anchor.y, PADDING + radius)).assertTrue();
    });

    it('falls_back_when_scale_is_not_positive', 0, () => {
      const radius: number = StrokeNumberLayout.radiusFor(SIZE);
      const anchor: NumberAnchor = StrokeNumberLayout.anchor(polyline([100, 800, 300, 800]), 30, 20, radius);
      expect(Number.isFinite(anchor.x)).assertTrue();
      expect(Number.isFinite(anchor.y)).assertTrue();
    });
  });
}
