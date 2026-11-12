/*
 * CustomImmersiveViewModel.ets — 自定义沉浸光感的唯一重算入口（@ObservedV2）。
 *
 * 职责：
 * - 汇总「总开关 / 设备能力 / 算力档 / 用户档位」并调用纯策略；
 * - 把结果同时供给标题栏与底部悬浮页签（两处读同一个 plan，不各算一次）；
 * - 把降级原因翻译成设置页文案。
 *
 * 不 import 任何 UI 组件；HDS 枚举映射由 MaterialController 完成。
 */

import { deviceInfo } from '@kit.BasicServicesKit';
import { appSettings } from '../model/AppSettings';
import { MaterialController } from '../service/MaterialController';
import {
  CustomPlan,
  MaterialLevelBand,
  PlanReason,
  customImmersivePlan,
  customStyleOf,
  resolveLevel
} from '../common/material/CustomImmersivePolicy';

@ObservedV2
export class CustomImmersiveViewModel {
  /** 当前生效计划；初始值按「未知设备 + 未探测」保守处理。 */
  @Trace plan: CustomPlan = customImmersivePlan('AUTO', [], 'L2', 'phone');
  /** 当前降级档位（L0–L3），供设置页只读展示。 */
  @Trace band: MaterialLevelBand = 'L2';

  /** 设置加载完成、任意相关开关变化、设备能力变化后调用。 */
  recompute(): void {
    const level: MaterialLevelBand = resolveLevel(
      appSettings.immersiveOn,
      MaterialController.immersiveSupported(),
      MaterialController.globalLevelId()
    );
    const next: CustomPlan = customImmersivePlan(
      customStyleOf(appSettings.materialLevel),
      MaterialController.materialTypeNames(),
      level,
      deviceInfo.deviceType
    );
    this.band = level;
    this.plan = next;
  }

  /** 降级原因文案（设置页展示；未命中时保持空串）。 */
  reasonText(): ResourceStr {
    const reason: string = this.plan.reason;
    if (reason === PlanReason.APP_DISABLED) {
      return $r('app.string.custom_immersive_reason_off');
    }
    if (reason === PlanReason.L2_SMOOTH) {
      return $r('app.string.custom_immersive_reason_l2');
    }
    if (reason === PlanReason.UNSUPPORTED_SMOOTH) {
      return $r('app.string.custom_immersive_reason_unsupported');
    }
    if (reason === PlanReason.SYSTEM_ADAPTIVE) {
      return $r('app.string.custom_immersive_reason_auto');
    }
    if (reason === PlanReason.USER_SMOOTH) {
      return $r('app.string.custom_immersive_reason_user_smooth');
    }
    if (reason === PlanReason.L1_GENTLE) {
      return $r('app.string.custom_immersive_reason_l1');
    }
    return $r('app.string.custom_immersive_reason_ok');
  }
}

/** 全局唯一 ViewModel。 */
export const customImmersiveViewModel: CustomImmersiveViewModel = new CustomImmersiveViewModel();
