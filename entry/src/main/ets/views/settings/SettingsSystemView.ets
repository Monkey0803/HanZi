/*
 * SettingsSystemView.ets — 「系统与隐私」二级页（纯展示 + 事件上报）。
 *
 * 内容：智感握姿、防窥保护；能力不支持时展示降级说明。
 */

import { common } from '@kit.AbilityKit';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { antiPeep } from '../../service/AntiPeep';
import { gripSensor } from '../../service/GripSensor';
import { safeArea } from '../../service/SafeAreaController';
import { SettingField, SettingsSectionTitle, SwitchSettingRow } from './SettingsRows';
import { ResponsiveContent } from '../ResponsiveContent';

@ComponentV2
export struct SettingsSystemView {
  /** 内容是否穿透标题栏：true 时顶部预留标题栏高度。 */
  @Param underTitleBar: boolean = false;

  private hostContext(): common.UIAbilityContext {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    return context as common.UIAbilityContext;
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column() {
          Row()
            .width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          SettingsSectionTitle({ title: $r('app.string.section_system') })
          Column() {
            SwitchSettingRow({
              icon: $r('sys.symbol.hand_raised_hexagon'),
              title: $r('app.string.row_grip'),
              field: SettingField.GRIP,
              onToggle: (value: boolean) => {
                settingsViewModel.setGripEnabled(value);
              }
            })
            Divider().color($r('app.color.hm_divider'))
            SwitchSettingRow({
              icon: $r('sys.symbol.eye_slash'),
              title: $r('app.string.row_antipeep'),
              field: SettingField.ANTI_PEEP,
              onToggle: (value: boolean) => {
                settingsViewModel.setAntiPeepEnabled(value, this.hostContext());
              }
            })
          }
          .width('100%')
          .backgroundColor($r('app.color.hm_card_background'))
          .borderRadius($r('app.float.radius_card'))

          if (!gripSensor.supported) {
            Text($r('app.string.aux_grip_unsupported'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .margin({ top: $r('app.float.space_s'), left: $r('app.float.space_xs') })
          }
          if (!antiPeep.supported) {
            Text($r('app.string.aux_antipeep_unsupported'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .margin({ top: $r('app.float.space_xs'), left: $r('app.float.space_xs') })
          }

          Row().width('100%').height($r('app.float.space_xl'))
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .clip(false)
    }
  }
}
