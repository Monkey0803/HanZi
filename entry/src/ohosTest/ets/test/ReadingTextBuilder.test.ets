import { describe, it, expect } from '@ohos/hypium';
import { PassageGlyph } from '../../../main/ets/model/ReadingModels';
import { ReadingTextBuilder } from '../../../main/ets/service/ReadingTextBuilder';

// 短文排版纯函数单测：不依赖设备、Context 与课程数据。
export default function readingTextBuilderTest() {
  describe('ReadingTextBuilder', () => {
    it('builds_han_glyphs_with_pinyin_and_focus', 0, () => {
      const focus: Map<string, string> = new Map();
      focus.set('天', 'tiān');
      const all: Map<string, string> = new Map();
      all.set('地', 'dì');
      const glyphs: PassageGlyph[] = ReadingTextBuilder.build('天地。', focus, all, new Map());
      expect(glyphs.length).assertEqual(3);
      expect(glyphs[0].char).assertEqual('天');
      expect(glyphs[0].pinyin).assertEqual('tiān');
      expect(glyphs[0].isFocus).assertTrue();
      expect(glyphs[1].char).assertEqual('地');
      expect(glyphs[1].pinyin).assertEqual('dì');
      expect(glyphs[1].isFocus).assertFalse();
      expect(glyphs[2].char).assertEqual('。');
      expect(glyphs[2].isHan).assertFalse();
      expect(glyphs[2].pinyin).assertEqual('');
    });

    it('override_wins_over_lesson_pinyin', 0, () => {
      const focus: Map<string, string> = new Map();
      focus.set('地', 'de');
      const overrides: Map<string, string> = new Map();
      overrides.set('地', 'dì');
      const glyphs: PassageGlyph[] = ReadingTextBuilder.build('地', focus, new Map(), overrides);
      expect(glyphs.length).assertEqual(1);
      expect(glyphs[0].pinyin).assertEqual('dì');
      expect(glyphs[0].isFocus).assertTrue();
    });

    it('skips_spaces_and_keeps_punctuation', 0, () => {
      const glyphs: PassageGlyph[] = ReadingTextBuilder.build('天 上\u3000下，', new Map(), new Map(), new Map());
      expect(glyphs.length).assertEqual(4);
      expect(glyphs[0].char).assertEqual('天');
      expect(glyphs[1].char).assertEqual('上');
      expect(glyphs[2].char).assertEqual('下');
      expect(glyphs[3].char).assertEqual('，');
      expect(glyphs[0].pinyin).assertEqual('');
    });

    it('empty_text_returns_empty_array', 0, () => {
      const glyphs: PassageGlyph[] = ReadingTextBuilder.build('', new Map(), new Map(), new Map());
      expect(glyphs.length).assertEqual(0);
    });

    it('unknown_han_char_has_empty_pinyin', 0, () => {
      const glyphs: PassageGlyph[] = ReadingTextBuilder.build('龘', new Map(), new Map(), new Map());
      expect(glyphs.length).assertEqual(1);
      expect(glyphs[0].isHan).assertTrue();
      expect(glyphs[0].pinyin).assertEqual('');
      expect(glyphs[0].isFocus).assertFalse();
    });
  });
}
