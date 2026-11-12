/*
 * CatalogDataSource.ets — 字表页状态（状态管理 V2）。
 *
 * 负责分页窗口与过滤条件的组合；数据本身仍来自 CurriculumRepository 的内存索引。
 */

import { CharacterEntry } from '../model/CurriculumModels';
import { ChoiceSet } from '../model/SettingsOptions';
import { CatalogQuery, CharacterCatalogService } from '../service/CharacterCatalogService';
import { curriculumRepository } from '../service/CurriculumRepository';
import { CatalogScope, StrokeBand } from '../common/constants/StrokeConstants';

/** 首次加载与每次「更多」追加的条数。 */
const PAGE_SIZE: number = 120;

@ObservedV2
export class CatalogDataSource {
  @Trace keyword: string = '';
  @Trace scope: string = CatalogScope.ALL;
  @Trace band: string = StrokeBand.ALL;
  @Trace radical: string = '';
  @Trace items: CharacterEntry[] = [];
  @Trace total: number = 0;
  @Trace limitedData: boolean = false;
  private window: number = PAGE_SIZE;

  reload(): void {
    if (!curriculumRepository.isLoaded()) {
      this.items = [];
      this.total = 0;
      this.limitedData = true;
      return;
    }
    this.window = PAGE_SIZE;
    this.total = CharacterCatalogService.count(this.condition());
    this.items = CharacterCatalogService.results(this.condition(), this.window);
    this.limitedData = CharacterCatalogService.isLimitedData();
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
    this.reload();
  }

  setBand(value: string): void {
    if (this.band === value) {
      return;
    }
    this.band = value;
    this.reload();
  }

  setRadical(value: string): void {
    if (this.radical === value) {
      return;
    }
    this.radical = value;
    this.reload();
  }

  hasMore(): boolean {
    return this.items.length < this.total;
  }

  loadMore(): void {
    if (!this.hasMore()) {
      return;
    }
    this.window += PAGE_SIZE;
    this.items = CharacterCatalogService.results(this.condition(), this.window);
  }

  radicalChoice(): ChoiceSet {
    return CharacterCatalogService.radicalOptions(this.radical);
  }

  private condition(): CatalogQuery {
    return new CatalogQuery(this.keyword, this.scope, this.band, this.radical);
  }
}
