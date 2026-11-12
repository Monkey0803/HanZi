/*
 * PreferencesConstants.ets — 偏好库（@ohos.data.preferences）的库名与 key。
 *
 * key 是纯逻辑字符串，集中在这里，避免在读写两端各写一遍。
 */
export class PreferencesConstants {
  static readonly STORE_NAME: string = 'hds_app_settings_v1';
  static readonly KEY_THEME_MODE: string = 'themeMode';
  static readonly KEY_THEME_COLOR: string = 'themeColor';
  static readonly KEY_LANGUAGE_MODE: string = 'languageMode';
  static readonly KEY_MATERIAL_TYPE: string = 'materialType';
  static readonly KEY_MATERIAL_LEVEL: string = 'materialLevel';
  static readonly KEY_IMMERSIVE_ON: string = 'immersiveOn';
  static readonly KEY_LIGHT_EFFECT: string = 'lightEffectEnabled';
  static readonly KEY_GRIP_ENABLED: string = 'gripEnabled';
  static readonly KEY_ANTI_PEEP_ENABLED: string = 'antiPeepEnabled';
  static readonly KEY_STROKE_NUMBERS: string = 'strokeNumbers';
  static readonly KEY_GRID_STYLE: string = 'gridStyle';
  static readonly KEY_STROKE_SKELETON: string = 'strokeSkeleton';
  static readonly KEY_STROKE_STEPS: string = 'strokeSteps';
}
