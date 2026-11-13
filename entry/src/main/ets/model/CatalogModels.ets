/*
 * CatalogModels.ets — 字表浏览的分组与网格行模型。
 *
 * 手机五列、宽屏八列的行在服务层一次生成，视图只渲染当前断点对应的行，
 * 避免在 build 中重复切片或一次性创建整张字表。
 */

import { CharacterEntry } from './CurriculumModels';

export enum CatalogBrowseMode {
  RADICAL = 'radical',
  PINYIN = 'pinyin',
  STROKE = 'stroke'
}

export class CatalogGridRow {
  id: string = '';
  entries: CharacterEntry[] = [];

  constructor(id: string, entries: CharacterEntry[]) {
    this.id = id;
    this.entries = entries;
  }
}

export class CatalogGroup {
  key: string = '';
  displayTitle: string = '';
  indexLabel: string = '';
  indexPosition: number = 0;
  entries: CharacterEntry[] = [];
  narrowRows: CatalogGridRow[] = [];
  wideRows: CatalogGridRow[] = [];

  constructor(key: string, entries: CharacterEntry[], indexPosition: number = 0) {
    this.key = key;
    this.displayTitle = key;
    this.indexLabel = key;
    this.indexPosition = indexPosition;
    this.entries = entries;
    this.narrowRows = CatalogGroup.partition(key, entries, 5);
    this.wideRows = CatalogGroup.partition(key, entries, 8);
  }

  static partition(groupKey: string, entries: CharacterEntry[], columnCount: number): CatalogGridRow[] {
    const rows: CatalogGridRow[] = [];
    let rowIndex: number = 0;
    for (let start = 0; start < entries.length; start += columnCount) {
      const end: number = Math.min(start + columnCount, entries.length);
      rows.push(new CatalogGridRow(`${groupKey}-${rowIndex}`, entries.slice(start, end)));
      rowIndex += 1;
    }
    return rows;
  }
}
