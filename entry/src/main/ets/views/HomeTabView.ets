/*
 * HomeTabView.ets — 可滚动的底部沉浸列表示例（纯展示 + 事件上报）。
 *
 * List 占满页签内容区，文章行可以从 HdsTabs 悬浮栏后方经过；末尾偏移保证最后一行可见。
 */

import { RouterConstants } from '../common/constants/RouterConstants';
import { deviceService } from '../service/DeviceService';
import { scrollers } from '../service/ScrollerRegistry';
import { safeArea } from '../service/SafeAreaController';
import { ResponsiveContent } from './ResponsiveContent';
import { PageTopSpacer } from './PageTopSpacer';

const SAMPLE_ROWS: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  13, 14, 15, 16, 17, 18, 19, 20];

@ComponentV2
export struct HomeTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  build() {
    ResponsiveContent() {
      List({ scroller: scrollers.home }) {
        ListItem() {
          Column({ space: $r('app.float.space_l') }) {
            PageTopSpacer({ underTitleBar: this.underTitleBar })
            Text($r('app.string.home_placeholder'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
            Button($r('app.string.home_open_detail'))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontColor($r('app.color.hm_brand'))
              .onClick(() => {
                this.navPathStack.pushPath(new NavPathInfo(RouterConstants.PAGE_DETAIL, ''));
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .margin({ bottom: $r('app.float.space_l') })

        ForEach(SAMPLE_ROWS, (item: number) => {
          ListItem() {
            Text($r('app.string.home_sample_row', item))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_primary'))
              .width('100%')
              .padding($r('app.float.space_l'))
              .backgroundColor($r('app.color.hm_card_background'))
              .borderRadius($r('app.float.radius_card'))
          }
          .margin({ bottom: $r('app.float.space_s') })
        }, (item: number) => item.toString())
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      .scrollBar(BarState.Off)
      .clip(false)
      // 宽屏侧栏没有底部悬浮页签，不留末尾空白。
      .contentEndOffset(deviceService.wide ? 0 : safeArea.contentBottomInsetVp)
      .backgroundColor($r('app.color.hm_page_transparent'))
    }
  }
}
