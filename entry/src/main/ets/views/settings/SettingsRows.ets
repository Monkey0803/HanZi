/*
 * SettingsRows.ets — 设置页（主页 + 各二级页）共用的行与小节标题（纯状态管理 V2）。
 *
 * 为什么行做成 @ComponentV2 而不是多参 @Builder：ArkUI 规定 @Builder 传入两个及以上参数时
 * 不触发动态刷新（官方文档「@Builder 参数传递规则」）。各行自己在 build() 里读 appSettings 的
 * @Trace 字段，选完值 / 拨完开关才会立刻反映到行文案上。
 *
 * 导航与动作都通过 @Event 上报，组件本身不持有 NavPathStack，便于在主页和二级页复用。
 */

import { appSettings } from '../../model/AppSettings';
import { ChoiceSet, THEME_OPTIONS } from '../../model/SettingsOptions';
import { MaterialController } from '../../service/MaterialController';
import { AppMenu } from '../../common/components/AppMenu';
import { choiceMenu } from '../../common/components/ChoiceMenu';
import { ChoiceValueChip } from '../../common/components/ChoiceField';
import { themePalette } from '../../model/ThemePalette';

/** 设置页每一行绑定到 appSettings 的哪个字段。 */
export enum SettingField {
  THEME = 'theme',
  MATERIAL_TYPE = 'materialType',
  MATERIAL_LEVEL = 'materialLevel',
  LANGUAGE = 'language',
  IMMERSIVE = 'immersive',
  LIGHT_EFFECT = 'lightEffect',
  GRIP = 'grip',
  ANTI_PEEP = 'antiPeep',
  SHOW_NUMBERS = 'showNumbers',
  SHOW_SKELETON = 'showSkeleton',
  SHOW_STEPS = 'showSteps',
  GRID_STYLE = 'gridStyle',
  HIDE_PINYIN = 'hidePinyin',
  STROKE_SPEED = 'strokeSpeed',
  DAILY_GOAL = 'dailyGoal',
  TTS = 'tts'
}

/** 行首图标 + 标题。纯静态内容，不随状态变化。 */
@ComponentV2
export struct SettingIconTitle {
  @Param icon: Resource = $r('sys.symbol.house');
  @Param title: ResourceStr = '';

  build() {
    Row({ space: $r('app.float.space_m') }) {
      SymbolGlyph(this.icon)
        .fontSize($r('app.float.icon_size'))
        .fontColor([themePalette.accent()])
      // 多语言长文案（德语尤其长）：标题让出空间并省略，避免把右侧取值 / 开关 / 箭头挤出屏幕。
      Text(this.title)
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
  }
}

/** 小节标题（卡片上方的小字）。 */
@ComponentV2
export struct SettingsSectionTitle {
  @Param title: ResourceStr = '';

  build() {
    Text(this.title)
      .fontSize($r('app.float.font_size_section'))
      .fontColor($r('app.color.hm_text_secondary'))
      .width('100%')
      .margin({ top: $r('app.float.space_xl'), bottom: $r('app.float.space_s'), left: $r('app.float.space_xs') })
  }
}

/** 下拉选项行：自己读 appSettings 的当前值并弹 Menu。 */
@ComponentV2
export struct OptionSelectRow {
  @Param icon: Resource = $r('sys.symbol.house');
  @Param title: ResourceStr = '';
  @Param choice: ChoiceSet = THEME_OPTIONS;
  @Param field: SettingField = SettingField.THEME;
  @Event onPick: (id: string) => void = () => {};

  /** 当前选中项 id。在 build 中被调用，所以本组件会随 @Trace 一起刷新。 */
  private currentId(): string {
    switch (this.field) {
      case SettingField.MATERIAL_TYPE:
        return appSettings.materialType;
      case SettingField.MATERIAL_LEVEL:
        return appSettings.materialLevel;
      case SettingField.LANGUAGE:
        return appSettings.languageMode;
      case SettingField.GRID_STYLE:
        return appSettings.gridStyle;
      case SettingField.STROKE_SPEED:
        return appSettings.strokeSpeed;
      case SettingField.DAILY_GOAL:
        return appSettings.dailyGoal.toString();
      default:
        return appSettings.themeMode;
    }
  }

  /**
   * 选项菜单：渲染统一走 AppMenu（圆角卡片 + 品牌色高亮块 + 分区/行分隔线），
   * 这里只把选项表折算成规格；菜单打开时现算，读到最新选中项。
   */
  @Builder
  OptionMenu() {
    AppMenu(choiceMenu(this.choice, this.currentId(), this.onPick));
  }

