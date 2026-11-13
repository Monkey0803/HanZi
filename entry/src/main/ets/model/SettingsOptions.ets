/*
 * SettingsOptions.ets — 设置项选项表（ChoiceSet）。
 *
 * 每一项只存**语义 id**（来自 common/constants/SettingsConstants 的 enum，不是枚举数值）：
 * 状态文件可读，SDK 枚举重排也不会错位；读到旧值 / 脏值统一退回默认项。控件（下拉菜单）只认 label。
 */

import { ThemeMode, AppLanguage, MaterialKind, MaterialGrade } from '../common/constants/SettingsConstants';
import { CatalogScope, GridStyleId, StrokeBand, StrokeSpeedId } from '../common/constants/StrokeConstants';

/** 一个可选项：语义 id + 展示文案。 */
export class ChoiceOption {
  readonly id: string;
  readonly label: ResourceStr;

  constructor(id: string, label: ResourceStr) {
    this.id = id;
    this.label = label;
  }
}

/** 一张选项表：选项 + 默认项 + 归一 / 查下标 / 取文案。 */
export class ChoiceSet {
  readonly options: ChoiceOption[];
  readonly defaultValue: string;

  constructor(options: ChoiceOption[], defaultValue: string) {
    this.options = options;
    this.defaultValue = defaultValue;
  }

  /** 语义 id 在表里的下标；未知 id 返回默认项下标。 */
  indexOf(id: string): number {
    for (let i = 0; i < this.options.length; i += 1) {
      if (this.options[i].id === id) {
        return i;
      }
    }
    return this.indexOf(this.defaultValue);
  }

  /** 下标对应文案；越界退回默认项文案。 */
  labelAtIndex(index: number): ResourceStr {
    const safe: number = (index >= 0 && index < this.options.length) ? index : 0;
    return this.options[safe].label;
  }

  /** 语义 id 归一：认得出就保留，认不出退回默认项。 */
  normalize(id: string): string {
    for (let i = 0; i < this.options.length; i += 1) {
      if (this.options[i].id === id) {
        return id;
      }
    }
    return this.defaultValue;
  }

  /** 当前 id 对应的文案。 */
  labelOf(id: string): ResourceStr {
    return this.labelAtIndex(this.indexOf(id));
  }
}

/** 主题：跟随系统 / 浅色 / 深色。 */
export const THEME_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(ThemeMode.SYSTEM, $r('app.string.opt_follow_system')),
  new ChoiceOption(ThemeMode.LIGHT, $r('app.string.opt_light')),
  new ChoiceOption(ThemeMode.DARK, $r('app.string.opt_dark'))
], ThemeMode.SYSTEM);

/** 语言：跟随系统 / 简体中文 / 英语。 */
export const LANGUAGE_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(AppLanguage.SYSTEM, $r('app.string.opt_follow_system')),
  new ChoiceOption(AppLanguage.ZH, $r('app.string.opt_chinese')),
  new ChoiceOption(AppLanguage.EN, $r('app.string.opt_english'))
], AppLanguage.SYSTEM);

/** 材质类型：自适应 / 沉浸式 / 无材质效果（对应 hdsMaterial.MaterialType）。 */
export const MATERIAL_TYPE_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(MaterialKind.ADAPTIVE, $r('app.string.opt_material_adaptive')),
  new ChoiceOption(MaterialKind.IMMERSIVE, $r('app.string.opt_material_immersive')),
  new ChoiceOption(MaterialKind.NONE, $r('app.string.opt_material_none'))
], MaterialKind.ADAPTIVE);

/** 沉浸光感材质：四档（对应 hdsMaterial.MaterialLevel）。 */
export const MATERIAL_LEVEL_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(MaterialGrade.EXQUISITE, $r('app.string.opt_level_exquisite')),
  new ChoiceOption(MaterialGrade.GENTLE, $r('app.string.opt_level_gentle')),
  new ChoiceOption(MaterialGrade.SMOOTH, $r('app.string.opt_level_smooth')),
  new ChoiceOption(MaterialGrade.ADAPTIVE, $r('app.string.opt_level_adaptive'))
], MaterialGrade.ADAPTIVE);

/** 字格样式：田字格 / 米字格 / 九宫格 / 无格。 */
export const GRID_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(GridStyleId.TIAN, $r('app.string.opt_grid_tian')),
  new ChoiceOption(GridStyleId.MI, $r('app.string.opt_grid_mi')),
  new ChoiceOption(GridStyleId.NINE, $r('app.string.opt_grid_nine')),
  new ChoiceOption(GridStyleId.NONE, $r('app.string.opt_grid_none'))
], GridStyleId.TIAN);

/** 字表口径：全部 / 教材字 / 通用字。 */
export const CATALOG_SCOPE_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(CatalogScope.ALL, $r('app.string.catalog_scope_all')),
  new ChoiceOption(CatalogScope.CURRICULUM, $r('app.string.catalog_scope_curriculum')),
  new ChoiceOption(CatalogScope.COMMON, $r('app.string.catalog_scope_common'))
], CatalogScope.ALL);

/** 字表笔画分段。 */
export const CATALOG_BAND_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(StrokeBand.ALL, $r('app.string.catalog_band_all')),
  new ChoiceOption(StrokeBand.B1, $r('app.string.catalog_band_1_4')),
  new ChoiceOption(StrokeBand.B2, $r('app.string.catalog_band_5_8')),
  new ChoiceOption(StrokeBand.B3, $r('app.string.catalog_band_9_12')),
  new ChoiceOption(StrokeBand.B4, $r('app.string.catalog_band_13_plus'))
], StrokeBand.ALL);

export const DAILY_GOAL_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption('5', $r('app.string.opt_daily_goal_5')),
  new ChoiceOption('10', $r('app.string.opt_daily_goal_10')),
  new ChoiceOption('15', $r('app.string.opt_daily_goal_15')),
  new ChoiceOption('20', $r('app.string.opt_daily_goal_20'))
], '10');

export const STROKE_SPEED_OPTIONS: ChoiceSet = new ChoiceSet([
  new ChoiceOption(StrokeSpeedId.SLOW, $r('app.string.opt_stroke_speed_slow')),
  new ChoiceOption(StrokeSpeedId.STANDARD, $r('app.string.opt_stroke_speed_standard')),
  new ChoiceOption(StrokeSpeedId.FAST, $r('app.string.opt_stroke_speed_fast'))
], StrokeSpeedId.STANDARD);
