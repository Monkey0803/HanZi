/*
 * PinyinUtils.ets — 拼音归一化与查询匹配。
 *
 * 数据里的拼音带声调（nǐ / lǜ）；查字时用户只会输入无声调的 a-z，
 * 这里统一把声调母音折叠为基本字母，并把 ü 统一成 v。
 */

const TONE_MAP: Record<string, string> = {
  'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
  'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
  'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
  'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
  'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
  'ǖ': 'v', 'ǘ': 'v', 'ǚ': 'v', 'ǜ': 'v', 'ü': 'v'
};

export class PinyinUtils {
  /** 去声调、小写、去空白；ü 折叠为 v。 */
  static normalize(input: string): string {
    const lower: string = input.trim().toLowerCase();
    let result: string = '';
    for (let i = 0; i < lower.length; i += 1) {
      const ch: string = lower.charAt(i);
      const mapped: string | undefined = TONE_MAP[ch];
      result += mapped !== undefined ? mapped : ch;
    }
    return result;
  }

  /** 该字的任一读音是否以 query 开头（适合逐字母输入）。 */
  static matches(pinyins: string[], query: string): boolean {
    const normalizedQuery: string = PinyinUtils.normalize(query);
    if (normalizedQuery.length === 0) {
      return true;
    }
    for (let i = 0; i < pinyins.length; i += 1) {
      if (PinyinUtils.normalize(pinyins[i]).startsWith(normalizedQuery)) {
        return true;
      }
    }
    return false;
  }

  /** 读音排序键：无声调拼写，便于按字母序稳定排列。 */
  static sortKey(pinyin: string): string {
    return PinyinUtils.normalize(pinyin);
  }
}
