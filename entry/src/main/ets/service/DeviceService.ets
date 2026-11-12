/*
 * DeviceService.ets — 代码侧的多设备断点（@ObservedV2）。
 *
 * `ResponsiveContent` 用 GridRow/GridCol 断点做**声明式**收窄；但在**代码里**要按断点切换结构
 * （例如宽屏用侧栏替掉底部页签）就需要一个可观察的布尔值 —— 用 UIContext 的 mediaquery 监听
 * 宽屏条件，以 vp 为单位，免去 px/vp 换算。
 *
 * 注意用 `uiContext.getMediaQuery().matchMediaSync(...)`：全局 `@ohos.mediaquery.matchMediaSync`
 * 自 API 18 起已废弃。由**外壳（Index）单独持有** start/stop，其他页面只读 `wide`，
 * 避免子页面 stop() 把外壳的订阅停掉。
 */

import { UIContext, mediaquery } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';

@ObservedV2
export class DeviceService {
  /** 窗口是否达到「宽屏」断点（>= 840vp：平板 / 横屏 / 折叠展开）。 */
  @Trace wide: boolean = false;
  private listener: mediaquery.MediaQueryListener | undefined = undefined;

  /** 只应由外壳调用一次。 */
  start(uiContext: UIContext): void {
    if (this.listener !== undefined) {
      return;
    }
    const listener: mediaquery.MediaQueryListener =
      uiContext.getMediaQuery().matchMediaSync(BreakpointConstants.WIDE_MEDIA_QUERY);
    this.listener = listener;
    this.wide = listener.matches;
    listener.on('change', onWideChange);
  }

  /** 与 start 成对，只应由外壳调用。 */
  stop(): void {
    const listener: mediaquery.MediaQueryListener | undefined = this.listener;
    if (listener !== undefined) {
      listener.off('change');
      this.listener = undefined;
    }
  }
}

/** 全局唯一实例。 */
export const deviceService: DeviceService = new DeviceService();

/** 回调写在类外，避免模块级函数里的 this。 */
function onWideChange(result: mediaquery.MediaQueryResult): void {
  deviceService.wide = result.matches;
}
