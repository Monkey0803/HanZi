/*
 * 自动阅读练习的纯文本组合规则。
 *
 * 上游负责筛选“已学字范围内且包含本课生字”的教材词语；这里再做最后一道
 * 长度与去重防线。合规词语不足两个时宁可不生成，也不回退到生字机械拼接。
 */

export const MAX_PRACTICE_WORDS = 6;

export function composeWordPractice(candidates) {
  const words = [];
  const seen = new Set();
  for (const candidate of candidates) {
    const word = String(candidate ?? '').trim();
    const length = Array.from(word).length;
    if (length < 2 || length > 4 || seen.has(word)) continue;
    seen.add(word);
    words.push(word);
    if (words.length >= MAX_PRACTICE_WORDS) break;
  }
  return words.length >= 2 ? `${words.join('、')}。` : '';
}
