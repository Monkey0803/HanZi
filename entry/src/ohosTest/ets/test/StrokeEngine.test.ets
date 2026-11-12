import { describe, it, expect } from '@ohos/hypium';
import { SvgPathParser } from '../../../main/ets/service/SvgPathParser';
import { StrokeGeometry } from '../../../main/ets/service/StrokeGeometry';
import { StrokeMatcher } from '../../../main/ets/service/StrokeMatcher';
import { PathCommand, PathOp, Point, StrokeMatcherOptions, StrokeMatchResult } from '../../../main/ets/model/StrokeModels';

function almostEqual(actual: number, expected: number, tolerance: number = 0.001): boolean {
  return Math.abs(actual - expected) <= tolerance;
}

function polyline(points: number[]): Point[] {
  const result: Point[] = [];
  for (let i = 0; i + 1 < points.length; i += 2) {
    result.push(new Point(points[i], points[i + 1]));
  }
  return result;
}

export default function strokeEngineTest() {
  describe('SvgPathParser', () => {
    it('parses_absolute_polyline', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 L100 0 L100 100');
      expect(commands.length).assertEqual(3);
      expect(commands[0].op).assertEqual(PathOp.MOVE);
      expect(commands[0].values[0]).assertEqual(0);
      expect(commands[0].values[1]).assertEqual(0);
      expect(commands[1].op).assertEqual(PathOp.LINE);
      expect(commands[1].values[0]).assertEqual(100);
      expect(commands[2].values[1]).assertEqual(100);
    });

    it('parses_relative_and_implicit_lineto', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('m10 10 l5 0 5 5');
      expect(commands.length).assertEqual(3);
      expect(commands[0].values[0]).assertEqual(10);
      expect(commands[1].values[0]).assertEqual(15);
      expect(commands[2].values[0]).assertEqual(20);
      expect(commands[2].values[1]).assertEqual(15);
    });

    it('handles_implicit_moveto_as_lineto', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 10 0 10 10');
      expect(commands.length).assertEqual(3);
      expect(commands[0].op).assertEqual(PathOp.MOVE);
      expect(commands[1].op).assertEqual(PathOp.LINE);
      expect(commands[1].values[0]).assertEqual(10);
      expect(commands[2].values[1]).assertEqual(10);
    });

    it('expands_horizontal_and_vertical', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 H50 V60');
      expect(commands.length).assertEqual(3);
      expect(commands[1].values[0]).assertEqual(50);
      expect(commands[1].values[1]).assertEqual(0);
      expect(commands[2].values[0]).assertEqual(50);
      expect(commands[2].values[1]).assertEqual(60);
    });

    it('reflects_quadratic_control_point', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 Q10 10 20 0 T40 0');
      expect(commands.length).assertEqual(3);
      expect(commands[1].op).assertEqual(PathOp.QUAD);
      expect(commands[2].op).assertEqual(PathOp.QUAD);
      // 反射控制点 = 2 * 当前点 - 上一控制点 = (30, -10)
      expect(commands[2].values[0]).assertEqual(30);
      expect(commands[2].values[1]).assertEqual(-10);
    });

    it('reflects_cubic_control_point', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 C0 10 10 10 10 0 S20 -10 20 0');
      expect(commands.length).assertEqual(3);
      expect(commands[2].op).assertEqual(PathOp.CUBIC);
      expect(commands[2].values[0]).assertEqual(10);
      expect(commands[2].values[1]).assertEqual(-10);
    });

    it('converts_arc_to_cubics', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 A50 50 0 0 1 100 0');
      expect(commands.length >= 2).assertTrue();
      for (let i = 0; i < commands.length; i += 1) {
        expect(commands[i].op).assertEqual(PathOp.CUBIC);
      }
      const last: PathCommand = commands[commands.length - 1];
      expect(almostEqual(last.values[4], 100)).assertTrue();
      expect(almostEqual(last.values[5], 0)).assertTrue();
    });

    it('keeps_close_command', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 L10 0 L10 10 Z');
      expect(commands.length).assertEqual(4);
      expect(commands[3].op).assertEqual(PathOp.CLOSE);
    });

    it('skips_invalid_characters', 0, () => {
      const commands: PathCommand[] = SvgPathParser.parse('M0 0 X L10 10');
      expect(commands.length).assertEqual(2);
    });
  });

  describe('StrokeGeometry', () => {
    it('computes_polyline_length', 0, () => {
      expect(StrokeGeometry.polylineLength(polyline([0, 0, 3, 4]))).assertEqual(5);
    });

    it('samples_by_distance', 0, () => {
      const half: Point = StrokeGeometry.pointAtLength(polyline([0, 0, 10, 0]), 5);
      expect(almostEqual(half.x, 5)).assertTrue();
      expect(almostEqual(half.y, 0)).assertTrue();
    });

    it('measures_distance_to_segment', 0, () => {
      const distance: number = StrokeGeometry.distanceToSegment(
        new Point(0, 5), new Point(-10, 0), new Point(10, 0));
      expect(almostEqual(distance, 5)).assertTrue();
    });

    it('builds_clip_polygon_with_caps', 0, () => {
      const polygon: Point[] = StrokeGeometry.clipPolygon(polyline([0, 0, 100, 0]), 10, 0, 1);
      expect(polygon.length > 10).assertTrue();
      let minY: number = Number.MAX_VALUE;
      let maxY: number = -Number.MAX_VALUE;
      for (let i = 0; i < polygon.length; i += 1) {
        minY = Math.min(minY, polygon[i].y);
        maxY = Math.max(maxY, polygon[i].y);
      }
      expect(almostEqual(maxY - minY, 20, 0.5)).assertTrue();
    });

    it('round_trips_screen_to_data', 0, () => {
      const point: Point = StrokeGeometry.toData(new Point(10, 20), 0.5, 5);
      expect(almostEqual(point.x, 10)).assertTrue();
      expect(almostEqual(point.y, 870)).assertTrue();
    });
  });

  describe('StrokeMatcher', () => {
    const options: StrokeMatcherOptions = new StrokeMatcherOptions();
    const median: Point[] = polyline([0, 0, 200, 0]);

    it('accepts_same_path', 0, () => {
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([0, 0, 100, 0, 200, 0]), median, options);
      expect(result.passed).assertTrue();
    });

    it('rejects_reversed_path', 0, () => {
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([200, 0, 100, 0, 0, 0]), median, options);
      expect(result.passed).assertFalse();
    });

    it('rejects_offset_path', 0, () => {
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([0, 400, 200, 400]), median, options);
      expect(result.passed).assertFalse();
    });

    it('rejects_too_short_path', 0, () => {
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([0, 0, 20, 0]), median, options);
      expect(result.passed).assertFalse();
    });

    it('rejects_single_point', 0, () => {
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([0, 0]), median, options);
      expect(result.passed).assertFalse();
      expect(result.reason).assertEqual('too-few-points');
    });

    it('skips_direction_for_tiny_stroke', 0, () => {
      const tiny: Point[] = polyline([0, 0, 40, 0]);
      const result: StrokeMatchResult = StrokeMatcher.match(polyline([0, 0, 20, 0, 40, 0]), tiny, options);
      expect(result.passed).assertTrue();
      expect(result.directionCosine).assertEqual(1);
    });
  });
}
