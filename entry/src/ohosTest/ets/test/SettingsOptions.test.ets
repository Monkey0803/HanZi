import { describe, it, expect } from '@ohos/hypium';
import {
  THEME_OPTIONS,
  LANGUAGE_OPTIONS,
  MATERIAL_TYPE_OPTIONS,
  MATERIAL_LEVEL_OPTIONS,
  DAILY_GOAL_OPTIONS,
  STROKE_SPEED_OPTIONS
} from '../../../main/ets/model/SettingsOptions';

// ChoiceSet 的纯函数单测：不依赖 Context，也不访问文件系统。

export default function settingsOptionsTest() {
  describe('ChoiceSet', () => {
    it('indexOf_returns_option_index', 0, () => {
      expect(THEME_OPTIONS.indexOf('dark')).assertEqual(2);
      expect(THEME_OPTIONS.indexOf('light')).assertEqual(1);
      expect(MATERIAL_LEVEL_OPTIONS.indexOf('smooth')).assertEqual(2);
    });

    it('indexOf_falls_back_to_default_index_for_unknown_id', 0, () => {
      expect(THEME_OPTIONS.indexOf('nope')).assertEqual(0);
      expect(MATERIAL_TYPE_OPTIONS.indexOf('')).assertEqual(0);
    });

    it('normalize_keeps_known_and_falls_back_to_default', 0, () => {
      expect(LANGUAGE_OPTIONS.normalize('en')).assertEqual('en');
      expect(LANGUAGE_OPTIONS.normalize('zh')).assertEqual('zh');
      expect(LANGUAGE_OPTIONS.normalize('fr')).assertEqual('system');
      expect(MATERIAL_LEVEL_OPTIONS.normalize('exquisite')).assertEqual('exquisite');
      expect(MATERIAL_LEVEL_OPTIONS.normalize('bad')).assertEqual('adaptive');
    });

    it('default_value_is_the_first_option_for_every_table', 0, () => {
      expect(THEME_OPTIONS.indexOf(THEME_OPTIONS.defaultValue)).assertEqual(0);
      expect(LANGUAGE_OPTIONS.indexOf(LANGUAGE_OPTIONS.defaultValue)).assertEqual(0);
      expect(MATERIAL_TYPE_OPTIONS.indexOf(MATERIAL_TYPE_OPTIONS.defaultValue)).assertEqual(0);
      expect(MATERIAL_LEVEL_OPTIONS.indexOf(MATERIAL_LEVEL_OPTIONS.defaultValue)).assertEqual(3);
    });

    it('labelOf_never_throws_for_unknown_id', 0, () => {
      expect(MATERIAL_TYPE_OPTIONS.labelOf('unknown') !== undefined).assertTrue();
    });

    it('study_options_have_expected_values', 0, () => {
      expect(DAILY_GOAL_OPTIONS.options.length).assertEqual(4);
      expect(DAILY_GOAL_OPTIONS.normalize('15')).assertEqual('15');
      expect(DAILY_GOAL_OPTIONS.normalize('99')).assertEqual('10');
      expect(STROKE_SPEED_OPTIONS.options.length).assertEqual(3);
      expect(STROKE_SPEED_OPTIONS.normalize('fast')).assertEqual('fast');
    });
  });
}
