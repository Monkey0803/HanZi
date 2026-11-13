/*
 * CharacterCatalogService.ets — 字表查询的业务入口。
 *
 * 视图只拿到已排序的结果与统计；过滤口径（scope/band/radical/query）全部由这里
 * 转成仓库查询参数，仓库保持纯数据职责。
 */

import { ChoiceOption, ChoiceSet } from '../model/SettingsOptions';
import { CharacterEntry } from '../model/CurriculumModels';
import { CurriculumRepository, curriculumRepository } from './CurriculumRepository';
import { CatalogScope, StrokeBand } from '../common/constants/StrokeConstants';
import { CatalogBrowseMode, CatalogGroup } from '../model/CatalogModels';
import { PinyinUtils } from './PinyinUtils';

const OTHER_GROUP_KEY: string = '#';

function firstPinyin(entry: CharacterEntry): string {
  return entry.pinyins.length > 0 ? entry.pinyins[0] : '';
}

function pinyinGroupKey(entry: CharacterEntry): string {
  const normalized: string = PinyinUtils.sortKey(firstPinyin(entry));
  if (normalized.length === 0) {
    return OTHER_GROUP_KEY;
  }
  const first: string = normalized.charAt(0).toUpperCase();
  return first >= 'A' && first <= 'Z' ? first : OTHER_GROUP_KEY;
}

function groupKey(entry: CharacterEntry, mode: CatalogBrowseMode): string {
  if (mode === CatalogBrowseMode.PINYIN) {
    return pinyinGroupKey(entry);
  }
  if (mode === CatalogBrowseMode.STROKE) {
    return entry.strokeCount > 0 ? entry.strokeCount.toString() : OTHER_GROUP_KEY;
  }
  const radical: string = entry.radical.trim();
  return radical.length > 0 ? radical : OTHER_GROUP_KEY;
}

function compareGroupKeys(left: string, right: string, mode: CatalogBrowseMode): number {
  if (left === OTHER_GROUP_KEY) {
    return right === OTHER_GROUP_KEY ? 0 : 1;
  }
  if (right === OTHER_GROUP_KEY) {
    return -1;
  }
  if (mode === CatalogBrowseMode.STROKE) {
    return Number(left) - Number(right);
  }
  return left.localeCompare(right);
}

function compareEntries(left: CharacterEntry, right: CharacterEntry, mode: CatalogBrowseMode): number {
  if (mode === CatalogBrowseMode.PINYIN) {
    const pinyinOrder: number = PinyinUtils.sortKey(firstPinyin(left))
      .localeCompare(PinyinUtils.sortKey(firstPinyin(right)));
    if (pinyinOrder !== 0) {
      return pinyinOrder;
    }
  } else if (mode === CatalogBrowseMode.RADICAL && left.strokeCount !== right.strokeCount) {
    return left.strokeCount - right.strokeCount;
  }
  return left.char.localeCompare(right.char);
}

/** 一次查询的完整条件。 */
export class CatalogQuery {
  query: string = '';
  scope: string = CatalogScope.ALL;
  band: string = StrokeBand.ALL;
  radical: string = '';

  constructor(query: string = '', scope: string = CatalogScope.ALL, band: string = StrokeBand.ALL,
    radical: string = '') {
    this.query = query;
    this.scope = scope;
    this.band = band;
    this.radical = radical;
  }
}

export class CharacterCatalogService {
  /** 查询结果（已排序、已限量）。 */
  static results(condition: CatalogQuery, limit: number = 0): CharacterEntry[] {
    const repo: CurriculumRepository = curriculumRepository;
    return repo.searchCatalog(condition.query, condition.scope, condition.band, condition.radical, limit);
  }

  /** 当前条件下的命中总数。 */
  static count(condition: CatalogQuery): number {
    return CharacterCatalogService.results(condition, 0).length;
  }

  /** 按指定浏览维度生成稳定分组，同时预切手机 / 宽屏网格行。 */
  static groups(condition: CatalogQuery, mode: CatalogBrowseMode): CatalogGroup[] {
    return CharacterCatalogService.groupEntries(CharacterCatalogService.results(condition, 0), mode);
  }

  /** 纯分组函数：便于对排序、缺失字段和行切分做单元测试。 */
  static groupEntries(entries: CharacterEntry[], mode: CatalogBrowseMode): CatalogGroup[] {
    const buckets: Map<string, CharacterEntry[]> = new Map<string, CharacterEntry[]>();
    for (let i = 0; i < entries.length; i += 1) {
      const key: string = groupKey(entries[i], mode);
      const bucket: CharacterEntry[] | undefined = buckets.get(key);
      if (bucket === undefined) {
        buckets.set(key, [entries[i]]);
      } else {
        bucket.push(entries[i]);
      }
    }
    const keys: string[] = [];
    buckets.forEach((_entries: CharacterEntry[], key: string) => {
      keys.push(key);
    });
    keys.sort((left: string, right: string) => compareGroupKeys(left, right, mode));

    const groups: CatalogGroup[] = [];
    for (let i = 0; i < keys.length; i += 1) {
      const bucket: CharacterEntry[] | undefined = buckets.get(keys[i]);
      if (bucket !== undefined) {
        bucket.sort((left: CharacterEntry, right: CharacterEntry) => compareEntries(left, right, mode));
        groups.push(new CatalogGroup(keys[i], bucket, i));
      }
    }
    return groups;
  }

  /** 部首下拉表：首项「全部」+ 数据里出现过的部首。 */
  static radicalOptions(current: string): ChoiceSet {
    const options: ChoiceOption[] = [new ChoiceOption('', $r('app.string.catalog_radical_all'))];
    const radicals: string[] = curriculumRepository.catalogRadicals();
    for (let i = 0; i < radicals.length; i += 1) {
      options.push(new ChoiceOption(radicals[i], radicals[i]));
    }
    return new ChoiceSet(options, '');
  }

  /** 当前数据是否只含演示字表（seed）。 */
  static isLimitedData(): boolean {
    return curriculumRepository.meta('dataMode', 'seed') !== 'full';
  }

  /** 结果计数文案。 */
  static countLabel(count: number): ResourceStr {
    return $r('app.string.catalog_result_count', count);
  }
}
