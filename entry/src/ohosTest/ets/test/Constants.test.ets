import { describe, it, expect } from '@ohos/hypium';
import { BreakpointConstants } from '../../../main/ets/common/constants/BreakpointConstants';
import { TabIndex } from '../../../main/ets/common/constants/NavigationConstants';
import { RouterConstants } from '../../../main/ets/common/constants/RouterConstants';
import { PreferencesConstants } from '../../../main/ets/common/constants/PreferencesConstants';
import { CommonConstants } from '../../../main/ets/common/constants/CommonConstants';

// 常量的自洽性单测：这些值一改错（顺序、重复、与媒体查询不一致）界面就会静默错位，
// 编译器不会报，所以专门钉住。

export default function constantsTest() {
  describe('Constants', () => {
    it('breakpoints_are_ascending_and_match_the_wide_query', 0, () => {
      const points: string[] = BreakpointConstants.WINDOW_BREAKPOINTS;
      expect(points.length).assertEqual(2);
      const small: number = Number.parseInt(points[0], 10);
      const large: number = Number.parseInt(points[1], 10);
      expect(small < large).assertTrue();
      // 代码侧「宽屏」条件必须与最后一个（lg）断点一致，否则声明式与代码式会打架
      expect(BreakpointConstants.WIDE_MEDIA_QUERY.indexOf(`${large}vp`) >= 0).assertTrue();
    });

    it('grid_columns_is_twelve', 0, () => {
      expect(BreakpointConstants.GRID_COLUMNS).assertEqual(12);
    });

    it('tab_indices_are_distinct_and_ordered', 0, () => {
      // 显式声明为 number 做拓宽：直接比较两个字面量枚举值会被判「无交集」而编译失败
      const books: number = TabIndex.BOOKS;
      const review: number = TabIndex.REVIEW;
      const settings: number = TabIndex.SETTINGS;
      const images: number = TabIndex.IMAGES;
      expect(books === review).assertFalse();
      expect(review === settings).assertFalse();
      expect(settings === images).assertFalse();
      expect(books < review && review < settings && settings < images).assertTrue();
    });

    it('route_names_are_distinct_and_non_empty', 0, () => {
      expect(RouterConstants.PAGE_DETAIL.length > 0).assertTrue();
      expect(RouterConstants.PAGE_PREVIEW.length > 0).assertTrue();
      expect(RouterConstants.PAGE_DETAIL === RouterConstants.PAGE_PREVIEW).assertFalse();
      expect(RouterConstants.PAGE_BOOK.length > 0).assertTrue();
      expect(RouterConstants.PAGE_LESSON.length > 0).assertTrue();
      expect(RouterConstants.PAGE_CHAR.length > 0).assertTrue();
    });

    it('preference_keys_are_unique', 0, () => {
      const keys: string[] = [
        PreferencesConstants.KEY_THEME_MODE,
        PreferencesConstants.KEY_LANGUAGE_MODE,
        PreferencesConstants.KEY_MATERIAL_TYPE,
        PreferencesConstants.KEY_MATERIAL_LEVEL,
        PreferencesConstants.KEY_IMMERSIVE_ON,
        PreferencesConstants.KEY_LIGHT_EFFECT,
        PreferencesConstants.KEY_GRIP_ENABLED,
        PreferencesConstants.KEY_ANTI_PEEP_ENABLED
      ];
      const unique: Set<string> = new Set<string>();
      for (const key of keys) {
        unique.add(key);
      }
      expect(unique.size).assertEqual(keys.length);
      expect(PreferencesConstants.STORE_NAME.length > 0).assertTrue();
    });

    it('common_constants_hold_valid_title_bar_hide_params', 0, () => {
      // 动态显隐只在内容穿透（滚动联动）模式下有意义，二者不能自相矛盾。
      if (CommonConstants.TITLE_BAR_DYNAMIC_HIDE) {
        expect(CommonConstants.CONTENT_UNDER_TITLE_BAR).assertTrue();
      }
      expect(CommonConstants.TITLE_BAR_HIDE_OFFSET_VP >= 0).assertTrue();
      // hideRatio 取值区间由系统约定为 [1.0, 3.0]。
      expect(CommonConstants.TITLE_BAR_HIDE_RATIO >= 1.0 && CommonConstants.TITLE_BAR_HIDE_RATIO <= 3.0).assertTrue();
      expect(CommonConstants.TITLE_BAR_BLUR_START_VP <= CommonConstants.TITLE_BAR_BLUR_END_VP).assertTrue();
    });
  });
}
