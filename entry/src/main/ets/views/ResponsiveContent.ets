/*
 * ResponsiveContent.ets — 多设备内容容器。
 *
 * 用 GridRow/GridCol + 窗口断点把内容在宽屏上收窄并居中（手机满宽、折叠屏展开 10/12、平板 8/12）。
 * 用法（尾随闭包即 @BuilderParam）：
 *   ResponsiveContent() { ...页面内容... }
 */

import { BreakpointConstants } from '../common/constants/BreakpointConstants';

/** @BuilderParam 的默认值必须是 @Builder 函数，不能是箭头函数。 */
@Builder
function emptyContent() {
}

@ComponentV2
export struct ResponsiveContent {
  @BuilderParam content: () => void = emptyContent;

  build() {
    GridRow({
      columns: BreakpointConstants.GRID_COLUMNS,
      gutter: { x: $r('app.float.space_l') },
      breakpoints: {
        value: BreakpointConstants.WINDOW_BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    }) {
      GridCol({
        span: { xs: 12, sm: 12, md: 10, lg: 8 },
        offset: { xs: 0, sm: 0, md: 1, lg: 2 }
      }) {
        this.content()
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
