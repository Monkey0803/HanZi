/*
 * PaperBackground.ets — 课本 / 复习页共用的水墨纸色背景。
 *
 * 纸色渐变 + 两团低透明度墨晕，不使用位图素材；颜色全部走资源（含深色模式）。
 */

@ComponentV2
export struct PaperBackground {
  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [[$r('app.color.ink_paper'), 0.0], [$r('app.color.ink_paper_deep'), 1.0]]
        })
      Column()
        .width(260)
        .height(260)
        .borderRadius(130)
        .backgroundColor($r('app.color.ink_paper_deep'))
        .opacity(0.9)
        .blur(80)
        .offset({ x: -90, y: -60 })
      Column()
        .width(220)
        .height(220)
        .borderRadius(110)
        .backgroundColor($r('app.color.ink_paper_deep'))
        .opacity(0.9)
        .blur(80)
        .offset({ x: 110, y: 320 })
    }
    .width('100%')
    .height('100%')
  }
}
