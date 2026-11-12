/*
 * DetailPageView.ets — 二级页（HdsNavDestination 内容），集中演示更多 HDS 组件：
 * - 自绘列表行（遵守纯 V2：不使用 V1 的 HdsListItem）；
 * - HdsActionBar (+ ActionBarButton / ActionBarStyle)：底部核心操作栏（含可展开主按钮）；
 * - HdsSnackBar：即时通知（由 service/NotificationService 封装）；
 * - HdsSideMenu：**宽屏**（>= 840vp）下用侧边菜单切分区，窄屏保持上下排布；
 * - 按压阴影 / 双边边缘流光；沉浸式系统材质（systemMaterial）不在内容区生效，
 *   示范放在底部页签栏（pages/Index.ets）与设置页菜单。
 */

import {
  HdsActionBar,
  ActionBarButton,
  ActionBarStyle,
  HdsSideMenu,
  HdsSideMenuMainItem,
  hdsEffect
} from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { appSettings } from '../model/AppSettings';
import { notificationService } from '../service/NotificationService';
import { gripSensor } from '../service/GripSensor';
import { deviceService } from '../service/DeviceService';
import { safeArea } from '../service/SafeAreaController';
import { ResponsiveContent } from './ResponsiveContent';

const SECTION_LIST: number = 0;
const SECTION_EFFECTS: number = 1;

