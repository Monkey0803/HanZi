/*
 * AppSettings.ets — 应用设置状态（ArkTS 状态管理 V2）。
 *
 * 用 @ObservedV2 + @Trace：状态被任何持有者读取都会建立观察关系，所以这里做成模块级
 * 单例（appSettings），界面直接 import 读写即可，不需要在组件间层层传参。
 */

import { THEME_OPTIONS, LANGUAGE_OPTIONS, MATERIAL_TYPE_OPTIONS, MATERIAL_LEVEL_OPTIONS } from './SettingsOptions';
import { DEFAULT_THEME_COLOR } from '../common/constants/SettingsConstants';
import { GridStyleId, StrokeSpeedId } from '../common/constants/StrokeConstants';

@ObservedV2
export class AppSettings {
  /** 主题：'system' | 'light' | 'dark'。 */
  @Trace themeMode: string = THEME_OPTIONS.defaultValue;
  /** 主题色：#RRGGBB（默认品牌蓝；自定义色为任意合法色值）。 */
  @Trace themeColor: string = DEFAULT_THEME_COLOR;
  /** 语言：'system' | 'zh' | 'en'。 */
  @Trace languageMode: string = LANGUAGE_OPTIONS.defaultValue;
  /** 沉浸光感总开关。 */
  @Trace immersiveOn: boolean = true;
  /** 光感反馈开关（沉浸式系统材质的 lightEffect 流光跟随）。 */
  @Trace lightEffectEnabled: boolean = true;
  /** 材质类型：'adaptive' | 'immersive' | 'none'。 */
  @Trace materialType: string = MATERIAL_TYPE_OPTIONS.defaultValue;
  /** 沉浸光感材质四档：'exquisite' | 'gentle' | 'smooth' | 'adaptive'。 */
  @Trace materialLevel: string = MATERIAL_LEVEL_OPTIONS.defaultValue;
  /** 智感握姿：悬浮页签是否跟随握持手。 */
  @Trace gripEnabled: boolean = true;
  /** 防窥保护总开关。 */
  @Trace antiPeepEnabled: boolean = false;
  /** 字详情是否显示笔顺序号。 */
  @Trace showStrokeNumbers: boolean = true;
  /** 字格样式：'tian' | 'mi' | 'nine' | 'none'。 */
  @Trace gridStyle: string = GridStyleId.TIAN;
  /** 是否显示 median 透视骨架与运笔方向。 */
  @Trace showSkeleton: boolean = false;
  /** 字详情是否显示笔顺步骤条。 */
  @Trace showStrokeSteps: boolean = true;
  /** 每日学习目标。 */
  @Trace dailyGoal: number = 10;
  /** 笔顺播放速度。 */
  @Trace strokeSpeed: string = StrokeSpeedId.STANDARD;
  /** 全局隐藏拼音。 */
  @Trace hidePinyin: boolean = false;
  /** 系统语音朗读开关。 */
  @Trace ttsEnabled: boolean = true;
  /** 教材版本：'pep' | 'shanghai'。 */
}

/** 全局唯一设置实例。 */
export const appSettings: AppSettings = new AppSettings();
