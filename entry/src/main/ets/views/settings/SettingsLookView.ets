/*
 * SettingsLookView.ets — 「外观与语言」二级页（纯展示 + 事件上报）。
 *
 * 内容：主题、主题色（预设 + 系统取色器）、语言。
 * 行为全部在 SettingsViewModel；本页只读 appSettings 的 @Trace 字段。
 */

import { common } from '@kit.AbilityKit';
import { appSettings } from '../../model/AppSettings';
import { LANGUAGE_OPTIONS, THEME_OPTIONS } from '../../model/SettingsOptions';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { AppSheet } from '../../common/components/AppSheet';
import { safeArea } from '../../service/SafeAreaController';
import { themePalette } from '../../model/ThemePalette';
import { themeColorLabelOf } from '../../model/ThemeColorOptions';
import { NavSettingRow, OptionSelectRow, SettingField, SettingsSectionTitle } from './SettingsRows';
import { ThemeColorSheet } from './ThemeColorSheet';
import { ResponsiveContent } from '../ResponsiveContent';

@ComponentV2
export struct SettingsLookView {
  /** 内容是否穿透标题栏：true 时顶部预留标题栏高度。 */
  @Param underTitleBar: boolean = false;
  /** 主题色取色面板显隐。 */
  @Local showThemeColor: boolean = false;

  private hostContext(): common.UIAbilityContext {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    return context as common.UIAbilityContext;
  }

  private closeThemeColor(): void {
    this.showThemeColor = false;
    settingsViewModel.setThemeColor(appSettings.themeColor);
  }

  build() {
    Stack() {
      ResponsiveContent() {
        Scroll() {
          Column() {
            // 透明标题栏占位：首屏顶部预留「状态栏 + 标题栏」高度。
            Row()
              .width('100%')
              .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

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
                  this.showThemeColor = true;
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

            Row().width('100%').height($r('app.float.space_xl'))
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        // Scroll 默认会把短内容整体居中；这里固定从顶部开始排。
        .align(Alignment.TopStart)
        .clip(false)
      }

      AppSheet({
        visible: this.showThemeColor,
        initialSize: SheetSize.MEDIUM,
        showClose: false,
        onDismiss: () => {
          this.closeThemeColor();
        }
      }) {
        ThemeColorSheet({
          currentColor: appSettings.themeColor,
          onPreview: (hex: string) => {
            settingsViewModel.previewThemeColor(hex);
          },
          onCommit: (hex: string) => {
            settingsViewModel.setThemeColor(hex);
            this.showThemeColor = false;
          },
          onClose: () => {
            this.closeThemeColor();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.hm_page_transparent'))
  }
}
