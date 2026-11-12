import { describe, it, expect } from '@ohos/hypium';
import { ReviewScheduler } from '../../../main/ets/service/ReviewScheduler';

const DAY: number = 24 * 60 * 60 * 1000;

export default function reviewSchedulerTest() {
  describe('ReviewScheduler', () => {
    it('uses_growing_intervals', 0, () => {
      const now: number = 1000000;
      expect(ReviewScheduler.nextAfterPass(0, now)).assertEqual(now + DAY);
      expect(ReviewScheduler.nextAfterPass(1, now)).assertEqual(now + DAY);
      expect(ReviewScheduler.nextAfterPass(2, now)).assertEqual(now + 2 * DAY);
      expect(ReviewScheduler.nextAfterPass(3, now)).assertEqual(now + 4 * DAY);
      expect(ReviewScheduler.nextAfterPass(99, now)).assertEqual(now + 30 * DAY);
    });

    it('requeues_again_in_ten_minutes', 0, () => {
      const now: number = 1000000;
      expect(ReviewScheduler.nextAfterAgain(now)).assertEqual(now + 10 * 60 * 1000);
    });

    it('schedules_learned_for_tomorrow', 0, () => {
      const now: number = 1000000;
      expect(ReviewScheduler.nextAfterLearned(now)).assertEqual(now + DAY);
    });

    it('counts_streak_ending_today', 0, () => {
      const now: number = Date.UTC(2026, 10, 12, 10, 0, 0);
      const today: string = ReviewScheduler.localDateText(now);
      const yesterday: string = ReviewScheduler.localDateText(now - DAY);
      const twoDaysAgo: string = ReviewScheduler.localDateText(now - 2 * DAY);
      expect(ReviewScheduler.streak([today, yesterday, twoDaysAgo], now)).assertEqual(3);
    });

    it('counts_streak_ending_yesterday', 0, () => {
      const now: number = Date.UTC(2026, 10, 12, 10, 0, 0);
      const yesterday: string = ReviewScheduler.localDateText(now - DAY);
      const twoDaysAgo: string = ReviewScheduler.localDateText(now - 2 * DAY);
      expect(ReviewScheduler.streak([yesterday, twoDaysAgo], now)).assertEqual(2);
    });

    it('ignores_broken_streak', 0, () => {
      const now: number = Date.UTC(2026, 10, 12, 10, 0, 0);
      const twoDaysAgo: string = ReviewScheduler.localDateText(now - 2 * DAY);
      expect(ReviewScheduler.streak([twoDaysAgo], now)).assertEqual(0);
    });

    it('returns_zero_for_empty_dates', 0, () => {
      expect(ReviewScheduler.streak([], Date.now())).assertEqual(0);
    });
  });
}