@ComponentV2
export struct DetailPageView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  /** HdsActionBar 主按钮的展开态。 */
  @Local expanded: boolean = false;
  /** 宽屏侧边菜单当前分区。 */
  @Local section: number = SECTION_LIST;

  /** 分区一：自绘列表行（HdsListItem 是 V1 组件，本工程统一用 V2 自绘）。 */
  @Builder
  RowItem(icon: Resource, title: ResourceStr, subtitle: ResourceStr) {
    Row({ space: $r('app.float.space_m') }) {
      SymbolGlyph(icon)
        .fontSize($r('app.float.icon_size'))
        .fontColor([$r('app.color.hm_text_primary')])
      Column({ space: $r('app.float.space_xxs') }) {
        Text(title)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(subtitle)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([$r('app.color.hm_text_secondary')])
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    .backgroundColor($r('app.color.hm_card_background'))
    .borderRadius($r('app.float.radius_card'))
    .onClick(() => {
      this.notify($r('app.string.detail_snack_message'));
    })
  }

  /** 宽屏侧边菜单的分区项。 */
  private sideItems(): HdsSideMenuMainItem[] {
    const items: HdsSideMenuMainItem[] = [];
    items.push(new HdsSideMenuMainItem({
      itemId: 'list',
      label: $r('app.string.section_list'),
      symbol: new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2')),
      action: () => {
        this.section = SECTION_LIST;
      }
    }));
    items.push(new HdsSideMenuMainItem({
      itemId: 'effects',
      label: $r('app.string.section_effects'),
      symbol: new SymbolGlyphModifier($r('sys.symbol.rays')),
      action: () => {
        this.section = SECTION_EFFECTS;
      }
    }));
    return items;
  }

  private startButtons(): ActionBarButton[] {
    return [new ActionBarButton({ baseIcon: $r('sys.symbol.folder') })];
  }

  private endButtons(): ActionBarButton[] {
    return [new ActionBarButton({ baseIcon: $r('sys.symbol.share') })];
  }

  private primaryButton(): ActionBarButton {
    return new ActionBarButton({
      baseIcon: $r('sys.symbol.play_fill'),
      altIcon: $r('sys.symbol.pause_round_triangle_fill'),
      onClick: () => {
        this.expanded = !this.expanded;
      }
    });
  }

  private actionBarStyle(): ActionBarStyle {
    return new ActionBarStyle({ isPrimaryIconChanged: this.expanded });
  }

  private notify(message: ResourceStr): void {
    notificationService.show(this.getUIContext(), message);
  }

  /** 次操作按钮的按压阴影（hdsEffect pressShadow）。 */
  private pressShadowEffect(): VisualEffect {
    const effect: VisualEffect = new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .buildEffect();
    return effect;
  }

  /** 顶部装饰条的双边边缘流光（hdsEffect shaderEffect）。 */
  private flowLightEffect(): VisualEffect {
    const first: hdsEffect.EdgeFlowLightParam = {
      startPos: 0,
      endPos: 1.0,
      color: $r('app.color.hm_brand')
    };
    const second: hdsEffect.EdgeFlowLightParam = {
      startPos: 0.5,
      endPos: 1.5,
      color: $r('app.color.hm_brand')
    };
    const params: hdsEffect.DualEdgeFlowLightParam = {
      firstEdgeFlowLight: first,
      secondEdgeFlowLight: second
    };
    const animation: hdsEffect.AnimationParams = {
      duration: 4000,
      iterations: -1,
      autoPlay: appSettings.lightEffectEnabled
    };
    const shader: hdsEffect.ShaderEffectParams = {
      effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
      params: params,
      animation: animation
    };
    return new hdsEffect.HdsEffectBuilder().shaderEffect(shader).buildEffect();
  }

  /** 分区一：列表行。 */
  @Builder
  listSection() {
    Column({ space: $r('app.float.space_s') }) {
      this.RowItem($r('sys.symbol.house'), $r('app.string.tab_home'), $r('app.string.home_placeholder'))
      this.RowItem($r('sys.symbol.gearshape'), $r('app.string.tab_settings'), $r('app.string.detail_hint'))
    }
    .width('100%')
  }

  /** 分区二：视效与操作行。 */
  @Builder
  effectsSection() {
    Column({ space: $r('app.float.space_l') }) {
      // 双边边缘流光装饰条（hdsEffect shaderEffect）
      Column()
        .width('100%')
        .height($r('app.float.row_height'))
        .borderRadius($r('app.float.radius_card'))
        .backgroundColor($r('app.color.hm_effect_surface'))
        .visualEffect(this.flowLightEffect())

      // 操作行：智感握姿镜像 —— 左手握持时主操作移到拇指够得着的左侧
      Flex({
        direction: gripSensor.gripLeft ? FlexDirection.Row : FlexDirection.RowReverse,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        // 主操作：普通按钮（页面内容区**不是** systemMaterial 的生效区域）。
        // 组件级沉浸材质只在 Navigation/NavDestination 标题栏、底部 TabBar、弹窗类组件与接口、
        // Slider / Toggle / Select 上生效；挂在内容区不会报错也没有任何视觉效果，等于白设。
        // 通透镜的示范在「底部页签栏」（pages/Index.ets，底部 TabBar 生效区）与设置页的
        // bindMenu 菜单（弹窗生效区）。
        Button() {
          SymbolGlyph($r('sys.symbol.bolt'))
            .fontSize($r('app.float.icon_size'))
            .fontColor([$r('app.color.hm_brand')])
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor($r('app.color.hm_card_background'))
        .onClick(() => {
          notificationService.showWithAction(this.getUIContext(),
            $r('app.string.detail_snack_message'),
            $r('app.string.detail_snack_action'),
            () => {
              this.notify($r('app.string.detail_snack_action'));
            });
        })

        // 次操作：按压阴影（hdsEffect pressShadow）
        Button() {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize($r('app.float.icon_size'))
            .fontColor([$r('app.color.hm_text_primary')])
        }
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor($r('app.color.hm_card_background'))
        .visualEffect(this.pressShadowEffect())
        .onClick(() => {
          this.notify($r('app.string.detail_snack_message'));
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    ResponsiveContent() {
      Column({ space: $r('app.float.space_l') }) {
        // 透明标题栏占位：内容从标题栏下方开始，滚动/布局不压住标题。
        Row().width('100%').height(safeArea.contentTopInsetVp)
        Text($r('app.string.detail_hint'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))

        if (deviceService.wide) {
          // 宽屏（平板 / 横屏 / 折叠展开）：HdsSideMenu 侧边切换分区
          Row({ space: $r('app.float.space_l') }) {
            HdsSideMenu({
              items: this.sideItems(),
              selectedIndex: this.section,
              $selectedIndex: (index: number) => {
                this.section = index;
              }
            })

            Column({ space: $r('app.float.space_l') }) {
              if (this.section === SECTION_LIST) {
                this.listSection()
              } else {
                this.effectsSection()
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        } else {
          // 窄屏：上下排布
          this.listSection()
          this.effectsSection()
        }

        Blank()

        // HdsActionBar：底部核心操作栏（主按钮可展开）
        HdsActionBar({
          startButtons: this.startButtons(),
          endButtons: this.endButtons(),
          primaryButton: this.primaryButton(),
          actionBarStyle: this.actionBarStyle(),
          isExpand: this.expanded,
          $isExpand: (value: boolean) => {
            this.expanded = value;
          }
        })

        // 底部系统导航条避让：操作栏不压住手势条 / 三键导航。
        Row().width('100%').height(safeArea.bottomInsetVp)
      }
      .width('100%')
      .height('100%')
      .padding($r('app.float.space_l'))
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.hm_page_transparent'))
    }
  }
}
