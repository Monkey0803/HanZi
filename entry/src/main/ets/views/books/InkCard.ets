/*
 * InkCard.ets — 水墨卷轴卡片容器。
 *
 * 结构：上下各一条「轴身」细线 + 中间内容，卡片本体是暖白纸色 + 极淡墨线描边。
 * 所有颜色走资源（含深色模式），调用方只关心内容。
 */

@Builder
function emptyInkContent() {
}

@ComponentV2
export struct InkCard {
  @BuilderParam content: () => void = emptyInkContent;

  /** 卷轴「轴头」：卡片上下各一条短横线，比通栏细线更像卷轴装裱。 */
  @Builder
  axisLine() {
    Row()
      .width(28)
      .height(2)
      .borderRadius(1)
      .backgroundColor($r('app.color.ink_line'))
  }

  build() {
    Column() {
      this.axisLine()
      Column() {
        this.content()
      }
      .width('100%')
      this.axisLine()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.ink_card'))
    .borderRadius($r('app.float.ink_radius_card'))
    .border({ width: 1, color: $r('app.color.ink_line') })
  }
}