  build() {
    Row({ space: $r('app.float.space_s') }) {
      Row() {
        SettingIconTitle({ icon: this.icon, title: this.title })
      }
      .layoutWeight(1)
      // 当前值做成「胶囊底 + 实心倒三角」的取值控件（与系统设置页一致），样式见 ChoiceField。
      ChoiceValueChip({ label: this.choice.labelOf(this.currentId()) })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
    // 贴着被点的这一行弹出：右下对齐，从右侧的当前值 / 箭头下方展开。
    .bindMenu(this.OptionMenu(),
      MaterialController.menuOptionsFor({ placement: Placement.BottomRight }, appSettings.immersiveOn,
        appSettings.lightEffectEnabled))
  }
}

/** 布尔开关行：自己读 appSettings 的当前值。开启状态由 Toggle 自身表达，行不额外加背景块。 */
@ComponentV2
export struct SwitchSettingRow {
  @Param icon: Resource = $r('sys.symbol.house');
  @Param title: ResourceStr = '';
  @Param field: SettingField = SettingField.IMMERSIVE;
  @Event onToggle: (value: boolean) => void = () => {};

  private isOn(): boolean {
    switch (this.field) {
      case SettingField.LIGHT_EFFECT:
        return appSettings.lightEffectEnabled;
      case SettingField.GRIP:
        return appSettings.gripEnabled;
      case SettingField.ANTI_PEEP:
        return appSettings.antiPeepEnabled;
      case SettingField.SHOW_NUMBERS:
        return appSettings.showStrokeNumbers;
      case SettingField.SHOW_SKELETON:
        return appSettings.showSkeleton;
      case SettingField.SHOW_STEPS:
        return appSettings.showStrokeSteps;
      case SettingField.HIDE_PINYIN:
        return appSettings.hidePinyin;
      case SettingField.TTS:
        return appSettings.ttsEnabled;
      default:
        return appSettings.immersiveOn;
    }
  }

  build() {
    Row() {
      Row({ space: $r('app.float.space_s') }) {
        Row() {
          SettingIconTitle({ icon: this.icon, title: this.title })
        }
        .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.isOn() })
          .selectedColor(themePalette.fill())
          .onChange((value: boolean) => {
            this.onToggle(value);
          })
      }
      .width('100%')
      .height('100%')
      // 外层留 space_xs，这里补齐到 space_m，保证文字与选项行对齐。
      .padding({ left: $r('app.float.space_s'), right: $r('app.float.space_s') })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({
      left: $r('app.float.space_xs'),
      right: $r('app.float.space_xs'),
      top: $r('app.float.space_xs'),
      bottom: $r('app.float.space_xs')
    })
  }
}

/** 跳转行：右侧可选状态文案 + 右箭头。 */
@ComponentV2
export struct NavSettingRow {
  @Param icon: Resource = $r('sys.symbol.house');
  @Param title: ResourceStr = '';
  @Param detail: ResourceStr = '';
  /** 详情文案前是否显示一个色点（主题色行用）。 */
  @Param showDot: boolean = false;
  @Param dotColor: ResourceColor = themePalette.accent();
  @Event onOpen: () => void = () => {};

  build() {
    Row() {
      Row() {
        SettingIconTitle({ icon: this.icon, title: this.title })
      }
      .layoutWeight(1)
      if (this.showDot) {
        Row()
          .width($r('app.float.theme_color_dot_size'))
          .height($r('app.float.theme_color_dot_size'))
          .borderRadius($r('app.float.theme_color_dot_radius'))
          .backgroundColor(this.dotColor)
      }
      if (this.detail !== '') {
        Text(this.detail)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '40%' })
          .margin({ left: this.showDot ? $r('app.float.space_xs') : 0 })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([themePalette.accent()])
        .padding({ left: $r('app.float.space_xs') })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
    .onClick(() => {
      this.onOpen();
    })
  }
}

/** 动作行：执行一个就地操作（如清理缓存），右侧可选状态文案 + 右箭头。 */
@ComponentV2
export struct ActionSettingRow {
  @Param icon: Resource = $r('sys.symbol.house');
  @Param title: ResourceStr = '';
  @Param detail: ResourceStr = '';
  @Event onAction: () => void = () => {};

  build() {
    Row() {
      Row() {
        SettingIconTitle({ icon: this.icon, title: this.title })
      }
      .layoutWeight(1)
      if (this.detail !== '') {
        Text(this.detail)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '40%' })
      }
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([$r('app.color.hm_text_secondary')])
        .padding({ left: $r('app.float.space_xs') })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
    .onClick(() => {
      this.onAction();
    })
  }
}
