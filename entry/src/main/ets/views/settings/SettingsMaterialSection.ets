/*
 * SettingsMaterialSection.ets — 「材质与动效」分区（纯展示 + 事件上报）。
 *
 * 内容：沉浸光感总开关、材质类型、材质等级、光感反馈开关。
 */

import { MATERIAL_LEVEL_OPTIONS, MATERIAL_TYPE_OPTIONS } from '../../model/SettingsOptions';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { OptionSelectRow, SettingField, SettingsSectionTitle, SwitchSettingRow } from './SettingsRows';

@ComponentV2
export struct SettingsMaterialSection {
  build() {
    Column() {
      SettingsSectionTitle({ title: $r('app.string.settings_material_title') })
      Column() {
        SwitchSettingRow({
          icon: $r('sys.symbol.rays'),
          title: $r('app.string.row_immersive'),
          field: SettingField.IMMERSIVE,
          onToggle: (value: boolean) => {
            settingsViewModel.setImmersiveOn(value);
          }
        })
        Divider().color($r('app.color.hm_divider'))
        OptionSelectRow({
          icon: $r('sys.symbol.bolt'),
          title: $r('app.string.row_material_type'),
          choice: MATERIAL_TYPE_OPTIONS,
          field: SettingField.MATERIAL_TYPE,
          onPick: (id: string) => {
            settingsViewModel.setMaterialType(id);
          }
        })
        Divider().color($r('app.color.hm_divider'))
        OptionSelectRow({
          icon: $r('sys.symbol.slider_horizontal_2'),
          title: $r('app.string.row_material_level'),
          choice: MATERIAL_LEVEL_OPTIONS,
          field: SettingField.MATERIAL_LEVEL,
          onPick: (id: string) => {
            settingsViewModel.setMaterialLevel(id);
          }
        })
        Divider().color($r('app.color.hm_divider'))
        SwitchSettingRow({
          icon: $r('sys.symbol.bolt'),
          title: $r('app.string.row_light_effect'),
          field: SettingField.LIGHT_EFFECT,
          onToggle: (value: boolean) => {
            settingsViewModel.setLightEffectEnabled(value);
          }
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.hm_card_background'))
      .borderRadius($r('app.float.radius_card'))

      if (!settingsViewModel.immersiveSupported) {
        Text($r('app.string.aux_material_unsupported'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .margin({ top: $r('app.float.space_s'), left: $r('app.float.space_xs') })
      }
    }
    .width('100%')
  }
}
