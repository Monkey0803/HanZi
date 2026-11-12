/*
 * HanziDataRepository.ets — 笔顺分片加载。
 *
 * 分片规则与构建脚本一致：shard = charCode % 32。每个分片解析成
 * Map<字, StrokeData>，最多缓存 4 个分片（LRU）。数据缺失返回 undefined，
 * UI 显示「暂无笔顺」并禁用描红。
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PathCommand, Point, StrokeData } from '../model/StrokeModels';
import { SvgPathParser } from './SvgPathParser';
import { dataRootResolver } from './DataRootResolver';
import { TsvUtil } from './TsvUtil';

const SHARD_COUNT: number = 32;
const MAX_CACHED_SHARDS: number = 4;

export class HanziDataRepository {
  private cache: Map<number, Map<string, StrokeData>> = new Map();
  /** LRU 顺序：末尾是最近使用的分片号。 */
  private order: number[] = [];

  /** 取某字的笔顺；缺失返回 undefined。 */
  async get(context: common.Context, char: string): Promise<StrokeData | undefined> {
    if (char.length === 0) {
      return undefined;
    }
    const shard: number = HanziDataRepository.shardOf(char);
    let shardMap: Map<string, StrokeData> | undefined = this.cache.get(shard);
    if (shardMap === undefined) {
      shardMap = await this.loadShard(context, shard);
      this.cache.set(shard, shardMap);
      this.order.push(shard);
      this.trimCache();
    } else {
      this.touch(shard);
    }
    return shardMap.get(char);
  }

  /** 预加载某个字所在分片。 */
  async preload(context: common.Context, char: string): Promise<void> {
    await this.get(context, char);
  }

  clear(): void {
    this.cache.clear();
    this.order = [];
  }

  cachedShardCount(): number {
    return this.cache.size;
  }

  static shardOf(char: string): number {
    const code: number = char.codePointAt(0) ?? 0;
    return code % SHARD_COUNT;
  }

  static shardFileName(index: number): string {
    const suffix: string = index < 10 ? `0${index}` : `${index}`;
    return `strokes/shard-${suffix}.tsv`;
  }

  private async loadShard(context: common.Context, index: number): Promise<Map<string, StrokeData>> {
    const result: Map<string, StrokeData> = new Map();
    try {
      const text: string = await dataRootResolver.readRootText(context, HanziDataRepository.shardFileName(index));
      const rows: string[][] = TsvUtil.rows(text);
      for (let i = 0; i < rows.length; i += 1) {
        const data: StrokeData | undefined = HanziDataRepository.parseRow(rows[i]);
        if (data !== undefined) {
          result.set(data.char, data);
        }
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.warn(`HanziDataRepository.loadShard ${index} failed: ${error.code}`);
    }
    return result;
  }

  private static parseRow(row: string[]): StrokeData | undefined {
    const char: string = TsvUtil.at(row, 0);
    const count: number = TsvUtil.numberAt(row, 1);
    if (char.length === 0 || count <= 0) {
      return undefined;
    }
    const data: StrokeData = new StrokeData();
    data.char = char;
    data.strokeCount = count;
    for (let i = 0; i < count; i += 1) {
      const path: string = TsvUtil.at(row, 2 + i);
      data.paths.push(path);
      const commands: PathCommand[] = SvgPathParser.parse(path);
      data.commands.push(commands);
    }
    const medianText: string = TsvUtil.at(row, 2 + count);
    const medianParts: string[] = medianText.length > 0 ? medianText.split('|') : [];
    for (let i = 0; i < count; i += 1) {
      const raw: string = i < medianParts.length ? medianParts[i] : '';
      data.medians.push(HanziDataRepository.parseMedian(raw));
    }
    return data;
  }

  private static parseMedian(raw: string): Point[] {
    const points: Point[] = [];
    if (raw.length === 0) {
      return points;
    }
    const parts: string[] = raw.split(';');
    for (let i = 0; i < parts.length; i += 1) {
      const pair: string[] = parts[i].split(',');
      if (pair.length < 2) {
        continue;
      }
      const x: number = Number(pair[0]);
      const y: number = Number(pair[1]);
      if (Number.isFinite(x) && Number.isFinite(y)) {
        points.push(new Point(x, y));
      }
    }
    return points;
  }

  private touch(shard: number): void {
    const at: number = this.order.indexOf(shard);
    if (at >= 0) {
      this.order.splice(at, 1);
    }
    this.order.push(shard);
  }

  private trimCache(): void {
    while (this.order.length > MAX_CACHED_SHARDS) {
      const evicted: number | undefined = this.order.shift();
      if (evicted !== undefined) {
        this.cache.delete(evicted);
      }
    }
  }
}

export const hanziDataRepository: HanziDataRepository = new HanziDataRepository();
