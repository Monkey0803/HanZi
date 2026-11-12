/*
 * CustomImmersivePolicy.ets — 自定义沉浸光感的纯策略函数。
 *
 * 无系统 API、无 UI import，可直接进 ohosTest：
 * - resolveLevel()：把「开关 / 设备能力 / 算力档」收敛成 L0–L3；
 * - customImmersivePlan()：把用户档位与设备能力求交集，输出下发到 HDS 的配置。
 *
 * 关键约束（skill 16）：
 * - 自定义只切 materialLevel，materialType 恒 ADAPTIVE；
 * - 只有 getSystemMaterialTypes() 含 IMMERSIVE 才可选 EXQUISITE / GENTLE，
 *   否则 SMOOTH（降低卡顿与发热）；
 * - L1 把 EXQUISITE 收敛为 GENTLE；L2 恒 SMOOTH；L3 整体不下发。
 */

/** 降级档位：L0 最高，L3 关闭。 */
export type MaterialLevelBand = 'L0' | 'L1' | 'L2' | 'L3';

/** 用户在设置页可选的自定义档位；AUTO = 跟随系统自适应。 */
export type CustomStyle = 'AUTO' | 'EXQUISITE' | 'GENTLE' | 'SMOOTH';

/** 下发到 hdsMaterial 的实际档位。 */
export type CustomLevel = 'ADAPTIVE' | 'EXQUISITE' | 'GENTLE' | 'SMOOTH';

/** 下发到 hdsMaterial 的实际类型；自定义路径只会是 ADAPTIVE 或 NONE。 */
export type CustomType = 'NONE' | 'ADAPTIVE';

/** 降级原因（供设置页展示与单测断言）。 */
export enum PlanReason {
  APP_DISABLED = 'app disabled',
  L2_SMOOTH = 'L2 -> SMOOTH',
  UNSUPPORTED_SMOOTH = 'IMMERSIVE unsupported -> SMOOTH',
  SYSTEM_ADAPTIVE = 'system adaptive',
  USER_SMOOTH = 'user SMOOTH',
  L1_GENTLE = 'L1 cap GENTLE',
  OK = 'ok'
}

/** 一次计算的完整结果；标题栏与底部页签共用同一份。 */
export interface CustomPlan {
  materialType: CustomType;
  materialLevel: CustomLevel;
  emitEffect: boolean;
  reason: string;
}

/** 用户设置里的语义 id -> 自定义档位；脏值回到 AUTO。 */
export function customStyleOf(id: string): CustomStyle {
  if (id === 'exquisite') {
    return 'EXQUISITE';
  }
  if (id === 'gentle') {
    return 'GENTLE';
  }
  if (id === 'smooth') {
    return 'SMOOTH';
  }
  return 'AUTO';
}

/** 手表一律按 L2 处理；其余设备保持输入档位。 */
export function effectiveLevel(level: MaterialLevelBand, device: string): MaterialLevelBand {
  if (device === 'wearable') {
    return 'L2';
  }
  return level;
}

/**
 * 由「总开关 / 是否支持 HDS 沉浸材质 / uiMaterial 算力档」推导 L0–L3。
 * 算力档只读（EXQUISITE / GENTLE / SMOOTH），映射为高 / 中 / 低。
 */
export function resolveLevel(immersiveOn: boolean, hdsSupported: boolean, globalLevel: string): MaterialLevelBand {
  if (!immersiveOn) {
    return 'L3';
  }
  if (!hdsSupported) {
    return 'L2';
  }
  if (globalLevel === 'SMOOTH') {
    return 'L2';
  }
  if (globalLevel === 'GENTLE') {
    return 'L1';
  }
  return 'L0';
}

/**
 * 自定义沉浸光感决策：
 * L3 → 不下发；L2 / 不支持 IMMERSIVE → SMOOTH；
 * AUTO → 系统自适应；SMOOTH → SMOOTH；
 * L1 且 EXQUISITE → GENTLE。
 */
export function customImmersivePlan(userStyle: CustomStyle, materialTypes: string[], level: MaterialLevelBand,
  device: string): CustomPlan {
  const lv: MaterialLevelBand = effectiveLevel(level, device);
  if (lv === 'L3') {
    const disabled: CustomPlan = {
      materialType: 'NONE',
      materialLevel: 'SMOOTH',
      emitEffect: false,
      reason: PlanReason.APP_DISABLED
    };
    return disabled;
  }
  if (lv === 'L2') {
    const l2: CustomPlan = {
      materialType: 'ADAPTIVE',
      materialLevel: 'SMOOTH',
      emitEffect: true,
      reason: PlanReason.L2_SMOOTH
    };
    return l2;
  }
  if (materialTypes.indexOf('IMMERSIVE') < 0) {
    const unsupported: CustomPlan = {
      materialType: 'ADAPTIVE',
      materialLevel: 'SMOOTH',
      emitEffect: true,
      reason: PlanReason.UNSUPPORTED_SMOOTH
    };
    return unsupported;
  }
  if (userStyle === 'AUTO') {
    const adaptive: CustomPlan = {
      materialType: 'ADAPTIVE',
      materialLevel: 'ADAPTIVE',
      emitEffect: true,
      reason: PlanReason.SYSTEM_ADAPTIVE
    };
    return adaptive;
  }
  if (userStyle === 'SMOOTH') {
    const smooth: CustomPlan = {
      materialType: 'ADAPTIVE',
      materialLevel: 'SMOOTH',
      emitEffect: true,
      reason: PlanReason.USER_SMOOTH
    };
    return smooth;
  }
  const capped: boolean = userStyle === 'EXQUISITE' && lv === 'L1';
  const chosen: CustomLevel = capped ? 'GENTLE' : userStyle;
  const plan: CustomPlan = {
    materialType: 'ADAPTIVE',
    materialLevel: chosen,
    emitEffect: true,
    reason: capped ? PlanReason.L1_GENTLE : PlanReason.OK
  };
  return plan;
}
