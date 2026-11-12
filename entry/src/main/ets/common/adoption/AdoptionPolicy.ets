/*
 * AdoptionPolicy.ets — 存量工程增量接入的纯决策函数（skill 17 · 3.10.7）。
 *
 * 只依赖入参，不调用系统 API、不 import UI，可直接单测；
 * 页面与 service 拿它的结果决定「全量 / 降级 / 阻塞」以及要补的文件与断言。
 */

export type AdoptionMode = 'FULL' | 'DEGRADED' | 'BLOCKED';

export type FeatureKey = 'MATERIAL' | 'THEME' | 'BACKGROUND' | 'WINDOW_IMMERSIVE'
  | 'NAVIGATION' | 'REACH' | 'ANTI_PEEP' | 'MATERIAL_CHOICE' | 'CUSTOM_IMMERSIVE'
  | 'CARD' | 'I18N' | 'TEST' | 'RELEASE' | 'REUSE';

export type RouterKind = 'ROUTER' | 'NAVIGATION' | 'HDS';

/** A0 盘点结果（实测值，不含推断）。 */
export interface Audit {
  apiVersion: number;
  stateV2: boolean;
  hasCommonModule: boolean;
  routerKind: RouterKind;
  testRunner: boolean;
  aclApproved: boolean;
}

/** 一次接入的落地计划。 */
export interface AdoptionPlan {
  mode: AdoptionMode;
  refs: string[];
  gates: string[];
  changes: string[];
  tests: string[];
  degrade: string;
}

export function adoptionPlan(feature: FeatureKey, a: Audit): AdoptionPlan {
  const refs: string[] = ['17'];
  const gates: string[] = [];
  const changes: string[] = ['common/<feature>/'];
  const tests: string[] = ['src/test/<Feature>.test.ets'];
  let mode: AdoptionMode = 'FULL';
  let degrade: string = 'NONE';

  if (feature === 'CUSTOM_IMMERSIVE' || feature === 'REACH' || feature === 'MATERIAL_CHOICE') {
    refs.push('16', '15', '13', '14');
    if (a.apiVersion < 23) {
      mode = 'DEGRADED';
      degrade = 'SMOOTH_OR_OFF';
    }
  }
  if (feature === 'ANTI_PEEP') {
    refs.push('14', '11');
    if (!a.aclApproved) {
      mode = 'BLOCKED';
      gates.push('DLP_ACL_PENDING');
    }
  }
  if (!a.stateV2) {
    gates.push('V1_ISOLATION_BOUNDARY');
  }
  if (a.routerKind === 'ROUTER' && feature === 'NAVIGATION') {
    gates.push('LOCAL_CONTAINER_ONLY_NO_ROOT_REPLACE');
  }
  if (!a.hasCommonModule) {
    changes.push('target-module/ets/<feature>/');
  }
  if (!a.testRunner) {
    changes.push('oh-package.json5:devDependencies');
  }
  const plan: AdoptionPlan = {
    mode: mode,
    refs: refs,
    gates: gates,
    changes: changes,
    tests: tests,
    degrade: degrade
  };
  return plan;
}
