/*
 * ReviewStatCard.ets — 复习页的单个统计卡。
 *
 * 用独立 @ComponentV2 + @Param，确保 ProgressStore 变化时数值能刷新；
 * 不把动态数值塞进多参 @Builder（V2 下参数本身不触发刷新）。
 */

@ComponentV2
export struct ReviewStatCard {
  @Param value: ResourceStr = '';
  @Param label: ResourceStr = '';

  build() {
    Column({ space: $r('app.float.space_xxs') }) {
      Text(this.value)
        .fontSize($r('app.float.font_size_title'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_primary'))
      Text(this.label)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: $r('app.float.review_stat_min_height') })
    .padding($r('app.float.space_m'))
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.ink_card'))
    .borderRadius($r('app.float.ink_radius_card'))
    .border({ width: 1, color: $r('app.color.ink_line') })
  }
}
