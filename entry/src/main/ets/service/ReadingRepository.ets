/*
 * ReadingRepository.ets — 识字短文仓库（可选数据）。
 *
 * passages.tsv 是增强数据：不存在（旧 full/seed 数据）或解析失败时回退为空列表，
 * 不阻塞启动；页面据此隐藏阅读区。
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Passage } from '../model/ReadingModels';
import { dataRootResolver } from './DataRootResolver';
import { TsvUtil } from './TsvUtil';

const PASSAGES_RELATIVE: string = 'curriculum/passages.tsv';

export class ReadingRepository {
  private loaded: boolean = false;
  private total: number = 0;
  private byLesson: Map<string, Passage[]> = new Map();

  /** 读取当前数据根下的 passages.tsv；重复调用直接返回。 */
  async load(context: common.Context): Promise<void> {
    if (this.loaded) {
      return;
    }
    this.loaded = true;
    const root: string = dataRootResolver.currentRoot();
    if (root.length === 0) {
      return;
    }
    try {
      const exists: boolean = await dataRootResolver.exists(context, `${root}/${PASSAGES_RELATIVE}`);
      if (!exists) {
        return;
      }
      const text: string = await dataRootResolver.readRootText(context, PASSAGES_RELATIVE);
      this.parse(text);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`ReadingRepository.load failed: ${error.code} ${error.message}`);
    }
  }

  isLoaded(): boolean {
    return this.loaded;
  }

  /** 数据库里是否有短文（用于隐藏整个阅读区）。 */
  hasData(): boolean {
    return this.total > 0;
  }

  count(): number {
    return this.total;
  }

  passagesOfLesson(lessonId: string): Passage[] {
    return this.byLesson.get(lessonId) ?? [];
  }

  private parse(text: string): void {
    const rows: string[][] = TsvUtil.rows(text);
    for (let i = 0; i < rows.length; i += 1) {
      const row: string[] = rows[i];
      // TsvUtil 不认识 passageId 表头，这里手动跳过。
      if (TsvUtil.at(row, 0) === 'passageId') {
        continue;
      }
      const passage: Passage = new Passage();
      passage.id = TsvUtil.at(row, 0);
      passage.lessonId = TsvUtil.at(row, 1);
      passage.order = TsvUtil.numberAt(row, 2);
      passage.title = TsvUtil.at(row, 3);
      passage.text = TsvUtil.at(row, 4);
      passage.overrides = this.parseOverrides(TsvUtil.at(row, 5));
      if (passage.id.length === 0 || passage.lessonId.length === 0 || passage.text.length === 0) {
        continue;
      }
      const list: Passage[] = this.byLesson.get(passage.lessonId) ?? [];
      list.push(passage);
      this.byLesson.set(passage.lessonId, list);
      this.total += 1;
    }
    this.byLesson.forEach((list: Passage[]) => {
      list.sort((a: Passage, b: Passage) => a.order - b.order);
    });
  }

  /** '地:dì;人:rén' → Map。 */
  private parseOverrides(value: string): Map<string, string> {
    const result: Map<string, string> = new Map();
    const parts: string[] = TsvUtil.splitList(value, ';');
    for (let i = 0; i < parts.length; i += 1) {
      const pair: string[] = parts[i].split(':');
      if (pair.length < 2) {
        continue;
      }
      const char: string = pair[0].trim();
      const pinyin: string = pair[1].trim();
      if (char.length > 0 && pinyin.length > 0) {
        result.set(char, pinyin);
      }
    }
    return result;
  }
}

export const readingRepository: ReadingRepository = new ReadingRepository();
