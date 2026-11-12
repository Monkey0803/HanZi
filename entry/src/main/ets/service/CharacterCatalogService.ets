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
