/*
 * SettingsTabView.ets — 设置页签（纯状态管理 V2）。
 *
 * 四个分区直接铺在同一页里（外观与语言 / 材质与动效 / 系统与隐私 / 笔顺与练习），
 * 不再有「首页 → 二级页」的跳转；各分区的行与开关见 views/settings/。
 *
 * 为什么主题色半模态放在这一层：bindSheet 必须挂在 Stack 内的已上树节点上，
 * 放进 Scroll 会被滚动容器裁切，所以由页签统一持有 AppSheet + ThemeColorSheet。
 */

import { appSettings } from '../model/AppSettings';
import { settingsViewModel } from '../viewmodel/SettingsViewModel';
import { scrollers } from '../service/ScrollerRegistry';
import { safeArea } from '../service/SafeAreaController';
import { AppSheet } from '../common/components/AppSheet';
import { SettingsLookSection } from './settings/SettingsLookSection';
import { SettingsMaterialSection } from './settings/SettingsMaterialSection';
import { SettingsSystemSection } from './settings/SettingsSystemSection';
import { SettingsStudySection } from './settings/SettingsStudySection';
import { SettingsAboutSection } from './settings/SettingsAboutSection';
import { ThemeColorSheet } from './settings/ThemeColorSheet';
import { ResponsiveContent } from './ResponsiveContent';
import { PageTopSpacer } from './PageTopSpacer';
import { RouterConstants } from '../common/constants/RouterConstants';

@ComponentV2
export struct SettingsTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  /** 内容是否穿透标题栏：true 时顶部预留标题栏高度，首屏内容不被标题栏遮住。 */
  @Param underTitleBar: boolean = false;
  /** 主题色取色面板显隐。 */
  @Local showThemeColor: boolean = false;

  private closeThemeColor(): void {
    this.showThemeColor = false;
    // 关闭时把预览色落盘（用户拖动取色器时只做预览，不写入设置）。
    settingsViewModel.setThemeColor(appSettings.themeColor);
  }

  build() {
    Stack() {
      ResponsiveContent() {
        Scroll(scrollers.settings) {
          Column() {
            // 透明标题栏占位：首屏顶部预留「状态栏 + 标题栏」高度，滚动时随内容上移。
            PageTopSpacer({ underTitleBar: this.underTitleBar })

            SettingsLookSection({
              onOpenThemeColor: () => {
                this.showThemeColor = true;
              }
            })
            SettingsMaterialSection()
            SettingsSystemSection()
            SettingsStudySection()
            SettingsAboutSection({
              onOpenData: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_ABOUT_DATA, '');
              },
              onOpenPrivacy: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_PRIVACY, '');
              }
            })

            // barOverlap(true) 时页签栏悬浮叠在内容上：底部预留避让，末行不被遮挡。
            Blank().height(safeArea.contentBottomInsetVp)
          }
          .width('100%')
          .padding({
            left: $r('app.float.space_l'),
            right: $r('app.float.space_l')
          })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        // 内容穿透标题栏：不裁剪，让内容能滚动到标题栏下方（配合动态模糊）。
        .clip(false)
        .backgroundColor($r('app.color.hm_page_transparent'))
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
