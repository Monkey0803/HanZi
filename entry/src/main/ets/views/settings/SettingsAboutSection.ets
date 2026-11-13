/*
 * SettingsAboutSection.ets — 「关于」分区（纯状态管理 V2）。
 *
 * 展示品牌标记、应用名、简介与版本号；复用设置页的小节标题与卡片样式，
 * 与外观 / 材质 / 系统 / 笔顺四个分区保持视觉一致。
 */

import { LogoMark } from '../../common/components/LogoMark';
import { SettingsSectionTitle } from './SettingsRows';

@ComponentV2
export struct SettingsAboutSection {
  build() {
    Column() {
      SettingsSectionTitle({ title: $r('app.string.settings_about_title') })
      Column() {
        Row({ space: $r('app.float.space_m') }) {
          LogoMark({ markSize: 44 })
          Column({ space: $r('app.float.space_xxs') }) {
            Text($r('app.string.about_app_name'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text($r('app.string.about_app_description'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({
          left: $r('app.float.space_m'),
          right: $r('app.float.space_m'),
          top: $r('app.float.space_m'),
          bottom: $r('app.float.space_m')
        })
        Divider().color($r('app.color.hm_divider'))
        Row() {
          Text($r('app.string.about_app_version'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
        }
        .width('100%')
        .padding({
          left: $r('app.float.space_m'),
          right: $r('app.float.space_m'),
          top: $r('app.float.space_s'),
          bottom: $r('app.float.space_s')
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.hm_card_background'))
      .borderRadius($r('app.float.radius_card'))
    }
    .width('100%')
  }
}
