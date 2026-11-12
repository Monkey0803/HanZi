/*
 * BreakpointConstants.ets — 响应式断点配置。
 *
 * 用 ArkUI 的 GridRow/GridCol 断点（以**窗口**宽度为参照）做多设备适配：
 * xs/sm < 600vp（手机）、md 600–840vp（折叠屏展开 / 小平板）、lg >= 840vp（平板 / 横屏）。
 * 内容在 md/lg 下收窄并居中，避免大屏上一行文字拉满整个宽度。
 */
export class BreakpointConstants {
  /** 栅格总列数。 */
  static readonly GRID_COLUMNS: number = 12;
  /** 窗口宽度断点（vp）：sm -> md -> lg。 */
  static readonly WINDOW_BREAKPOINTS: string[] = ['600vp', '840vp'];
  /** 「宽屏」媒体查询条件（lg 起点），供 mediaquery 在代码里取断点用。 */
  static readonly WIDE_MEDIA_QUERY: string = '(width>=840vp)';
}
