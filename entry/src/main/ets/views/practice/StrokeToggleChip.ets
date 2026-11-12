/*
 * StrokeToggleChip.ets — 笔顺显示的紧凑开关 chip（序号 / 透视 / 步骤条）。
 *
 * 单个 @ComponentV2：状态由外部以 @Param 传入，点击通过 @Event 上报，
 * 避免多参 @Builder 不刷新的问题。
 */

import { themePalette } from '../../model/ThemePalette';

@ComponentV2
export struct StrokeToggleChip {
  @Param label: ResourceStr = '';
  @Param active: boolean = false;
  @Event onTap: () => void = () => {};

  build() {
    Text(this.label)
      .fontSize($r('app.float.font_size_caption'))
      .fontColor(this.active ? $r('app.color.hm_on_brand') : $r('app.color.hm_text_secondary'))
      .padding({
        left: $r('app.float.space_m'),
        right: $r('app.float.space_m'),
        top: $r('app.float.space_xs'),
        bottom: $r('app.float.space_xs')
      })
      .backgroundColor(this.active ? themePalette.fill() : $r('app.color.hm_divider'))
      .borderRadius($r('app.float.radius_chip'))
      .onClick(() => {
        this.onTap();
      })
  }
}
