/*
 * StrokeThemeFactory.ets — 从资源构建画布配色。
 *
 * UI 侧必须用工厂取色，避免在 .ets 里硬编码十六进制；
 * StrokeTheme 自身的默认值只服务单测与兜底构造。
 */

import { common } from '@kit.AbilityKit';
import { StrokeTheme } from '../model/StrokeModels';
import { themePalette } from '../model/ThemePalette';
import { ColorUtil } from '../common/utils/ColorUtil';

export class StrokeThemeFactory {
  static fromContext(context: common.Context): StrokeTheme {
    const theme: StrokeTheme = new StrokeTheme();
    theme.ink = ColorUtil.fromResource(context, $r('app.color.hanzi_ink').id);
    theme.grid = ColorUtil.fromResource(context, $r('app.color.hanzi_grid').id);
    theme.outline = ColorUtil.fromResource(context, $r('app.color.hanzi_outline').id);
    theme.active = themePalette.accent();
    theme.error = ColorUtil.fromResource(context, $r('app.color.hanzi_error').id);
    theme.success = ColorUtil.fromResource(context, $r('app.color.hanzi_success').id);
    theme.skeleton = ColorUtil.fromResource(context, $r('app.color.hanzi_skeleton').id);
    theme.skeletonActive = ColorUtil.fromResource(context, $r('app.color.hanzi_skeleton_active').id);
    theme.numberBg = ColorUtil.fromResource(context, $r('app.color.hanzi_number_bg').id);
    theme.numberBorder = ColorUtil.fromResource(context, $r('app.color.hanzi_number_border').id);
    theme.numberText = ColorUtil.fromResource(context, $r('app.color.hanzi_number_text').id);
    theme.numberActiveBg = ColorUtil.fromResource(context, $r('app.color.hanzi_number_active_bg').id);
    theme.numberActiveText = ColorUtil.fromResource(context, $r('app.color.hanzi_number_active_text').id);
    return theme;
  }
}
