/*
 * ImageTabView.ets — 图片领域页签的占位实现（基模板）。
 *
 * `--domain image` 时被 application-image/ 里的真实实现覆盖。基模板下 IMAGE_DOMAIN 为 false，
 * 该页签根本不会挂载；但仍需与真实实现保持相同的入参接口（Index 会编译期携带 underTitleBar）。
 */

@ComponentV2
export struct ImageTabView {
  @Param underTitleBar: boolean = false;
  @Param navPathStack: NavPathStack = new NavPathStack();

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.hm_page_transparent'))
  }
}
