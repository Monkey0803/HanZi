/*
 * SettingsTabView.ets — 设置页签首页（纯索引，纯状态管理 V2）。
 *
 * 三个二级页入口：外观与语言 / 材质与动效 / 系统与隐私。
 * 具体开关都在 views/settings/ 下，页签只负责「找到」与导航。
 *
 * 关键约束：入口行的 detail 读的是 appSettings 的 @Trace 字段，
 * 因此在二级页改完返回时，这里会自动刷新。
 */

import { appSettings } from '../model/AppSettings';
import { MATERIAL_LEVEL_OPTIONS, THEME_OPTIONS, GRID_OPTIONS } from '../model/SettingsOptions';
import { MaterialController } from '../service/MaterialController';
import { scrollers } from '../service/ScrollerRegistry';
import { safeArea } from '../service/SafeAreaController';
import { RouterConstants } from '../common/constants/RouterConstants';
import { NavSettingRow, SettingsSectionTitle } from './settings/SettingsRows';
import { ResponsiveContent } from './ResponsiveContent';

@ComponentV2
export struct SettingsTabView {
  /** 内容是否穿透标题栏：true 时顶部预留标题栏高度，首屏内容不被标题栏遮住。 */
  @Param underTitleBar: boolean = false;
  /** 全局唯一的导航栈，由外壳 pages/Index 传入。 */
  @Param navPathStack: NavPathStack = new NavPathStack();

  /** 材质入口的当前状态文案：不支持时直接显示降级说明。 */
  private materialDetail(): ResourceStr {
    if (!MaterialController.immersiveSupported()) {
      return $r('app.string.aux_material_unsupported');
    }
    return MATERIAL_LEVEL_OPTIONS.labelOf(appSettings.materialLevel);
  }

  build() {
    ResponsiveContent() {
      Scroll(scrollers.settings) {
        Column() {
          // 透明标题栏占位：首屏顶部预留「状态栏 + 标题栏」高度，滚动时随内容上移。
          Row().width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          SettingsSectionTitle({ title: $r('app.string.tab_settings') })
          Column() {
            NavSettingRow({
              icon: $r('sys.symbol.paintpalette'),
              title: $r('app.string.settings_look_title'),
              detail: THEME_OPTIONS.labelOf(appSettings.themeMode),
              onOpen: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_SETTINGS_LOOK, '');
              }
            })
            Divider().color($r('app.color.hm_divider'))
            NavSettingRow({
              icon: $r('sys.symbol.rays'),
              title: $r('app.string.settings_material_title'),
              detail: this.materialDetail(),
              onOpen: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_SETTINGS_MATERIAL, '');
              }
            })
            Divider().color($r('app.color.hm_divider'))
            NavSettingRow({
              icon: $r('sys.symbol.hand_raised_hexagon'),
              title: $r('app.string.settings_system_title'),
              onOpen: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_SETTINGS_SYSTEM, '');
              }
            })
            Divider().color($r('app.color.hm_divider'))
            NavSettingRow({
              icon: $r('sys.symbol.checkmark_circle'),
              title: $r('app.string.settings_study_title'),
              detail: GRID_OPTIONS.labelOf(appSettings.gridStyle),
              onOpen: () => {
                this.navPathStack.pushPathByName(RouterConstants.PAGE_SETTINGS_STUDY, '');
              }
            })
          }
          .width('100%')
          .backgroundColor($r('app.color.hm_card_background'))
          .borderRadius($r('app.float.radius_card'))

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
  }
}
