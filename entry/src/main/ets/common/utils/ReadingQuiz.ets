/*
 * ReadingQuiz.ets — 「找一找」小测的纯逻辑。
 *
 * 抽成无状态函数便于单测：视图只负责把点击事件传进来并渲染结果。
 */

/** 小测判定结果。 */
export class ReadingQuizResult {
  /** 未开始小测：点击应进入字详情。 */
  static readonly NONE: number = 0;
  static readonly CORRECT: number = 1;
  static readonly RETRY: number = 2;
}

export class ReadingQuiz {
  /** 判定一次点击；target 为空表示当前不在小测中。 */
  static judge(target: string, char: string): number {
    if (target.length === 0) {
      return ReadingQuizResult.NONE;
    }
    return target === char ? ReadingQuizResult.CORRECT : ReadingQuizResult.RETRY;
  }

  /** 按游标轮取下一个小测目标字；候选为空返回空串。 */
  static nextTarget(chars: string[], cursor: number): string {
    if (chars.length === 0) {
      return '';
    }
    const index: number = ((cursor % chars.length) + chars.length) % chars.length;
    return chars[index];
  }
}
