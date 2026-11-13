/*
 * CommonConstants.ets — 应用级通用逻辑常量。
 *
 * 纯逻辑常量（超时、分页、默认下标等）集中在这里；随环境变化的颜色 / 文本 / 尺寸
 * 一律走 resources（color.json / string.json / float.json）。
 */
export class CommonConstants {
  /** 应用启动时的默认页签下标。 */
  static readonly DEFAULT_TAB_INDEX: number = 0;

  /** HDS 紧凑标题栏（MINI）高度（vp）——HDS 规范固定值，用于可滚动内容的首屏顶部占位。 */
  static readonly TITLE_BAR_HEIGHT_VP: number = 56;

  /**
   * 标题栏与内容的关系：
   * - true  —— 内容穿透标题栏（沉浸式动态模糊）：标题栏的 enableComponentSafeArea 为 false，
   *            内容全屏布局、滚动时穿过标题栏下方，由 scrollEffectOpts 触发模糊。
   * - false —— 内容避让标题栏：enableComponentSafeArea 为 true，内容从标题栏下方开始。
   * 两种模式互斥；切换这一项即可（视图的顶部预留由 underTitleBar 参数联动）。
   */
  static readonly CONTENT_UNDER_TITLE_BAR: boolean = true;

  /**
   * 标题栏 / 状态栏的动态显隐（沉浸光感的一环）。
   * - true  —— 上滑到固定位置隐藏、下滑到固定位置显示（HideMode.SCROLL_UP_TO）。
   *            仅在有内容滚动联动的穿透模式下有意义（需配合 bindToScrollable）。
   * - false —— 标题栏 / 状态栏常驻（当前产品要求：标题栏不随滑动隐藏）。
   * 与 CONTENT_UNDER_TITLE_BAR 同时为 true 时才会挂上 dynamicHideTitleBar。
   */
  static readonly TITLE_BAR_DYNAMIC_HIDE: boolean = false;

  /** 动态显隐的滚动偏移阈值（vp）：滚动到该位置开始隐藏标题栏。 */
  static readonly TITLE_BAR_HIDE_OFFSET_VP: number = 0;

  /** 标题栏隐藏长度与滚动距离之比，取值 [1.0, 3.0]（每滚动 1vp，标题栏隐藏 1/hideRatio vp）。 */
  static readonly TITLE_BAR_HIDE_RATIO: number = 2.0;

  /** 动态模糊的生效区间（vp）：滚动偏移在 [start, end] 之间时标题栏逐渐变模糊。 */
  static readonly TITLE_BAR_BLUR_START_VP: number = 0;
  static readonly TITLE_BAR_BLUR_END_VP: number = 20;

  /** 标题栏背景模糊半径（仅 GRADIENT_BLUR 模式生效，取值范围 [0, 128]）。 */
  static readonly TITLE_BAR_BLUR_RADIUS: number = 24;

  /**
   * 静止态标题栏的模糊半径：必须为 0。
   * 否则内容即使没有滚动，也会被标题栏背后的模糊带“吃掉”一截，看起来像已经沉浸。
   */
  static readonly TITLE_BAR_REST_BLUR_RADIUS: number = 0;
}
