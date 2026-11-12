import { describe, it, expect } from '@ohos/hypium';
import { ReadingQuiz, ReadingQuizResult } from '../../../main/ets/common/utils/ReadingQuiz';

// 「找一找」小测判定纯函数单测：不依赖设备、Context 与课程数据。
export default function readingQuizTest() {
  describe('ReadingQuiz', () => {
    it('empty_target_means_not_in_quiz', 0, () => {
      expect(ReadingQuiz.judge('', '天')).assertEqual(ReadingQuizResult.NONE);
    });

    it('same_char_is_correct', 0, () => {
      expect(ReadingQuiz.judge('天', '天')).assertEqual(ReadingQuizResult.CORRECT);
    });

    it('different_char_is_retry', 0, () => {
      expect(ReadingQuiz.judge('天', '地')).assertEqual(ReadingQuizResult.RETRY);
    });

    it('next_target_wraps_around', 0, () => {
      const chars: string[] = ['天', '地', '人'];
      expect(ReadingQuiz.nextTarget(chars, 0)).assertEqual('天');
      expect(ReadingQuiz.nextTarget(chars, 2)).assertEqual('人');
      expect(ReadingQuiz.nextTarget(chars, 3)).assertEqual('天');
      expect(ReadingQuiz.nextTarget(chars, 7)).assertEqual('地');
    });

    it('next_target_handles_empty_and_negative', 0, () => {
      expect(ReadingQuiz.nextTarget([], 0)).assertEqual('');
      expect(ReadingQuiz.nextTarget(['天', '地'], -1)).assertEqual('地');
    });
  });
}
