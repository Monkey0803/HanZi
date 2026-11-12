/*
 * SettingsViewModel.ets — 设置的装配与副作用（@ObservedV2）。
 *
 * 界面只读 appSettings 的字段；任何一次用户改动都经由这里：写状态 → 应用副作用 → 落盘。
 */

import { common } from '@kit.AbilityKit';
import { uiMaterial } from '@kit.ArkUI';
import { appSettings } from '../model/AppSettings';
import { settingsStore } from '../service/SettingsStore';
import { ThemeController } from '../service/ThemeController';
import { LocaleController } from '../service/LocaleController';
import { MaterialController } from '../service/MaterialController';
import { antiPeep } from '../service/AntiPeep';
import { gripSensor } from '../service/GripSensor';
import { ThemeColorMath } from '../common/utils/ThemeColorMath';
import { customImmersiveViewModel } from './CustomImmersiveViewModel';

@ObservedV2
export class SettingsViewModel {
  /** 本机是否支持沉浸式材质（设置页可据此提示降级）。 */
  @Trace immersiveSupported: boolean = true;
  /** 应用级（全局）沉浸光感状态说明（default / enable / disable，来自 module.json5 metadata）。 */
  @Trace stateCaption: ResourceStr = '';
  /** 设备材质等级说明（高 / 中 / 低算力，由设备决定、只能查不能设）。 */
  @Trace levelCaption: ResourceStr = '';

  /** 启动时装配：恢复落盘设置 → 应用主题与语言 → 恢复防窥订阅（不弹窗）。 */
  init(context: common.Context): void {
    this.load(context);
  }

  private async load(context: common.Context): Promise<void> {
    await settingsStore.load(context);
    ThemeController.apply(context, appSettings.themeMode);
    LocaleController.apply(appSettings.languageMode);
    this.immersiveSupported = MaterialController.immersiveSupported();
    this.stateCaption = SettingsViewModel.stateCaptionOf(MaterialController.materialState());
    this.levelCaption = SettingsViewModel.levelCaptionOf(MaterialController.globalLevel());
    // 设置恢复后重算一次：自定义沉浸光感的档位 / 降级原因依赖开关与设备能力。
    customImmersiveViewModel.recompute();
    gripSensor.setEnabled(appSettings.gripEnabled);
    if (appSettings.antiPeepEnabled) {
      await antiPeep.setEnabled(true);
    }
  }

  /**
   * 应用级状态文案：三态各有含义，不能简单写成"开 / 关"。
   * DEFAULT 下只有弹窗与文本菜单默认开材质；ENABLE 下系统清单内的组件默认开启
   * （Popup / Tips / Button 不在清单内，仍需组件级显式设置）。
   */
  private static stateCaptionOf(state: uiMaterial.MaterialState): ResourceStr {
    if (state === uiMaterial.MaterialState.ENABLE) {
      return $r('app.string.aux_material_state_enable');
    }
    if (state === uiMaterial.MaterialState.DISABLE) {
      return $r('app.string.aux_material_state_disable');
    }
    return $r('app.string.aux_material_state_default');
  }

  /**
   * 材质等级文案：uiMaterial 的 MaterialLevel 只有三档，由设备算力决定、应用无法设置，
   * 所以这里只做展示（排查"为什么这台机器效果不一样"时先看它）。
   */
  private static levelCaptionOf(level: uiMaterial.MaterialLevel): ResourceStr {
    if (level === uiMaterial.MaterialLevel.EXQUISITE) {
      return $r('app.string.aux_material_level_high');
    }
    if (level === uiMaterial.MaterialLevel.GENTLE) {
      return $r('app.string.aux_material_level_mid');
    }
    return $r('app.string.aux_material_level_low');
  }

  setTheme(context: common.Context, id: string): void {
    appSettings.themeMode = id;
    ThemeController.apply(context, id);
    settingsStore.save();
  }

  setLanguage(id: string): void {
    appSettings.languageMode = id;
    LocaleController.apply(id);
    settingsStore.save();
  }

  /** 主题色：归一后写入 appSettings；ThemePalette 的 getter 会自动刷新所有读取处。 */
  setThemeColor(hex: string): void {
    appSettings.themeColor = ThemeColorMath.normalize(hex, appSettings.themeColor);
    settingsStore.save();
  }

  /** 取色过程中实时预览：只改内存状态，不落盘（用户取消时不会留下脏值）。 */
  previewThemeColor(hex: string): void {
    appSettings.themeColor = ThemeColorMath.normalize(hex, appSettings.themeColor);
  }

  setImmersiveOn(value: boolean): void {
    appSettings.immersiveOn = value;
    customImmersiveViewModel.recompute();
    settingsStore.save();
  }

  setLightEffectEnabled(value: boolean): void {
    appSettings.lightEffectEnabled = value;
    settingsStore.save();
  }

  setMaterialType(id: string): void {
    appSettings.materialType = id;
    customImmersiveViewModel.recompute();
    settingsStore.save();
  }

  setMaterialLevel(id: string): void {
    appSettings.materialLevel = id;
    customImmersiveViewModel.recompute();
    settingsStore.save();
  }

  setGripEnabled(value: boolean): void {
    appSettings.gripEnabled = value;
    // 开关即订阅开关：开启时订阅 holdingHandChanged，关闭时 off。
    gripSensor.setEnabled(value);
    settingsStore.save();
  }

  setShowStrokeNumbers(value: boolean): void {
    appSettings.showStrokeNumbers = value;
    settingsStore.save();
  }

  setGridStyle(id: string): void {
    appSettings.gridStyle = id;
    settingsStore.save();
  }

  setShowSkeleton(value: boolean): void {
    appSettings.showSkeleton = value;
    settingsStore.save();
  }

  setShowStrokeSteps(value: boolean): void {
    appSettings.showStrokeSteps = value;
    settingsStore.save();
  }

  setAntiPeepEnabled(value: boolean, context: common.UIAbilityContext): void {
    appSettings.antiPeepEnabled = value;
    this.applyAntiPeep(value, context);
    settingsStore.save();
  }

  private async applyAntiPeep(value: boolean, context: common.UIAbilityContext): Promise<void> {
    await antiPeep.setEnabled(value, context);
  }
}

/** 全局唯一 ViewModel。 */
export const settingsViewModel: SettingsViewModel = new SettingsViewModel();
