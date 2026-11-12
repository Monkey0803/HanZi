/*
 * TsvUtil.ets — TSV / 分行文本解析。
 *
 * 数据文件在构建期由 tools/ 生成，格式固定：'#' 开头是注释，首行可能是表头。
 * 解析时逐字段 trim，但保留空字段（many rows 以空拼音结尾）。
 */

export class TsvUtil {
  /** 把文本切成字段数组；跳过空行、注释行与已知表头。 */
  static rows(text: string): string[][] {
    const result: string[][] = [];
    const lines: string[] = text.split('\n');
    for (let i = 0; i < lines.length; i += 1) {
      const raw: string = lines[i];
      const line: string = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      if (line.length === 0 || line.startsWith('#')) {
        continue;
      }
      const fields: string[] = line.split('\t');
      for (let j = 0; j < fields.length; j += 1) {
        fields[j] = fields[j].trim();
      }
      const first: string = fields[0];
      if (first.length === 0 || first === 'id' || first === 'lessonId' || first === 'char') {
        continue;
      }
      result.push(fields);
    }
    return result;
  }

  /** 安全取字段。 */
  static at(fields: string[], index: number): string {
    return index >= 0 && index < fields.length ? fields[index] : '';
  }

  /** 安全取数字字段。 */
  static numberAt(fields: string[], index: number): number {
    const value: number = Number(TsvUtil.at(fields, index));
    return Number.isFinite(value) ? value : 0;
  }

  /** 按 ';' 拆成非空数组。 */
  static splitList(value: string, separator: string): string[] {
    const result: string[] = [];
    if (value.length === 0) {
      return result;
    }
    const parts: string[] = value.split(separator);
    for (let i = 0; i < parts.length; i += 1) {
      const part: string = parts[i].trim();
      if (part.length > 0) {
        result.push(part);
      }
    }
    return result;
  }
}
