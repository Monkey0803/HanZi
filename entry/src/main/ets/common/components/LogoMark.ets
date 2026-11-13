/*
 * LogoMark.ets — HanZi 品牌标记（纯状态管理 V2）。
 *
 * base/media/logo_mark.svg 为浅色墨迹 + 朱红印章，dark/media/logo_mark.svg 为深色墨迹 + 浅红印章；
 * 同名资源由系统按深浅色自动解析，组件不需要读取 themePalette.isDark。
 */

@ComponentV2
export struct LogoMark {
  @Param markSize: number = 40;

  build() {
    Image($r('app.media.logo_mark'))
      .width(this.markSize)
      .height(this.markSize)
      .objectFit(ImageFit.Contain)
      .interpolation(ImageInterpolation.High)
      .accessibilityText($r('app.string.logo_mark_a11y'))
  }
}
