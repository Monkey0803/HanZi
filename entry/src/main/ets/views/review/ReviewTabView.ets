/*
 * ReviewTabView.ets — 复习页签。
 *
 * Phase 4 先提供入口与说明；进度队列、复习会话在 Phase 5 接入 ProgressStore。
 */

import { scrollers } from '../../service/ScrollerRegistry';
import { themePalette } from '../../model/ThemePalette';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { ResponsiveContent } from '../ResponsiveContent';

@ComponentV2
export struct ReviewTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  build() {
    ResponsiveContent() {
      Scroll(scrollers.review) {
        Column({ space: $r('app.float.space_l') }) {
          Row().width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          Column({ space: $r('app.float.space_s') }) {
            Text($r('app.string.review_title'))
              .fontSize($r('app.float.font_size_title'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.hm_text_primary'))
              .width('100%')
            Text($r('app.string.review_intro'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
            Text($r('app.string.review_coming_soon'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
            Button($r('app.string.review_start'))
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .backgroundColor(themePalette.fill())
              .fontColor($r('app.color.hm_on_brand'))
              .enabled(false)
              .width('100%')
          }
          .width('100%')
          .padding($r('app.float.space_l'))
          .backgroundColor($r('app.color.hanzi_card'))
          .borderRadius($r('app.float.book_card_radius'))
          .alignItems(HorizontalAlign.Start)

          Blank().height(safeArea.contentBottomInsetVp)
        }
        .width('100%')
        .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
  }
}
