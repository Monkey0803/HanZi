/*
 * SettingsStudyView.ets — 「笔顺与练习」二级页（纯展示 + 事件上报）。
 *
 * 内容：笔顺序号、运笔骨架、笔顺步骤条与字格样式；字详情页的内联开关与这里共用 appSettings。
 */

import { GRID_OPTIONS } from '../../model/SettingsOptions';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { safeArea } from '../../service/SafeAreaController';
import { OptionSelectRow, SettingField, SettingsSectionTitle, SwitchSettingRow } from './SettingsRows';
import { ResponsiveContent } from '../ResponsiveContent';

@ComponentV2
export struct SettingsStudyView {
  /** 内容是否穿透标题栏：true 时顶部预留标题栏高度。 */
  @Param underTitleBar: boolean = false;

  build() {
    ResponsiveContent() {
      Scroll() {
        Column() {
          Row()
            .width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          SettingsSectionTitle({ title: $r('app.string.settings_study_title') })
          Column() {
            SwitchSettingRow({
              icon: $r('sys.symbol.checkmark_circle'),
              title: $r('app.string.settings_show_numbers'),
              field: SettingField.SHOW_NUMBERS,
              onToggle: (value: boolean) => {
                settingsViewModel.setShowStrokeNumbers(value);
              }
            })
            Divider().color($r('app.color.hm_divider'))
            SwitchSettingRow({
              icon: $r('sys.symbol.rays'),
              title: $r('app.string.settings_show_skeleton'),
              field: SettingField.SHOW_SKELETON,
              onToggle: (value: boolean) => {
                settingsViewModel.setShowSkeleton(value);
              }
            })
            Divider().color($r('app.color.hm_divider'))
            SwitchSettingRow({
              icon: $r('sys.symbol.slider_horizontal_2'),
              title: $r('app.string.settings_show_steps'),
              field: SettingField.SHOW_STEPS,
              onToggle: (value: boolean) => {
                settingsViewModel.setShowStrokeSteps(value);
              }
            })
            Divider().color($r('app.color.hm_divider'))
            OptionSelectRow({
              icon: $r('sys.symbol.square_grid_2x2'),
              title: $r('app.string.settings_grid_style'),
              choice: GRID_OPTIONS,
              field: SettingField.GRID_STYLE,
              onPick: (id: string) => {
                settingsViewModel.setGridStyle(id);
              }
            })
          }
          .width('100%')
          .backgroundColor($r('app.color.hm_card_background'))
          .borderRadius($r('app.float.radius_card'))

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
