import { describe, it, expect } from '@ohos/hypium';
import { AdoptionPlan, Audit, adoptionPlan } from '../../../main/ets/common/adoption/AdoptionPolicy';

// 存量接入决策纯函数：覆盖 17-incremental-adoption 3.10.7 的 5 条门限断言。
export default function adoptionPolicyTest() {
  const baseline: Audit = {
    apiVersion: 26,
    stateV2: true,
    hasCommonModule: true,
    routerKind: 'HDS',
    testRunner: true,
    aclApproved: true
  };

  describe('AdoptionPolicy', () => {
    it('api_22_custom_immersive_degrades_to_smooth', 0, () => {
      const audit: Audit = {
        apiVersion: 22,
        stateV2: true,
        hasCommonModule: true,
        routerKind: 'HDS',
        testRunner: true,
        aclApproved: true
      };
      const plan: AdoptionPlan = adoptionPlan('CUSTOM_IMMERSIVE', audit);
      expect(plan.mode).assertEqual('DEGRADED');
      expect(plan.degrade).assertEqual('SMOOTH_OR_OFF');
    });

    it('anti_peep_without_acl_is_blocked', 0, () => {
      const audit: Audit = {
        apiVersion: 26,
        stateV2: true,
        hasCommonModule: true,
        routerKind: 'HDS',
        testRunner: true,
        aclApproved: false
      };
      const plan: AdoptionPlan = adoptionPlan('ANTI_PEEP', audit);
      expect(plan.mode).assertEqual('BLOCKED');
      expect(plan.gates.indexOf('DLP_ACL_PENDING') >= 0).assertTrue();
    });

    it('v1_custom_immersive_keeps_isolation_gate_and_refs_16', 0, () => {
      const audit: Audit = {
        apiVersion: 26,
        stateV2: false,
        hasCommonModule: true,
        routerKind: 'HDS',
        testRunner: true,
        aclApproved: true
      };
      const plan: AdoptionPlan = adoptionPlan('CUSTOM_IMMERSIVE', audit);
      expect(plan.gates.indexOf('V1_ISOLATION_BOUNDARY') >= 0).assertTrue();
      expect(plan.refs.indexOf('16') >= 0).assertTrue();
    });

    it('router_navigation_never_replaces_root_container', 0, () => {
      const audit: Audit = {
        apiVersion: 26,
        stateV2: true,
        hasCommonModule: true,
        routerKind: 'ROUTER',
        testRunner: true,
        aclApproved: true
      };
      const plan: AdoptionPlan = adoptionPlan('NAVIGATION', audit);
      expect(plan.gates.indexOf('LOCAL_CONTAINER_ONLY_NO_ROOT_REPLACE') >= 0).assertTrue();
    });

    it('missing_common_or_test_runner_only_appends_landing_points', 0, () => {
      const audit: Audit = {
        apiVersion: 26,
        stateV2: true,
        hasCommonModule: false,
        routerKind: 'HDS',
        testRunner: false,
        aclApproved: true
      };
      const plan: AdoptionPlan = adoptionPlan('MATERIAL', audit);
      expect(plan.changes.indexOf('target-module/ets/<feature>/') >= 0).assertTrue();
      expect(plan.changes.indexOf('oh-package.json5:devDependencies') >= 0).assertTrue();
      expect(plan.changes.indexOf('DELETE_EXISTING') < 0).assertTrue();

      const full: AdoptionPlan = adoptionPlan('MATERIAL', baseline);
      expect(full.mode).assertEqual('FULL');
      expect(full.gates.length).assertEqual(0);
    });
  });
}
