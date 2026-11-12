/*
 * ScrollerRegistry.ets — 页面滚动控制器注册表。
 *
 * 「内容穿透标题栏的动态模糊」需要把各页的滚动控制器交给 HdsNavigation.bindToScrollable()。
 * Scroller 是原生控制器对象，不适合跨组件用 @Param 传递（V2 的 @Param 类型不接受它），
 * 因此做成模块级单例：页面绑定、各页取用同一份实例。
 */

export class ScrollerRegistry {
  /** 首页（课本）列表滚动控制器。 */
  readonly home: Scroller = new Scroller();
  /** 复习页滚动控制器。 */
  readonly review: Scroller = new Scroller();
  /** 设置页滚动控制器。 */
  readonly settings: Scroller = new Scroller();
  /** 图片页滚动控制器。 */
  readonly images: Scroller = new Scroller();
}

/** 全局唯一实例。 */
export const scrollers: ScrollerRegistry = new ScrollerRegistry();
