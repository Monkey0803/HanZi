/*
 * ImagePreviewView.ets — 全屏图片预览的占位实现（基模板）。
 *
 * `--domain image` 时被 application-image/ 里的真实实现覆盖（用 ImageKit 全分辨率 + HDR 解码）。
 * 基模板下没有入口推入该路由，但仍需与真实实现保持相同的入参接口。
 */

@ComponentV2
export struct ImagePreviewView {
  @Param navPathStack: NavPathStack = new NavPathStack();

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.hm_page_transparent'))
  }
}
