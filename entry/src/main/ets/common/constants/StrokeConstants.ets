/*
 * StrokeConstants.ets — 笔顺显示与字表筛选的纯逻辑常量。
 *
 * 只放枚举与 Canvas 几何参数；UI 尺寸仍走 resources/base/element/float.json。
 */

/** 字格样式：田字格 / 米字格 / 九宫格 / 无格。 */
export enum GridStyleId {
  TIAN = 'tian',
  MI = 'mi',
  NINE = 'nine',
  NONE = 'none'
}

/** 字表范围：全部 / 教材字 / 通用字。 */
export enum CatalogScope {
  ALL = 'all',
  CURRICULUM = 'curriculum',
  COMMON = 'common'
}

/** 字表笔画数分段。 */
export enum StrokeBand {
  ALL = 'all',
  B1 = '1-4',
  B2 = '5-8',
  B3 = '9-12',
  B4 = '13+'
}

/** 序号徽标最小半径（vp）。 */
export const NUMBER_MIN_RADIUS: number = 7;
/** 序号徽标最大半径（vp）。 */
export const NUMBER_MAX_RADIUS: number = 12;
/** 半径随画布尺寸的比例。 */
export const NUMBER_RADIUS_RATIO: number = 0.032;
/** 序号字号相对徽标半径的比例（字号 = 半径 × 该值）。 */
export const NUMBER_FONT_RATIO: number = 1.45;
/** 序号沿书写方向内移的半径倍数，避免压住起笔。 */
export const NUMBER_OFFSET_RATIO: number = 1.15;
/** 画布过小时不画序号（vp）。 */
export const NUMBER_MIN_CANVAS_VP: number = 200;
/** 求方向时的最小累计长度（数据坐标，1024 基准）。 */
export const NUMBER_DIRECTION_MIN_LENGTH: number = 40;
/** 骨架线宽（vp）。 */
export const SKELETON_LINE_VP: number = 2.5;
/** 骨架方向箭头线长（vp）。 */
export const ARROW_LENGTH_VP: number = 9;
/** 骨架箭头落在 median 的长度比例。 */
export const ARROW_POSITION_RATIO: number = 0.8;
/** 骨架模式下轮廓透明度。 */
export const SKELETON_OUTLINE_ALPHA: number = 0.2;
/** 步骤条单元格宽度（vp，Canvas 几何）。 */
export const STEPS_CELL_WIDTH: number = 48;
/** 步骤条高度（vp，Canvas 几何）。 */
export const STEPS_HEIGHT: number = 64;
/** 步骤条单元格内边距（vp）。 */
export const STEPS_CELL_PADDING: number = 4;
/** 步骤条序号字号（vp）。 */
export const STEPS_NUMBER_FONT_SIZE: number = 11;
