import { describe, it, expect } from '@ohos/hypium';
import { PinyinUtils } from '../../../main/ets/service/PinyinUtils';
import { CatalogQuery, CharacterCatalogService } from '../../../main/ets/service/CharacterCatalogService';
import { CatalogScope, StrokeBand } from '../../../main/ets/common/constants/StrokeConstants';

export default function pinyinUtilsTest() {
  describe('PinyinUtils', () => {
    it('normalizes_tone_marks', 0, () => {
      expect(PinyinUtils.normalize('nǐ')).assertEqual('ni');
      expect(PinyinUtils.normalize('lǜ')).assertEqual('lv');
      expect(PinyinUtils.normalize('Zhōng')).assertEqual('zhong');
    });

    it('keeps_plain_letters_untouched', 0, () => {
      expect(PinyinUtils.normalize('hao')).assertEqual('hao');
      expect(PinyinUtils.normalize('  AI  ')).assertEqual('ai');
    });

    it('matches_any_reading_by_prefix', 0, () => {
      expect(PinyinUtils.matches(['hǎo', 'hào'], 'hao')).assertTrue();
      expect(PinyinUtils.matches(['hǎo', 'hào'], 'ha')).assertTrue();
      expect(PinyinUtils.matches(['hǎo', 'hào'], 'xi')).assertFalse();
      expect(PinyinUtils.matches(['hǎo'], '')).assertTrue();
    });

    it('matches_tone_typed_query', 0, () => {
      expect(PinyinUtils.matches(['lǜ'], 'lü')).assertTrue();
      expect(PinyinUtils.matches(['lǜ'], 'lv')).assertTrue();
    });
  });

  describe('CharacterCatalogService', () => {
    it('query_defaults_to_full_catalog', 0, () => {
      const query: CatalogQuery = new CatalogQuery();
      expect(query.scope).assertEqual(CatalogScope.ALL);
      expect(query.band).assertEqual(StrokeBand.ALL);
      expect(query.radical).assertEqual('');
      expect(query.query).assertEqual('');
    });

    it('returns_empty_before_repository_load', 0, () => {
      expect(CharacterCatalogService.results(new CatalogQuery(), 0).length).assertEqual(0);
      expect(CharacterCatalogService.isLimitedData()).assertTrue();
    });

    it('radical_options_always_offer_all', 0, () => {
      const options = CharacterCatalogService.radicalOptions('');
      expect(options.options.length >= 1).assertTrue();
      expect(options.options[0].id).assertEqual('');
    });
  });
}
