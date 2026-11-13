import { describe, it, expect } from '@ohos/hypium';
import { BreakpointConstants } from '../../../main/ets/common/constants/BreakpointConstants';
import { PracticeLayoutPolicy } from '../../../main/ets/common/utils/PracticeLayoutPolicy';

export default function practiceLayoutPolicyTest() {
  describe('PracticeLayoutPolicy', () => {
    it('canvas_size_uses_real_region_and_caps_large_windows', 0, () => {
      expect(PracticeLayoutPolicy.canvasSize(500, 500, false)).assertEqual(468);
      expect(PracticeLayoutPolicy.canvasSize(1200, 800, false)).assertEqual(480);
    });

    it('canvas_size_supports_compact_and_very_short_windows', 0, () => {
      expect(PracticeLayoutPolicy.canvasSize(176, 176, true)).assertEqual(144);
      expect(PracticeLayoutPolicy.canvasSize(180, 160, false)).assertEqual(128);
      expect(PracticeLayoutPolicy.canvasSize(20, 20, true)).assertEqual(0);
    });

    it('canvas_size_rejects_invalid_dimensions', 0, () => {
      expect(PracticeLayoutPolicy.canvasSize(0, 500, false)).assertEqual(0);
      expect(PracticeLayoutPolicy.canvasSize(Number.NaN, 500, false)).assertEqual(0);
      expect(PracticeLayoutPolicy.canvasSize(500, Number.POSITIVE_INFINITY, false)).assertEqual(0);
    });

    it('compact_mode_only_matches_small_square_windows', 0, () => {
      expect(PracticeLayoutPolicy.isCompactWindow(500, 500)).assertTrue();
      expect(PracticeLayoutPolicy.isCompactWindow(480, 600)).assertTrue();
      expect(PracticeLayoutPolicy.isCompactWindow(600, 480)).assertTrue();
      expect(PracticeLayoutPolicy.isCompactWindow(601, 500)).assertFalse();
      expect(PracticeLayoutPolicy.isCompactWindow(360, 780)).assertFalse();
    });

    it('breakpoint_queries_cover_boundary_widths', 0, () => {
      const medium: number = Number.parseInt(BreakpointConstants.WINDOW_BREAKPOINTS[0], 10);
      const wide: number = Number.parseInt(BreakpointConstants.WINDOW_BREAKPOINTS[1], 10);
      expect(599 < medium && 600 >= medium).assertTrue();
      expect(839 < wide && 840 >= wide).assertTrue();
      expect(BreakpointConstants.MEDIUM_MEDIA_QUERY.indexOf('600vp') >= 0).assertTrue();
      expect(BreakpointConstants.WIDE_MEDIA_QUERY.indexOf('840vp') >= 0).assertTrue();
    });
  });
}
