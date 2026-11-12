/*
 * SvgPathParser.ets — SVG path 归一化解析。
 *
 * 支持 M/L/H/V/C/S/Q/T/A/Z 及其相对形式与隐式重复；弧线转成三次贝塞尔。
 * 输出只包含 MOVE / LINE / QUAD / CUBIC / CLOSE 五种命令，供 Canvas 逐帧重放。
 */

import { PathCommand, PathOp } from '../model/StrokeModels';

/** 词法单元：命令字母或数字。 */
class PathToken {
  isCommand: boolean = false;
  command: string = '';
  value: number = 0;

  constructor(isCommand: boolean = false, command: string = '', value: number = 0) {
    this.isCommand = isCommand;
    this.command = command;
    this.value = value;
  }
}

/** 解析过程中的游标状态。 */
class PathState {
  cx: number = 0;
  cy: number = 0;
  sx: number = 0;
  sy: number = 0;
  lastCtrlX: number = 0;
  lastCtrlY: number = 0;
  /** 0 = 无，1 = 三次，2 = 二次。 */
  lastCtrlKind: number = 0;
  firstSet: boolean = true;
}

export class SvgPathParser {
  /** 解析一条 SVG path。 */
  static parse(path: string): PathCommand[] {
    const tokens: PathToken[] = SvgPathParser.tokenize(path);
    const commands: PathCommand[] = [];
    const state: PathState = new PathState();
    let index: number = 0;
    let current: string = '';
    while (index < tokens.length) {
      if (tokens[index].isCommand) {
        current = tokens[index].command;
        index += 1;
        state.firstSet = true;
        if (current === 'Z' || current === 'z') {
          commands.push(new PathCommand(PathOp.CLOSE, []));
          state.cx = state.sx;
          state.cy = state.sy;
          state.lastCtrlKind = 0;
          continue;
        }
      } else if (current.length === 0) {
        index += 1;
        continue;
      }
      const upper: string = current.toUpperCase();
      const relative: boolean = current !== upper;
      const consumed: number = SvgPathParser.consume(upper, relative, tokens, index, state, commands);
      if (consumed <= 0) {
        break;
      }
      index += consumed;
      state.firstSet = false;
    }
    return commands;
  }

  private static tokenize(path: string): PathToken[] {
    const tokens: PathToken[] = [];
    const length: number = path.length;
    let index: number = 0;
    while (index < length) {
      const ch: string = path.charAt(index);
      if (SvgPathParser.isSeparator(ch)) {
        index += 1;
        continue;
      }
      if (SvgPathParser.isCommandLetter(ch)) {
        tokens.push(new PathToken(true, ch, 0));
        index += 1;
        continue;
      }
      const start: number = index;
      if (ch === '+' || ch === '-') {
        index += 1;
      }
      let dots: number = 0;
      while (index < length) {
        const c: string = path.charAt(index);
        if (c >= '0' && c <= '9') {
          index += 1;
        } else if (c === '.' && dots === 0) {
          dots += 1;
          index += 1;
        } else {
          break;
        }
      }
      if (index < length) {
        const e: string = path.charAt(index);
        if (e === 'e' || e === 'E') {
          const look: number = index + 1;
          const sign: string = look < length ? path.charAt(look) : '';
          const afterSign: number = sign === '+' || sign === '-' ? look + 1 : look;
          const digit: string = afterSign < length ? path.charAt(afterSign) : '';
          if (digit >= '0' && digit <= '9') {
            index = afterSign;
            while (index < length) {
              const d: string = path.charAt(index);
              if (d >= '0' && d <= '9') {
                index += 1;
              } else {
                break;
              }
            }
          }
        }
      }
      const value: number = Number(path.substring(start, index));
      if (Number.isFinite(value)) {
        tokens.push(new PathToken(false, '', value));
      } else if (index === start) {
        index += 1;
      }
    }
    return tokens;
  }

  private static isSeparator(ch: string): boolean {
    return ch === ' ' || ch === ',' || ch === '\n' || ch === '\r' || ch === '\t';
  }

  private static isCommandLetter(ch: string): boolean {
    return 'MmLlHhVvCcSsQqTtAaZz'.indexOf(ch) >= 0;
  }

