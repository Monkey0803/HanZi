import { describe, it, expect } from '@ohos/hypium';
import { Lesson } from '../../../main/ets/model/CurriculumModels';
import { CharProgress } from '../../../main/ets/model/ProgressModels';
import { ProgressAggregator } from '../../../main/ets/service/ProgressAggregator';

function lesson(id: string, bookId: string): Lesson {
  const value: Lesson = new Lesson();
  value.id = id;
  value.bookId = bookId;
  return value;
}

function progress(char: string, lessonId: string, learned: boolean, mistakes: number = 0): CharProgress {
  const value: CharProgress = new CharProgress();
  value.character = char;
  value.lessonId = lessonId;
  value.learned = learned;
  value.mistakes = mistakes;
  return value;
}

export default function progressAggregatorTest() {
  describe('ProgressAggregator', () => {
    it('returns_empty_maps_for_empty_data', 0, () => {
      expect(ProgressAggregator.byLesson([], []).size).assertEqual(0);
      expect(ProgressAggregator.byBook([], []).size).assertEqual(0);
    });

    it('counts_only_learned_records_with_known_lesson', 0, () => {
      const lessons: Lesson[] = [lesson('1', '1a')];
      const items: CharProgress[] = [progress('人', '1', true), progress('口', '1', false), progress('山', '', true)];
      expect(ProgressAggregator.byLesson(items, lessons).get('1')).assertEqual(1);
    });

    it('deduplicates_same_character_in_same_lesson', 0, () => {
      const lessons: Lesson[] = [lesson('1', '1a')];
      const items: CharProgress[] = [progress('人', '1', true), progress('人', '1', true)];
      expect(ProgressAggregator.byLesson(items, lessons).get('1')).assertEqual(1);
    });

    it('aggregates_across_lessons_and_books', 0, () => {
      const lessons: Lesson[] = [lesson('1', '1a'), lesson('2', '1a'), lesson('3', '1b')];
      const items: CharProgress[] = [progress('人', '1', true), progress('口', '2', true), progress('山', '3', true)];
      expect(ProgressAggregator.byBook(items, lessons).get('1a')).assertEqual(2);
      expect(ProgressAggregator.byBook(items, lessons).get('1b')).assertEqual(1);
    });

    it('exposes_mistake_count_by_character', 0, () => {
      const items: CharProgress[] = [progress('人', '1', true, 3), progress('口', '1', true, 0)];
      expect(ProgressAggregator.mistakeCounts(items).get('人')).assertEqual(3);
      expect(ProgressAggregator.mistakeCounts(items).has('口')).assertFalse();
    });
  });
}
