import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { safeArea } from '../service/SafeAreaController';
import { Toast } from '@monkey0803/toast-kit';
import { Keyboard } from '@monkey0803/keyboard-kit';
import { setupToast } from '../common/utils/ToastSetup';

const DOMAIN: number = 0x0000;
const TAG: string = 'HdsEntry';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 主题由设置页控制；这里先跟随系统，恢复订阅后由 ThemeController 覆盖。
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'setColorMode failed');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 全局 Toast / 软键盘：主窗口上下文各注册一次，页面内直接 Toast.show 即可。
    Toast.init(windowStage);
    Keyboard.init(windowStage);
    setupToast();
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}d', err.code);
        return;
      }
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      // 全局沉浸：内容延伸至系统栏区域。
      mainWindow.setWindowLayoutFullScreen(true).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}d', e.code);
      });
      // 全屏沉浸：读取系统状态栏 / 导航条高度，供页面内容与悬浮页签栏动态避让。
      safeArea.attach(this.context, mainWindow);
      // 窗口背景色兜底（与背景图主色调一致），避免页面切换时闪白。
      // 颜色不硬编码：从 start_window_background 资源读取（含深浅色适配），转成 #AARRGGBB。
      const colorValue: number = this.context.resourceManager.getColorSync($r('app.color.start_window_background').id);
      const fallback: string = '#' + (colorValue >>> 0).toString(16).padStart(8, '0').toUpperCase();
      mainWindow.setWindowBackgroundColor(fallback);
    });
  }

  /** 接续恢复不会调用 onWindowStageCreate，仍须加载首页并初始化窗口。 */
  onWindowStageRestore(windowStage: window.WindowStage): void {
    this.onWindowStageCreate(windowStage);
  }

  onDestroy(): void {
    Toast.release();
    Keyboard.release();
    safeArea.detach();
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }
}
