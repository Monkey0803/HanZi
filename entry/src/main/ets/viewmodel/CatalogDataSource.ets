/*
 * CatalogDataSource.ets — 字表页状态（状态管理 V2）。
 *
 * 统一维护浏览模式、过滤条件、分组、索引选中项与搜索结果；
 * 数据本身仍来自 CurriculumRepository 的内存索引。
 */

import { CharacterEntry } from '../model/CurriculumModels';
import { ChoiceSet } from '../model/SettingsOptions';
import { CatalogQuery, CharacterCatalogService } from '../service/CharacterCatalogService';
import { curriculumRepository } from '../service/CurriculumRepository';
import { CatalogScope, StrokeBand } from '../common/constants/StrokeConstants';
import { CatalogBrowseMode, CatalogGridRow, CatalogGroup } from '../model/CatalogModels';

export interface CatalogDataProvider {
  isLoaded(): boolean;
  results(condition: CatalogQuery): CharacterEntry[];
  limitedData(): boolean;
  radicalChoice(current: string): ChoiceSet;
}

class AppCatalogDataProvider implements CatalogDataProvider {
  isLoaded(): boolean {
    return curriculumRepository.isLoaded();
  }

  results(condition: CatalogQuery): CharacterEntry[] {
    return CharacterCatalogService.results(condition, 0);
  }

  limitedData(): boolean {
    return CharacterCatalogService.isLimitedData();
  }

  radicalChoice(current: string): ChoiceSet {
    return CharacterCatalogService.radicalOptions(current);
  }
}

@ObservedV2
export class CatalogDataSource {
  @Trace keyword: string = '';
  @Trace scope: string = CatalogScope.ALL;
  @Trace band: string = StrokeBand.ALL;
  @Trace radical: string = '';
  @Trace browseMode: CatalogBrowseMode = CatalogBrowseMode.RADICAL;
  @Trace showPinyin: boolean = true;
  @Trace items: CharacterEntry[] = [];
  @Trace groups: CatalogGroup[] = [];
  @Trace selectedGroupIndex: number = 0;
  @Trace total: number = 0;
  @Trace limitedData: boolean = false;
  private provider: CatalogDataProvider = new AppCatalogDataProvider();

  constructor(provider?: CatalogDataProvider) {
    if (provider !== undefined) {
      this.provider = provider;
    }
  }

  reload(): void {
    if (!this.provider.isLoaded()) {
      this.items = [];
      this.total = 0;
      this.groups = [];
      this.limitedData = true;
      return;
    }
    this.items = this.provider.results(this.condition());
    this.total = this.items.length;
    this.groups = this.searching()
      ? []
      : CharacterCatalogService.groupEntries(this.items, this.browseMode);
    if (!this.searching()) {
      this.selectedGroupIndex = this.groups.length > 0
        ? Math.min(this.selectedGroupIndex, this.groups.length - 1)
        : 0;
    }
    this.limitedData = this.provider.limitedData();
  }

  searching(): boolean {
    return this.keyword.trim().length > 0;
  }

  setBrowseMode(value: CatalogBrowseMode): void {
    if (this.browseMode === value) {
      return;
    }
    this.browseMode = value;
    this.selectedGroupIndex = 0;
    this.reload();
  }

  setShowPinyin(value: boolean): void {
    this.showPinyin = value;
  }

  setKeyword(value: string): void {
    if (this.keyword === value) {
      return;
    }
    this.keyword = value;
    this.reload();
  }

  setScope(value: string): void {
    if (this.scope === value) {
      return;
    }
    this.scope = value;
    this.selectedGroupIndex = 0;
    this.reload();
  }

  setBand(value: string): void {
    if (this.band === value) {
      return;
    }
    this.band = value;
    this.selectedGroupIndex = 0;
    this.reload();
  }

  setRadical(value: string): void {
    if (this.radical === value) {
      return;
    }
    this.radical = value;
    this.selectedGroupIndex = 0;
    this.reload();
  }

  resetFilters(): void {
    this.scope = CatalogScope.ALL;
    this.band = StrokeBand.ALL;
    this.radical = '';
    this.selectedGroupIndex = 0;
    this.reload();
  }

  activeFilterCount(): number {
    let count: number = 0;
    if (this.scope !== CatalogScope.ALL) {
      count += 1;
    }
    if (this.band !== StrokeBand.ALL) {
      count += 1;
    }
    if (this.radical.length > 0) {
      count += 1;
    }
    return count;
  }

  indexLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < this.groups.length; i += 1) {
      labels.push(this.groups[i].indexLabel);
    }
    return labels;
  }

  searchRows(wide: boolean): CatalogGridRow[] {
    return CatalogGroup.partition('search', this.items, wide ? 8 : 5);
  }

  radicalChoice(): ChoiceSet {
    return this.provider.radicalChoice(this.radical);
  }

  private condition(): CatalogQuery {
    return new CatalogQuery(this.keyword, this.scope, this.band, this.radical);
  }
}
