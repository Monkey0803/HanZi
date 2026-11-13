import { describe, it, expect } from '@ohos/hypium';
import { CharacterEntry } from '../../../main/ets/model/CurriculumModels';
import { CatalogBrowseMode, CatalogGroup } from '../../../main/ets/model/CatalogModels';
import { CatalogQuery, CharacterCatalogService } from '../../../main/ets/service/CharacterCatalogService';
import { CurriculumRepository } from '../../../main/ets/service/CurriculumRepository';
import { CatalogDataProvider, CatalogDataSource } from '../../../main/ets/viewmodel/CatalogDataSource';
import { CatalogScope, StrokeBand } from '../../../main/ets/common/constants/StrokeConstants';
import { ChoiceOption, ChoiceSet } from '../../../main/ets/model/SettingsOptions';

function catalogEntry(char: string, pinyin: string, radical: string, strokeCount: number): CharacterEntry {
  const entry: CharacterEntry = new CharacterEntry();
  entry.char = char;
  entry.pinyins = pinyin.length > 0 ? [pinyin] : [];
  entry.radical = radical;
  entry.strokeCount = strokeCount;
  return entry;
}

class FixtureCatalogProvider implements CatalogDataProvider {
  private entries: CharacterEntry[] = [];

  constructor(entries: CharacterEntry[]) {
    this.entries = entries;
  }

  isLoaded(): boolean {
    return true;
  }

  results(condition: CatalogQuery): CharacterEntry[] {
    return CurriculumRepository.filterCatalogEntries(this.entries, condition.query, condition.scope,
      condition.band, condition.radical, 0);
  }

  limitedData(): boolean {
    return false;
  }

  radicalChoice(_current: string): ChoiceSet {
    return new ChoiceSet([new ChoiceOption('', 'All')], '');
  }
}