  /** 消费一组参数；返回消费的 token 数，0 表示参数不足。 */
  private static consume(upper: string, relative: boolean, tokens: PathToken[], index: number,
    state: PathState, commands: PathCommand[]): number {
    if (upper === 'M' || upper === 'L' || upper === 'T') {
      if (index + 1 >= tokens.length) {
        return 0;
      }
      const x: number = SvgPathParser.absolute(tokens[index].value, state.cx, relative);
      const y: number = SvgPathParser.absolute(tokens[index + 1].value, state.cy, relative);
      if (upper === 'M' && state.firstSet) {
        commands.push(new PathCommand(PathOp.MOVE, [x, y]));
        state.sx = x;
        state.sy = y;
      } else if (upper === 'T') {
        const ctrlX: number = state.lastCtrlKind === 2 ? 2 * state.cx - state.lastCtrlX : state.cx;
        const ctrlY: number = state.lastCtrlKind === 2 ? 2 * state.cy - state.lastCtrlY : state.cy;
        commands.push(new PathCommand(PathOp.QUAD, [ctrlX, ctrlY, x, y]));
        state.lastCtrlX = ctrlX;
        state.lastCtrlY = ctrlY;
        state.lastCtrlKind = 2;
      } else {
        commands.push(new PathCommand(PathOp.LINE, [x, y]));
      }
      state.cx = x;
      state.cy = y;
      if (upper !== 'T') {
        state.lastCtrlKind = 0;
      }
      return 2;
    }
    if (upper === 'H') {
      if (index >= tokens.length) {
        return 0;
      }
      const x: number = SvgPathParser.absolute(tokens[index].value, state.cx, relative);
      commands.push(new PathCommand(PathOp.LINE, [x, state.cy]));
      state.cx = x;
      state.lastCtrlKind = 0;
      return 1;
    }
    if (upper === 'V') {
      if (index >= tokens.length) {
        return 0;
      }
      const y: number = SvgPathParser.absolute(tokens[index].value, state.cy, relative);
      commands.push(new PathCommand(PathOp.LINE, [state.cx, y]));
      state.cy = y;
      state.lastCtrlKind = 0;
      return 1;
    }
    if (upper === 'C') {
      if (index + 5 >= tokens.length) {
        return 0;
      }
      const c1x: number = SvgPathParser.absolute(tokens[index].value, state.cx, relative);
      const c1y: number = SvgPathParser.absolute(tokens[index + 1].value, state.cy, relative);
      const c2x: number = SvgPathParser.absolute(tokens[index + 2].value, state.cx, relative);
      const c2y: number = SvgPathParser.absolute(tokens[index + 3].value, state.cy, relative);
      const x: number = SvgPathParser.absolute(tokens[index + 4].value, state.cx, relative);
      const y: number = SvgPathParser.absolute(tokens[index + 5].value, state.cy, relative);
      commands.push(new PathCommand(PathOp.CUBIC, [c1x, c1y, c2x, c2y, x, y]));
      state.lastCtrlX = c2x;
      state.lastCtrlY = c2y;
      state.lastCtrlKind = 1;
      state.cx = x;
      state.cy = y;
      return 6;
    }
    if (upper === 'S') {
      if (index + 3 >= tokens.length) {
        return 0;
      }
      const c1x: number = state.lastCtrlKind === 1 ? 2 * state.cx - state.lastCtrlX : state.cx;
      const c1y: number = state.lastCtrlKind === 1 ? 2 * state.cy - state.lastCtrlY : state.cy;
      const c2x: number = SvgPathParser.absolute(tokens[index].value, state.cx, relative);
      const c2y: number = SvgPathParser.absolute(tokens[index + 1].value, state.cy, relative);
      const x: number = SvgPathParser.absolute(tokens[index + 2].value, state.cx, relative);
      const y: number = SvgPathParser.absolute(tokens[index + 3].value, state.cy, relative);
      commands.push(new PathCommand(PathOp.CUBIC, [c1x, c1y, c2x, c2y, x, y]));
      state.lastCtrlX = c2x;
      state.lastCtrlY = c2y;
      state.lastCtrlKind = 1;
      state.cx = x;
      state.cy = y;
      return 4;
    }
    if (upper === 'Q') {
      if (index + 3 >= tokens.length) {
        return 0;
      }
      const ctrlX: number = SvgPathParser.absolute(tokens[index].value, state.cx, relative);
      const ctrlY: number = SvgPathParser.absolute(tokens[index + 1].value, state.cy, relative);
      const x: number = SvgPathParser.absolute(tokens[index + 2].value, state.cx, relative);
      const y: number = SvgPathParser.absolute(tokens[index + 3].value, state.cy, relative);
      commands.push(new PathCommand(PathOp.QUAD, [ctrlX, ctrlY, x, y]));
      state.lastCtrlX = ctrlX;
      state.lastCtrlY = ctrlY;
      state.lastCtrlKind = 2;
      state.cx = x;
      state.cy = y;
      return 4;
    }
    if (upper === 'A') {
      if (index + 6 >= tokens.length) {
        return 0;
      }
      const rx: number = Math.abs(tokens[index].value);
      const ry: number = Math.abs(tokens[index + 1].value);
      const rotation: number = tokens[index + 2].value;
      const largeArc: boolean = tokens[index + 3].value !== 0;
      const sweep: boolean = tokens[index + 4].value !== 0;
      const x: number = SvgPathParser.absolute(tokens[index + 5].value, state.cx, relative);
      const y: number = SvgPathParser.absolute(tokens[index + 6].value, state.cy, relative);
      SvgPathParser.arcToCubics(state.cx, state.cy, rx, ry, rotation, largeArc, sweep, x, y, commands);
      state.cx = x;
      state.cy = y;
      state.lastCtrlKind = 0;
      return 7;
    }
    return 0;
  }

