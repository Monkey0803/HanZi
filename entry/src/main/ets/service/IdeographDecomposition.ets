/*
 * IdeographDecomposition.ets — 字形结构（IDS）解析。
 *
 * makemeahanzi 的 decomposition 形如 "⿰扌丁" / "⿱日十"，首字符是表意描述符。
 * 这里只做「顶层结构 + 部件字符」的轻量解析，不做完整 IDS 语法树还原。
 */

/** 汉字结构类型。 */
export enum StructureKind {
  UNKNOWN = 'unknown',
  LEFT_RIGHT = 'lr',
  TOP_BOTTOM = 'tb',
  LEFT_MIDDLE_RIGHT = 'lcr',
  TOP_MIDDLE_BOTTOM = 'tcb',
  SURROUND = 'surround',
  SEMI_SURROUND = 'semi',
  OVERLAY = 'overlay'
}

/** 解析结果：结构类型 + 直接部件。 */
export class DecompositionInfo {
  kind: StructureKind = StructureKind.UNKNOWN;
  components: string[] = [];

  constructor(kind: StructureKind = StructureKind.UNKNOWN, components: string[] = []) {
    this.kind = kind;
    this.components = components;
  }
}

const SURROUND_OPERATOR: string = '⿴';
const UNKNOWN_OPERATOR: string = '？';

export class IdeographDecomposition {
  /** 表意描述符（结构符号）判断。 */
  static isOperator(ch: string): boolean {
    return ch >= '\u2FF0' && ch <= '\u2FFF';
  }

  /** 顶层结构类型。 */
  static kindOf(raw: string): StructureKind {
    if (raw.length === 0) {
      return StructureKind.UNKNOWN;
    }
    const operator: string = raw.charAt(0);
    if (operator === '⿰') {
      return StructureKind.LEFT_RIGHT;
    }
    if (operator === '⿱') {
      return StructureKind.TOP_BOTTOM;
    }
    if (operator === '⿲') {
      return StructureKind.LEFT_MIDDLE_RIGHT;
    }
    if (operator === '⿳') {
      return StructureKind.TOP_MIDDLE_BOTTOM;
    }
    if (operator === SURROUND_OPERATOR) {
      return StructureKind.SURROUND;
    }
    if (operator >= '\u2FF5' && operator <= '\u2FFA') {
      return StructureKind.SEMI_SURROUND;
    }
    if (operator === '⿻') {
      return StructureKind.OVERLAY;
    }
    return StructureKind.UNKNOWN;
  }

  /** 直接部件：去掉结构符号与「未知」占位，保持原顺序、去重。 */
  static componentsOf(raw: string): string[] {
    const result: string[] = [];
    for (let i = 0; i < raw.length; i += 1) {
      const ch: string = raw.charAt(i);
      if (IdeographDecomposition.isOperator(ch) || ch === UNKNOWN_OPERATOR) {
        continue;
      }
      if (result.indexOf(ch) < 0) {
        result.push(ch);
      }
    }
    return result;
  }

  /** 一次性解析。 */
  static parse(raw: string): DecompositionInfo {
    return new DecompositionInfo(IdeographDecomposition.kindOf(raw), IdeographDecomposition.componentsOf(raw));
  }
}
