/*
 * SettingsStore.ets — 设置的落盘与恢复（@ohos.data.preferences）。
 *
 * 只存语义 id / 布尔量，逐键存：读出来先归一（`ChoiceSet.normalize`），脏值退回默认项。
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { appSettings } from '../model/AppSettings';
import { THEME_OPTIONS, LANGUAGE_OPTIONS, MATERIAL_TYPE_OPTIONS, MATERIAL_LEVEL_OPTIONS, GRID_OPTIONS,
  DAILY_GOAL_OPTIONS, STROKE_SPEED_OPTIONS } from '../model/SettingsOptions';
import { PreferencesConstants } from '../common/constants/PreferencesConstants';
import { DEFAULT_THEME_COLOR } from '../common/constants/SettingsConstants';
import { ThemeColorMath } from '../common/utils/ThemeColorMath';

export class SettingsStore {
  private store: preferences.Preferences | undefined = undefined;

  /** 打开偏好库并把已存的值读进 appSettings。首次运行读不到值就保持默认。 */
  async load(context: common.Context): Promise<void> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, PreferencesConstants.STORE_NAME);
      this.store = store;
      const theme: string = store.getSync(PreferencesConstants.KEY_THEME_MODE, appSettings.themeMode) as string;
      const language: string = store.getSync(PreferencesConstants.KEY_LANGUAGE_MODE, appSettings.languageMode) as string;
      const materialType: string = store.getSync(PreferencesConstants.KEY_MATERIAL_TYPE, appSettings.materialType) as string;
      const materialLevel: string = store.getSync(PreferencesConstants.KEY_MATERIAL_LEVEL, appSettings.materialLevel) as string;
      appSettings.themeMode = THEME_OPTIONS.normalize(theme);
      appSettings.languageMode = LANGUAGE_OPTIONS.normalize(language);
      appSettings.materialType = MATERIAL_TYPE_OPTIONS.normalize(materialType);
      appSettings.materialLevel = MATERIAL_LEVEL_OPTIONS.normalize(materialLevel);
      appSettings.immersiveOn = store.getSync(PreferencesConstants.KEY_IMMERSIVE_ON, appSettings.immersiveOn) as boolean;
      appSettings.lightEffectEnabled = store.getSync(PreferencesConstants.KEY_LIGHT_EFFECT, appSettings.lightEffectEnabled) as boolean;
      appSettings.gripEnabled = store.getSync(PreferencesConstants.KEY_GRIP_ENABLED, appSettings.gripEnabled) as boolean;
      // 首版未申请 DLP ACL，防窥入口隐藏且启动时强制关闭，避免旧偏好误触发受限能力。
      appSettings.antiPeepEnabled = false;
      appSettings.showStrokeNumbers = store.getSync(PreferencesConstants.KEY_STROKE_NUMBERS, appSettings.showStrokeNumbers) as boolean;
      appSettings.showSkeleton = store.getSync(PreferencesConstants.KEY_STROKE_SKELETON, appSettings.showSkeleton) as boolean;
      appSettings.showStrokeSteps = store.getSync(PreferencesConstants.KEY_STROKE_STEPS, appSettings.showStrokeSteps) as boolean;
      const gridStyle: string = store.getSync(PreferencesConstants.KEY_GRID_STYLE, appSettings.gridStyle) as string;
      appSettings.gridStyle = GRID_OPTIONS.normalize(gridStyle);
      const dailyGoal: number = store.getSync(PreferencesConstants.KEY_DAILY_GOAL, appSettings.dailyGoal) as number;
      appSettings.dailyGoal = Number(DAILY_GOAL_OPTIONS.normalize(dailyGoal.toString()));
      const strokeSpeed: string = store.getSync(PreferencesConstants.KEY_STROKE_SPEED,
        appSettings.strokeSpeed) as string;
      appSettings.strokeSpeed = STROKE_SPEED_OPTIONS.normalize(strokeSpeed);
      appSettings.hidePinyin = store.getSync(PreferencesConstants.KEY_HIDE_PINYIN,
        appSettings.hidePinyin) as boolean;
      appSettings.ttsEnabled = store.getSync(PreferencesConstants.KEY_TTS_ENABLED,
        appSettings.ttsEnabled) as boolean;
      const themeColor: string =
        store.getSync(PreferencesConstants.KEY_THEME_COLOR, appSettings.themeColor) as string;
      appSettings.themeColor = ThemeColorMath.normalize(themeColor, DEFAULT_THEME_COLOR);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('SettingsStore.load failed: ' + error.code.toString());
    }
  }

  /** 把当前 appSettings 全量写回。任何一次用户改动后调用。 */
  save(): void {
    const store: preferences.Preferences | undefined = this.store;
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(PreferencesConstants.KEY_THEME_MODE, appSettings.themeMode);
      store.putSync(PreferencesConstants.KEY_LANGUAGE_MODE, appSettings.languageMode);
      store.putSync(PreferencesConstants.KEY_MATERIAL_TYPE, appSettings.materialType);
      store.putSync(PreferencesConstants.KEY_MATERIAL_LEVEL, appSettings.materialLevel);
      store.putSync(PreferencesConstants.KEY_IMMERSIVE_ON, appSettings.immersiveOn);
      store.putSync(PreferencesConstants.KEY_LIGHT_EFFECT, appSettings.lightEffectEnabled);
      store.putSync(PreferencesConstants.KEY_GRIP_ENABLED, appSettings.gripEnabled);
      store.putSync(PreferencesConstants.KEY_ANTI_PEEP_ENABLED, appSettings.antiPeepEnabled);
      store.putSync(PreferencesConstants.KEY_STROKE_NUMBERS, appSettings.showStrokeNumbers);
      store.putSync(PreferencesConstants.KEY_STROKE_SKELETON, appSettings.showSkeleton);
      store.putSync(PreferencesConstants.KEY_STROKE_STEPS, appSettings.showStrokeSteps);
      store.putSync(PreferencesConstants.KEY_GRID_STYLE, appSettings.gridStyle);
      store.putSync(PreferencesConstants.KEY_THEME_COLOR, appSettings.themeColor);
      store.putSync(PreferencesConstants.KEY_DAILY_GOAL, appSettings.dailyGoal);
      store.putSync(PreferencesConstants.KEY_STROKE_SPEED, appSettings.strokeSpeed);
      store.putSync(PreferencesConstants.KEY_HIDE_PINYIN, appSettings.hidePinyin);
      store.putSync(PreferencesConstants.KEY_TTS_ENABLED, appSettings.ttsEnabled);
      store.flush().catch((err: BusinessError) => {
        console.error('SettingsStore.flush failed: ' + err.code.toString());
      });
    } catch (err) {
      // putSync 可能抛（库已关闭 / 存储异常）：落盘失败不该让设置操作崩掉。
      const error: BusinessError = err as BusinessError;
      console.error('SettingsStore.save failed: ' + error.code.toString());
    }
  }
}

export const settingsStore: SettingsStore = new SettingsStore();
