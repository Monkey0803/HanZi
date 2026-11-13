/*
 * SettingsSystemSection.ets — 「系统与隐私」分区（纯展示 + 事件上报）。
 *
 * 内容：智感握姿、防窥保护；能力不支持时展示降级说明。
 */

import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { gripSensor } from '../../service/GripSensor';
import { SettingField, SettingsSectionTitle, SwitchSettingRow } from './SettingsRows';

@ComponentV2
export struct SettingsSystemSection {
  build() {
    Column() {
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
    }
    .width('100%')
  }
}
