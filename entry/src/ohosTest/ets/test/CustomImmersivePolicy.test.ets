import { describe, it, expect } from '@ohos/hypium';
import {
  CustomPlan,
  PlanReason,
  customImmersivePlan,
  customStyleOf,
  effectiveLevel,
  resolveLevel
} from '../../../main/ets/common/material/CustomImmersivePolicy';

// 纯策略单测：不依赖设备、Context 与 Kit 枚举。
export default function customImmersivePolicyTest() {
  const ok: string[] = ['ADAPTIVE', 'IMMERSIVE'];

  describe('CustomImmersivePolicy', () => {
    it('AUTO_follows_system_adaptive_default', 0, () => {
      const p: CustomPlan = customImmersivePlan('AUTO', ok, 'L0', 'phone');
      expect(p.materialType).assertEqual('ADAPTIVE');
      expect(p.materialLevel).assertEqual('ADAPTIVE');
      expect(p.emitEffect).assertTrue();
    });

    it('unsupported_IMMERSIVE_forces_SMOOTH', 0, () => {
      const p: CustomPlan = customImmersivePlan('EXQUISITE', ['ADAPTIVE'], 'L0', 'phone');
      expect(p.materialLevel).assertEqual('SMOOTH');
      expect(p.reason).assertEqual(PlanReason.UNSUPPORTED_SMOOTH);
    });

    it('supported_device_can_use_EXQUISITE', 0, () => {
      const p: CustomPlan = customImmersivePlan('EXQUISITE', ok, 'L0', 'phone');
      expect(p.materialLevel).assertEqual('EXQUISITE');
      expect(p.reason).assertEqual(PlanReason.OK);
    });

    it('L1_caps_EXQUISITE_to_GENTLE', 0, () => {
      const p: CustomPlan = customImmersivePlan('EXQUISITE', ok, 'L1', 'phone');
      expect(p.materialLevel).assertEqual('GENTLE');
      expect(p.reason).assertEqual(PlanReason.L1_GENTLE);
    });

    it('wearable_and_query_failure_degrade_to_SMOOTH', 0, () => {
      expect(customImmersivePlan('EXQUISITE', ok, 'L0', 'wearable').materialLevel).assertEqual('SMOOTH');
      expect(customImmersivePlan('GENTLE', [], 'L0', 'phone').materialLevel).assertEqual('SMOOTH');
      expect(effectiveLevel('L0', 'wearable')).assertEqual('L2');
    });

    it('L3_disables_the_whole_effect_field', 0, () => {
      const p: CustomPlan = customImmersivePlan('EXQUISITE', ok, 'L3', 'phone');
      expect(p.emitEffect).assertFalse();
      expect(p.materialType).assertEqual('NONE');
      expect(p.reason).assertEqual(PlanReason.APP_DISABLED);
    });

    it('custom_level_never_rewrites_materialType_to_IMMERSIVE', 0, () => {
      expect(customImmersivePlan('GENTLE', ok, 'L0', 'phone').materialType).assertEqual('ADAPTIVE');
      expect(customImmersivePlan('SMOOTH', ok, 'L0', 'phone').materialType).assertEqual('ADAPTIVE');
    });

    it('resolveLevel_and_style_mapping_are_stable', 0, () => {
      expect(resolveLevel(false, true, 'EXQUISITE')).assertEqual('L3');
      expect(resolveLevel(true, false, 'EXQUISITE')).assertEqual('L2');
      expect(resolveLevel(true, true, 'SMOOTH')).assertEqual('L2');
      expect(resolveLevel(true, true, 'GENTLE')).assertEqual('L1');
      expect(resolveLevel(true, true, 'EXQUISITE')).assertEqual('L0');
      expect(customStyleOf('adaptive')).assertEqual('AUTO');
      expect(customStyleOf('exquisite')).assertEqual('EXQUISITE');
      expect(customStyleOf('bad')).assertEqual('AUTO');
    });
  });
}
