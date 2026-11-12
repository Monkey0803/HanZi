/*
 * SettingsMaterialSection.ets — 「材质与动效」分区（纯展示 + 事件上报）。
 *
 * 内容：沉浸光感总开关、材质类型、材质等级、光感反馈开关；
 * 以及应用级材质状态与设备算力档的只读说明。
 */

import { customImmersiveViewModel } from '../../viewmodel/CustomImmersiveViewModel';
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

      // 应用级开关（module.json5 metadata）的运行时状态：三态，不简化成「开 / 关」。
      Text(settingsViewModel.stateCaption)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .margin({ top: $r('app.float.space_s'), left: $r('app.float.space_xs') })

      // 设备材质等级（算力档）：只读展示，应用无法设置。
      Text(settingsViewModel.levelCaption)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .margin({ top: $r('app.float.space_xs'), left: $r('app.float.space_xs') })

      if (!settingsViewModel.immersiveSupported) {
        Text($r('app.string.aux_material_unsupported'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .margin({ top: $r('app.float.space_s'), left: $r('app.float.space_xs') })
      }

      // 自定义沉浸光感：标题栏与底部页签共用同一份 plan，这里只展示实际生效档位与降级原因。
      SettingsSectionTitle({ title: $r('app.string.section_custom_immersive') })
      Column() {
        Text(customImmersiveViewModel.reasonText())
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
          .padding({
            left: $r('app.float.space_m'),
            right: $r('app.float.space_m'),
            top: $r('app.float.space_m'),
            bottom: $r('app.float.space_m')
          })
      }
      .width('100%')
      .backgroundColor($r('app.color.hm_card_background'))
      .borderRadius($r('app.float.radius_card'))
    }
    .width('100%')
  }
}
