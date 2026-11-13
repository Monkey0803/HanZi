/*
 * PageTopSpacer.ets — 页面顶部统一占位（标题栏避让 + 呼吸间距）。
 *
 * 所有页面（页签 / 二级页）都用它作为可滚动内容的第一项：
 * - 穿透模式（underTitleBar=true）：高度 = 状态栏 + 标题栏 + 间距（SafeAreaController 统一计算）；
 * - 避让模式（underTitleBar=false）：只留一个常规间距。
 * 这样顶部间距只有一处来源，新增页面直接复用，不会再出现某页紧贴标题栏的情况。
 */

import { safeArea } from '../service/SafeAreaController';

@ComponentV2
export struct PageTopSpacer {
  @Param underTitleBar: boolean = true;

  build() {
    Row()
      .width('100%')
      .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))
  }
}
