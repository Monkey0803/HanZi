/*
 * StrokeModels.ets — 笔顺数据与描红判分模型。
 *
 * makemeahanzi 坐标：1024×1024，y 轴向上。Point 保存原始数据坐标，
 * 转屏幕坐标由渲染层负责。
 */

/** 数据坐标点。 */
export class Point {
  x: number = 0;
  y: number = 0;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }
}

/** SVG 路径归一化后的命令种类。 */
export enum PathOp {
  MOVE = 0,
  LINE = 1,
  QUAD = 2,
  CUBIC = 3,
  CLOSE = 4
}

/** 一条路径命令；values 按 op 解释：MOVE/LINE=[x,y]，QUAD=[cx,cy,x,y]，CUBIC=[cx1,cy1,cx2,cy2,x,y]，CLOSE=[]。 */
export class PathCommand {
  op: PathOp = PathOp.MOVE;
  values: number[] = [];

  constructor(op: PathOp = PathOp.MOVE, values: number[] = []) {
    this.op = op;
    this.values = values;
  }
}

/** 单个字的笔顺数据。 */
export class StrokeData {
  char: string = '';
  strokeCount: number = 0;
  /** 每笔的 SVG 路径原文。 */
  paths: string[] = [];
  /** 每笔的骨架中线（书写轨迹）。 */
  medians: Point[][] = [];
  /** 每笔解析后的命令流；由 SvgPathParser 填充。 */
  commands: PathCommand[][] = [];
}

/** 描红判分阈值（数据坐标，1024 基准）。 */
export class StrokeMatcherOptions {
  maxStartDistance: number = 220;
  maxEndDistance: number = 260;
  minLengthRatio: number = 0.4;
  maxLengthRatio: number = 1.8;
  maxAverageDistance: number = 200;
  minDirectionCosine: number = 0.15;
  /** 标准笔顺过短时跳过方向判断。 */
  minDirectionLength: number = 80;
}

/** 一次描红判分结果。 */
export class StrokeMatchResult {
  passed: boolean = false;
  startDistance: number = 0;
  endDistance: number = 0;
  lengthRatio: number = 0;
  averageDistance: number = 0;
  directionCosine: number = 0;
  reason: string = '';
}

/** 画布配色（父组件按主题注入）。 */
export class StrokeTheme {
  ink: string = '#1F1F1F';
  grid: string = '#D8D8D8';
  outline: string = '#DDE3EA';
  active: string = '#0A59F7';
  error: string = '#E84026';
  success: string = '#64BB5C';
  /** 运笔骨架中线。 */
  skeleton: string = '#C04A1E';
  /** 当前笔的骨架高亮。 */
  skeletonActive: string = '#0A59F7';
  /** 序号徽标底色。 */
  numberBg: string = '#FFFFFF';
  /** 序号徽标描边。 */
  numberBorder: string = '#BFBFBF';
  /** 序号文字。 */
  numberText: string = '#1F1F1F';
  /** 当前笔序号底色。 */
  numberActiveBg: string = '#0A59F7';
  /** 当前笔序号文字。 */
  numberActiveText: string = '#FFFFFF';
}
