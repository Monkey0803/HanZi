/*
 * ThemeController.ets — 主题（跟随系统 / 浅色 / 深色）。
 *
 * 跟随系统 = COLOR_MODE_NOT_SET；浅色 / 深色分别显式设定。颜色资源在
 * resources/{base,dark}/element/color.json，由平台自动切换。
 *
 * setColorMode 可能抛异常（调用时机在 UIAbility 生命周期之外时会失败），
 * 所以统一兜住：主题切不过去也不该把设置流程带崩。
 */

import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ThemeMode } from '../common/constants/SettingsConstants';

export class ThemeController {
  static apply(context: common.Context, mode: string): void {
    try {
      const applicationContext: common.ApplicationContext = context.getApplicationContext();
      if (mode === ThemeMode.DARK) {
        applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      } else if (mode === ThemeMode.LIGHT) {
        applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else {
        applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('ThemeController.apply failed: ' + error.code.toString());
    }
  }
}
