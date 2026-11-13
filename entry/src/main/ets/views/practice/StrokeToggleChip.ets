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
  @Local hovering: boolean = false;

  build() {
    Button(this.label)
      .buttonStyle(ButtonStyleMode.NORMAL)
      .fontSize($r('app.float.font_size_caption'))
      .fontColor(this.active ? $r('app.color.hm_on_brand') : $r('app.color.hm_text_secondary'))
      .height($r('app.float.practice_control_min_height'))
      .padding({
        left: $r('app.float.space_m'),
        right: $r('app.float.space_m')
      })
      .backgroundColor(this.active ? themePalette.fill() : $r('app.color.hm_divider'))
      .opacity(this.hovering ? 0.82 : 1)
      .borderRadius($r('app.float.radius_chip'))
      .focusable(true)
      .accessibilityDescription(this.active ? $r('app.string.common_on') : $r('app.string.common_off'))
      .onHover((isHovering: boolean) => {
        this.hovering = isHovering;
      })
      .onClick(() => {
        this.onTap();
      })
  }
}