export default function catalogBrowserTest() {
  describe('CatalogBrowser', () => {
    it('groups_by_radical_and_places_unknown_last', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('你', 'nǐ', '亻', 7),
        catalogEntry('人', 'rén', '人', 2),
        catalogEntry('也', 'yě', '', 3),
        catalogEntry('他', 'tā', '亻', 5)
      ];
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.RADICAL);

      expect(groups.length).assertEqual(3);
      expect(groups[0].key).assertEqual('人');
      expect(groups[1].key).assertEqual('亻');
      expect(groups[1].entries[0].char).assertEqual('他');
      expect(groups[2].key).assertEqual('#');
    });

    it('groups_pinyin_by_normalized_initial', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('中', 'zhōng', '丨', 4),
        catalogEntry('好', 'hǎo', '女', 6),
        catalogEntry('略', 'lüè', '田', 11),
        catalogEntry('〇', '', '', 1)
      ];
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.PINYIN);

      expect(groups[0].key).assertEqual('H');
      expect(groups[0].entries[0].char).assertEqual('好');
      expect(groups[1].key).assertEqual('L');
      expect(groups[2].key).assertEqual('Z');
      expect(groups[3].key).assertEqual('#');
    });

    it('groups_strokes_in_numeric_order', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('九', 'jiǔ', '乙', 2),
        catalogEntry('十', 'shí', '十', 2),
        catalogEntry('龍', 'lóng', '龍', 16),
        catalogEntry('〇', '', '', 0)
      ];
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.STROKE);

      expect(groups[0].key).assertEqual('2');
      expect(groups[1].key).assertEqual('16');
      expect(groups[2].key).assertEqual('#');
    });

    it('uses_first_reading_for_pinyin_group_and_sort', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('重', 'zhòng', '里', 9),
        catalogEntry('张', 'zhāng', '弓', 7),
        catalogEntry('长', 'cháng', '长', 4)
      ];
      entries[0].pinyins = ['zhòng', 'chóng'];
      entries[2].pinyins = ['cháng', 'zhǎng'];
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.PINYIN);

      expect(groups[0].key).assertEqual('C');
      expect(groups[0].entries[0].char).assertEqual('长');
      expect(groups[1].key).assertEqual('Z');
      expect(groups[1].entries[0].char).assertEqual('张');
      expect(groups[1].entries[1].char).assertEqual('重');
    });

    it('partitions_every_entry_for_phone_and_wide_grids', 0, () => {
      const entries: CharacterEntry[] = [];
      for (let i = 0; i < 11; i += 1) {
        entries.push(catalogEntry(i.toString(), 'a', '一', i + 1));
      }
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.RADICAL);

      expect(groups[0].narrowRows.length).assertEqual(3);
      expect(groups[0].narrowRows[2].entries.length).assertEqual(1);
      expect(groups[0].wideRows.length).assertEqual(2);
      expect(groups[0].wideRows[1].entries.length).assertEqual(3);
    });

    it('keeps_index_positions_and_grid_members_one_to_one', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('一', 'yī', '一', 1),
        catalogEntry('二', 'èr', '二', 2),
        catalogEntry('三', 'sān', '一', 3),
        catalogEntry('四', 'sì', '囗', 5)
      ];
      const groups: CatalogGroup[] = CharacterCatalogService.groupEntries(entries, CatalogBrowseMode.RADICAL);
      const narrowChars: string[] = [];
      const wideChars: string[] = [];

      for (let groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
        expect(groups[groupIndex].indexPosition).assertEqual(groupIndex);
        expect(groups[groupIndex].indexLabel).assertEqual(groups[groupIndex].key);
        for (let rowIndex = 0; rowIndex < groups[groupIndex].narrowRows.length; rowIndex += 1) {
          const rowEntries: CharacterEntry[] = groups[groupIndex].narrowRows[rowIndex].entries;
          for (let entryIndex = 0; entryIndex < rowEntries.length; entryIndex += 1) {
            narrowChars.push(rowEntries[entryIndex].char);
          }
        }
        for (let rowIndex = 0; rowIndex < groups[groupIndex].wideRows.length; rowIndex += 1) {
          const rowEntries: CharacterEntry[] = groups[groupIndex].wideRows[rowIndex].entries;
          for (let entryIndex = 0; entryIndex < rowEntries.length; entryIndex += 1) {
            wideChars.push(rowEntries[entryIndex].char);
          }
        }
      }

      expect(narrowChars.length).assertEqual(entries.length);
      expect(wideChars.length).assertEqual(entries.length);
      expect(narrowChars.join('')).assertEqual(wideChars.join(''));
    });

    it('combines_scope_stroke_radical_and_search_filters', 0, () => {
      const curriculumMatch: CharacterEntry = catalogEntry('你', 'nǐ', '亻', 7);
      curriculumMatch.inCurriculum = true;
      const commonMatch: CharacterEntry = catalogEntry('佞', 'nìng', '亻', 7);
      commonMatch.inCurriculum = false;
      const wrongStroke: CharacterEntry = catalogEntry('伲', 'nǐ', '亻', 9);
      wrongStroke.inCurriculum = true;
      const wrongRadical: CharacterEntry = catalogEntry('妮', 'nī', '女', 8);
      wrongRadical.inCurriculum = true;
      const wrongSearch: CharacterEntry = catalogEntry('他', 'tā', '亻', 5);
      wrongSearch.inCurriculum = true;
      const entries: CharacterEntry[] = [commonMatch, wrongStroke, wrongRadical, wrongSearch, curriculumMatch];

      const result: CharacterEntry[] = CurriculumRepository.filterCatalogEntries(entries, 'ni',
        CatalogScope.CURRICULUM, StrokeBand.B2, '亻', 0);

      expect(result.length).assertEqual(1);
      expect(result[0].char).assertEqual('你');
    });

    it('maintains_search_and_filter_state_transitions', 0, () => {
      const entries: CharacterEntry[] = [
        catalogEntry('好', 'hǎo', '女', 6),
        catalogEntry('你', 'nǐ', '亻', 7),
        catalogEntry('他', 'tā', '亻', 5)
      ];
      for (let i = 0; i < entries.length; i += 1) {
        entries[i].inCurriculum = true;
      }
      const source: CatalogDataSource = new CatalogDataSource(new FixtureCatalogProvider(entries));
      source.reload();
      expect(source.groups.length).assertEqual(2);
      source.selectedGroupIndex = 1;
      source.setKeyword('hao');
      expect(source.searching()).assertTrue();
      expect(source.groups.length).assertEqual(0);

      source.setKeyword('');
      expect(source.searching()).assertFalse();
      expect(source.groups.length).assertEqual(2);
      expect(source.selectedGroupIndex).assertEqual(1);

      source.setBrowseMode(CatalogBrowseMode.PINYIN);
      expect(source.browseMode).assertEqual(CatalogBrowseMode.PINYIN);
      expect(source.selectedGroupIndex).assertEqual(0);

      source.setScope(CatalogScope.CURRICULUM);
      source.setBand(StrokeBand.B2);
      source.setRadical('亻');
      expect(source.activeFilterCount()).assertEqual(3);
      source.resetFilters();
      expect(source.activeFilterCount()).assertEqual(0);
    });
  });
}
