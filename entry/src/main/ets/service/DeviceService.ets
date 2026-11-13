/*
 * DeviceService.ets — 代码侧的多设备断点（@ObservedV2）。
 *
 * `ResponsiveContent` 用 GridRow/GridCol 断点做**声明式**收窄；但在**代码里**要按断点切换结构
 * （例如宽屏用侧栏替掉底部页签）就需要一个可观察的布尔值 —— 用 UIContext 的 mediaquery 监听
 * 宽屏条件，以 vp 为单位，免去 px/vp 换算。
 *
 * 注意用 `uiContext.getMediaQuery().matchMediaSync(...)`：全局 `@ohos.mediaquery.matchMediaSync`
 * 自 API 18 起已废弃。由**外壳（Index）单独持有** start/stop，其他页面只读 `medium` / `wide`，
 * 避免子页面 stop() 把外壳的订阅停掉。
 */

import { UIContext, mediaquery } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';

@ObservedV2
export class DeviceService {
  /** 窗口是否达到「中等」断点（>= 600vp：折叠展开 / 平板 / 2in1）。 */
  @Trace medium: boolean = false;
  /** 窗口是否达到「宽屏」断点（>= 840vp：平板 / 横屏 / 折叠展开）。 */
  @Trace wide: boolean = false;
  private mediumListener: mediaquery.MediaQueryListener | undefined = undefined;
  private wideListener: mediaquery.MediaQueryListener | undefined = undefined;

  /** 只应由外壳调用一次。 */
  start(uiContext: UIContext): void {
    if (this.mediumListener !== undefined || this.wideListener !== undefined) {
      return;
    }
    const mediumListener: mediaquery.MediaQueryListener =
      uiContext.getMediaQuery().matchMediaSync(BreakpointConstants.MEDIUM_MEDIA_QUERY);
    const wideListener: mediaquery.MediaQueryListener =
      uiContext.getMediaQuery().matchMediaSync(BreakpointConstants.WIDE_MEDIA_QUERY);
    this.mediumListener = mediumListener;
    this.wideListener = wideListener;
    this.medium = mediumListener.matches;
    this.wide = wideListener.matches;
    mediumListener.on('change', onMediumChange);
    wideListener.on('change', onWideChange);
  }

  /** 与 start 成对，只应由外壳调用。 */
  stop(): void {
    const mediumListener: mediaquery.MediaQueryListener | undefined = this.mediumListener;
    if (mediumListener !== undefined) {
      mediumListener.off('change');
      this.mediumListener = undefined;
    }
    const wideListener: mediaquery.MediaQueryListener | undefined = this.wideListener;
    if (wideListener !== undefined) {
      wideListener.off('change');
      this.wideListener = undefined;
    }
  }
}

/** 全局唯一实例。 */
export const deviceService: DeviceService = new DeviceService();

/** 回调写在类外，避免模块级函数里的 this。 */
function onMediumChange(result: mediaquery.MediaQueryResult): void {
  deviceService.medium = result.matches;
}

function onWideChange(result: mediaquery.MediaQueryResult): void {
  deviceService.wide = result.matches;
}
