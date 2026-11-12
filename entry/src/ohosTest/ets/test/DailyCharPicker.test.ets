import { describe, it, expect } from '@ohos/hypium';
import { DailyCharPicker } from '../../../main/ets/common/utils/DailyCharPicker';

// 每日一字的纯函数单测：不依赖设备、Context 与课程数据。
export default function dailyCharPickerTest() {
  describe('DailyCharPicker', () => {
    it('dayKey_is_stable_for_same_date', 0, () => {
      expect(DailyCharPicker.dayKeyOf(new Date(2026, 10, 12))).assertEqual(20261112);
      expect(DailyCharPicker.dayKeyOf(new Date(2026, 0, 1))).assertEqual(20260101);
    });

    it('index_is_stable_within_a_day_and_wraps', 0, () => {
      const key: number = 20261112;
      const a: number = DailyCharPicker.dailyIndex(key, 7);
      const b: number = DailyCharPicker.dailyIndex(key, 7);
      expect(a).assertEqual(b);
      expect(a >= 0 && a < 7).assertTrue();
    });

    it('index_differs_between_days_when_size_is_large', 0, () => {
      const day1: number = DailyCharPicker.dailyIndex(20261112, 3000);
      const day2: number = DailyCharPicker.dailyIndex(20261113, 3000);
      expect(day1).assertEqual(day2 + 1);
    });

    it('empty_list_returns_minus_one', 0, () => {
      expect(DailyCharPicker.dailyIndex(20261112, 0)).assertEqual(-1);
      expect(DailyCharPicker.dailyIndex(20261112, -5)).assertEqual(-1);
    });

    it('negative_day_key_still_in_range', 0, () => {
      const index: number = DailyCharPicker.dailyIndex(-20261112, 13);
      expect(index >= 0 && index < 13).assertTrue();
    });
  });
}
