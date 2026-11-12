/*
 * ReadingTextBuilder.ets — 短文文本 → 逐字 glyph（纯函数，可单测）。
 *
 * 不依赖 Context / 仓库，输入读音表即可；这样单测不需要设备与业务数据。
 */

import { PassageGlyph } from '../model/ReadingModels';

export class ReadingTextBuilder {
  /** 汉字判定：与 tools 生成脚本保持一致（CJK 基本区）。 */
  static isHan(char: string): boolean {
    const code: number = char.codePointAt(0) ?? 0;
    return code >= 0x4e00 && code <= 0x9fff;
  }

  /**
   * 逐字构建渲染单元。
   *
   * 读音优先级：overrides（按篇纠偏）→ focusPinyin（本课读音）→ allPinyin（字典首读音）。
   * 标点/数字保留为不可点 glyph；空格直接丢弃。
   */
  static build(text: string, focusPinyin: Map<string, string>, allPinyin: Map<string, string>,
    overrides: Map<string, string>): PassageGlyph[] {
    const result: PassageGlyph[] = [];
    const chars: string[] = Array.from(text);
    for (let i = 0; i < chars.length; i += 1) {
      const char: string = chars[i];
      if (char.length === 0 || char === ' ' || char === '\t' || char === '\n' || char === '\u3000') {
        continue;
      }
      const glyph: PassageGlyph = new PassageGlyph();
      glyph.char = char;
      glyph.isHan = ReadingTextBuilder.isHan(char);
      if (glyph.isHan) {
        const override: string | undefined = overrides.get(char);
        if (override !== undefined && override.length > 0) {
          glyph.pinyin = override;
        } else if (focusPinyin.has(char)) {
          glyph.pinyin = focusPinyin.get(char) ?? '';
        } else {
          glyph.pinyin = allPinyin.get(char) ?? '';
        }
        glyph.isFocus = focusPinyin.has(char);
      }
      result.push(glyph);
    }
    return result;
  }
}
