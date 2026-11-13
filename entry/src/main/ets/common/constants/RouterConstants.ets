/*
 * RouterConstants.ets — 路由名常量，消除魔法字符串。
 *
 * 单模块内用 NavPathStack + @Builder 映射即可；跨模块跳转时应改用系统路由表
 * （module.json5 的 routerMap + resources/base/profile/route_map.json）。
 */
export class RouterConstants {
  static readonly PAGE_DETAIL: string = 'detail';
  /** 册详情。 */
  static readonly PAGE_BOOK: string = 'book';
  /** 课详情。 */
  static readonly PAGE_LESSON: string = 'lesson';
  /** 字详情。 */
  static readonly PAGE_CHAR: string = 'char';
  /** 全屏专注练字。 */
  static readonly PAGE_PRACTICE: string = 'practice';
  /** 字表 / 查字。 */
  static readonly PAGE_CATALOG: string = 'catalog';
  /** 复习会话。 */
  static readonly PAGE_REVIEW_SESSION: string = 'reviewSession';
  /** 完整错题本。 */
  static readonly PAGE_MISTAKES: string = 'mistakes';
  /** 数据来源与许可。 */
  static readonly PAGE_ABOUT_DATA: string = 'aboutData';
  /** 隐私政策。 */
  static readonly PAGE_PRIVACY: string = 'privacy';
  /** 许可全文。 */
  static readonly PAGE_LICENSE: string = 'license';
  /** 全屏图片预览（图片领域使用；基模板只保留桩件与路由分支）。 */
  static readonly PAGE_PREVIEW: string = 'imagePreview';
}
