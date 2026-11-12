/*
 * ReviewConstants.ets — 复习相关的纯逻辑常量。
 *
 * 只放数值/枚举/语义 id，不放 UI 文案与尺寸（那些走 resources）。
 */

/** 复习卡正面内容。 */
export enum ReviewCardMode {
  /** 看字读音：正面汉字，翻面拼音 + 例词。 */
  CHAR = 'char',
  /** 看拼音写字：正面拼音，翻面汉字 + 例词。 */
  PINYIN = 'pinyin'
}

export class ReviewConstants {
  /** 每日目标（本轮固定，不开放设置）。 */
  static readonly DAILY_GOAL: number = 10;
  /** 一次复习会话默认取多少张卡。 */
  static readonly DEFAULT_LIMIT: number = 20;
  /** 单次会话最多多少张卡。 */
  static readonly MAX_LIMIT: number = 50;
  /** 错题本在复习页预览几个字。 */
  static readonly MISTAKE_PREVIEW: number = 5;
  /** 「再来」的卡往后插几张。 */
  static readonly REQUEUE_SPAN: number = 3;
  /** 描红错误次数不超过该值视为通过。 */
  static readonly PASS_MISTAKE_LIMIT: number = 2;
}