  private static absolute(value: number, origin: number, relative: boolean): number {
    return relative ? origin + value : value;
  }

  /** 端点参数化的椭圆弧 → 若干三次贝塞尔。 */
  private static arcToCubics(x1: number, y1: number, rx: number, ry: number, rotationDeg: number,
    largeArc: boolean, sweep: boolean, x2: number, y2: number, out: PathCommand[]): void {
    if (rx === 0 || ry === 0) {
      out.push(new PathCommand(PathOp.LINE, [x2, y2]));
      return;
    }
    const phi: number = rotationDeg * Math.PI / 180;
    const cosPhi: number = Math.cos(phi);
    const sinPhi: number = Math.sin(phi);
    const dx2: number = (x1 - x2) / 2;
    const dy2: number = (y1 - y2) / 2;
    const x1p: number = cosPhi * dx2 + sinPhi * dy2;
    const y1p: number = -sinPhi * dx2 + cosPhi * dy2;

    let radiusX: number = rx;
    let radiusY: number = ry;
    const lambda: number = (x1p * x1p) / (radiusX * radiusX) + (y1p * y1p) / (radiusY * radiusY);
    if (lambda > 1) {
      const scale: number = Math.sqrt(lambda);
      radiusX *= scale;
      radiusY *= scale;
    }

    const rx2: number = radiusX * radiusX;
    const ry2: number = radiusY * radiusY;
    const numerator: number = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p;
    const denominator: number = rx2 * y1p * y1p + ry2 * x1p * x1p;
    let factor: number = denominator === 0 ? 0 : Math.sqrt(Math.max(0, numerator / denominator));
    if (largeArc === sweep) {
      factor = -factor;
    }
    const cxp: number = factor * (radiusX * y1p / radiusY);
    const cyp: number = factor * (-radiusY * x1p / radiusX);
    const centerX: number = cosPhi * cxp - sinPhi * cyp + (x1 + x2) / 2;
    const centerY: number = sinPhi * cxp + cosPhi * cyp + (y1 + y2) / 2;

    const theta1: number = SvgPathParser.vectorAngle(1, 0,
      (x1p - cxp) / radiusX, (y1p - cyp) / radiusY);
    let delta: number = SvgPathParser.vectorAngle(
      (x1p - cxp) / radiusX, (y1p - cyp) / radiusY,
      (-x1p - cxp) / radiusX, (-y1p - cyp) / radiusY);
    if (!sweep && delta > 0) {
      delta -= Math.PI * 2;
    } else if (sweep && delta < 0) {
      delta += Math.PI * 2;
    }

    const segments: number = Math.max(1, Math.ceil(Math.abs(delta) / (Math.PI / 2)));
    const step: number = delta / segments;
    const alpha: number = 4 / 3 * Math.tan(step / 4);
    let theta: number = theta1;
    for (let i = 0; i < segments; i += 1) {
      const nextTheta: number = theta + step;
      const cos1: number = Math.cos(theta);
      const sin1: number = Math.sin(theta);
      const cos2: number = Math.cos(nextTheta);
      const sin2: number = Math.sin(nextTheta);
      const p1x: number = cosPhi * radiusX * cos1 - sinPhi * radiusY * sin1 + centerX;
      const p1y: number = sinPhi * radiusX * cos1 + cosPhi * radiusY * sin1 + centerY;
      const p2x: number = cosPhi * radiusX * cos2 - sinPhi * radiusY * sin2 + centerX;
      const p2y: number = sinPhi * radiusX * cos2 + cosPhi * radiusY * sin2 + centerY;
      const d1x: number = cosPhi * (-radiusX * sin1) - sinPhi * (radiusY * cos1);
      const d1y: number = sinPhi * (-radiusX * sin1) + cosPhi * (radiusY * cos1);
      const d2x: number = cosPhi * (-radiusX * sin2) - sinPhi * (radiusY * cos2);
      const d2y: number = sinPhi * (-radiusX * sin2) + cosPhi * (radiusY * cos2);
      out.push(new PathCommand(PathOp.CUBIC, [
        p1x + alpha * d1x,
        p1y + alpha * d1y,
        p2x - alpha * d2x,
        p2y - alpha * d2y,
        p2x,
        p2y
      ]));
      theta = nextTheta;
    }
  }

  private static vectorAngle(ux: number, uy: number, vx: number, vy: number): number {
    const dot: number = ux * vx + uy * vy;
    const length: number = Math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    if (length === 0) {
      return 0;
    }
    let cosine: number = dot / length;
    if (cosine > 1) {
      cosine = 1;
    } else if (cosine < -1) {
      cosine = -1;
    }
    const sign: number = ux * vy - uy * vx < 0 ? -1 : 1;
    return sign * Math.acos(cosine);
  }
}
