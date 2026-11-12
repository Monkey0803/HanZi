import { describe, it, expect } from '@ohos/hypium';
import { IdeographDecomposition, StructureKind } from '../../../main/ets/service/IdeographDecomposition';

export default function ideographDecompositionTest() {
  describe('IdeographDecomposition', () => {
    it('detects_left_right_structure', 0, () => {
      expect(IdeographDecomposition.kindOf('⿰扌丁')).assertEqual(StructureKind.LEFT_RIGHT);
      expect(IdeographDecomposition.kindOf('⿰人木')).assertEqual(StructureKind.LEFT_RIGHT);
    });

    it('detects_top_bottom_and_triple_structures', 0, () => {
      expect(IdeographDecomposition.kindOf('⿱日十')).assertEqual(StructureKind.TOP_BOTTOM);
      expect(IdeographDecomposition.kindOf('⿲木木木')).assertEqual(StructureKind.LEFT_MIDDLE_RIGHT);
      expect(IdeographDecomposition.kindOf('⿳日大日')).assertEqual(StructureKind.TOP_MIDDLE_BOTTOM);
      expect(IdeographDecomposition.kindOf('⿻日十')).assertEqual(StructureKind.OVERLAY);
    });

    it('splits_enclosed_and_semi_enclosed', 0, () => {
      expect(IdeographDecomposition.kindOf('⿴囗玉')).assertEqual(StructureKind.SURROUND);
      expect(IdeographDecomposition.kindOf('⿵门日')).assertEqual(StructureKind.SEMI_SURROUND);
      expect(IdeographDecomposition.kindOf('⿺九日')).assertEqual(StructureKind.SEMI_SURROUND);
    });

    it('returns_unknown_for_empty_or_plain_text', 0, () => {
      expect(IdeographDecomposition.kindOf('')).assertEqual(StructureKind.UNKNOWN);
      expect(IdeographDecomposition.kindOf('一')).assertEqual(StructureKind.UNKNOWN);
      expect(IdeographDecomposition.kindOf('？')).assertEqual(StructureKind.UNKNOWN);
    });

    it('collects_components_without_operators_or_unknown_marks', 0, () => {
      const parts: string[] = IdeographDecomposition.componentsOf('⿰扌丁');
      expect(parts.length).assertEqual(2);
      expect(parts[0]).assertEqual('扌');
      expect(parts[1]).assertEqual('丁');
      expect(IdeographDecomposition.componentsOf('？').length).assertEqual(0);
      expect(IdeographDecomposition.componentsOf('一').length).assertEqual(1);
    });

    it('deduplicates_repeated_components', 0, () => {
      const parts: string[] = IdeographDecomposition.componentsOf('⿰木木');
      expect(parts.length).assertEqual(1);
      expect(parts[0]).assertEqual('木');
    });

    it('parse_combines_kind_and_components', 0, () => {
      const info = IdeographDecomposition.parse('⿱日十');
      expect(info.kind).assertEqual(StructureKind.TOP_BOTTOM);
      expect(info.components.length).assertEqual(2);
    });
  });
}
