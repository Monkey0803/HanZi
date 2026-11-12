/*
 * SettingsLookSection.ets — 「外观与语言」分区（纯展示 + 事件上报）。
 *
 * 内容：主题、主题色（预设 + 系统取色器）、语言。
 * 行为全部在 SettingsViewModel；本分区只读 appSettings 的 @Trace 字段。
 * 主题色半模态的宿主在 SettingsTabView（半模态不能挂在 Scroll 里，否则会被裁切），
 * 这里只通过 @Event 上报「要打开取色面板」。
 */

import { common } from '@kit.AbilityKit';
import { appSettings } from '../../model/AppSettings';
import { LANGUAGE_OPTIONS, THEME_OPTIONS } from '../../model/SettingsOptions';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { themePalette } from '../../model/ThemePalette';
import { themeColorLabelOf } from '../../model/ThemeColorOptions';
import { NavSettingRow, OptionSelectRow, SettingField, SettingsSectionTitle } from './SettingsRows';

@ComponentV2
export struct SettingsLookSection {
  /** 打开主题色取色面板。 */
  @Event onOpenThemeColor: () => void = () => {
  };

  private hostContext(): common.UIAbilityContext {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    return context as common.UIAbilityContext;
  }

  build() {
    Column() {
      SettingsSectionTitle({ title: $r('app.string.section_appearance') })
      Column() {
        OptionSelectRow({
          icon: $r('sys.symbol.paintpalette'),
          title: $r('app.string.row_theme'),
          choice: THEME_OPTIONS,
          field: SettingField.THEME,
          onPick: (id: string) => {
            settingsViewModel.setTheme(this.hostContext(), id);
          }
        })
        Divider().color($r('app.color.hm_divider'))
        NavSettingRow({
          icon: $r('sys.symbol.circle'),
          title: $r('app.string.row_theme_color'),
          detail: themeColorLabelOf(appSettings.themeColor),
          showDot: true,
          dotColor: themePalette.accent(),
          onOpen: () => {
            this.onOpenThemeColor();
          }
        })
        Divider().color($r('app.color.hm_divider'))
        OptionSelectRow({
          icon: $r('sys.symbol.translate'),
          title: $r('app.string.row_language'),
          choice: LANGUAGE_OPTIONS,
          field: SettingField.LANGUAGE,
          onPick: (id: string) => {
            settingsViewModel.setLanguage(id);
          }
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.hm_card_background'))
      .borderRadius($r('app.float.radius_card'))
    }
    .width('100%')
  }
}
