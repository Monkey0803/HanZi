/*
 * IndexTitleStyle.ets — 全 App 共用的标题栏材质、滚动模糊与动态显隐配置。
 *
 * 外壳 HdsNavigation 与所有 HdsNavDestination 都使用同一套：
 * - 标题栏作为浮层（enableComponentSafeArea=false），自身避让系统状态栏（avoidLayoutSafeArea=true）；
 * - 静止态背景透明；滚动后露出半透明玻璃背板 + 模糊（材质不可用时补系统灰底，保证可读性）；
 * - 默认用 GRADIENT_BLUR（半透明 → 模糊）：IMMERSIVE_GRADIENT_BLUR 在浅色主题下会把标题文字与
 *   状态栏图标切成白色，浅色壁纸上不可读；深色 / 固定深色背景应用可按需替换。
 */

import {
  DynamicHideParams,
  HideMode,
  HdsNavigationMenuContentOptions,
  HdsNavigationTitleBarStyle,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  ScrollEffectOptions,
  ScrollEffectType,
  SystemMaterialParams,
  TitleBarContentOptions,
  TitleBarStyleOptions
} from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { appSettings } from '../model/AppSettings';
import { MaterialController } from '../service/MaterialController';
import { CommonConstants } from '../common/constants/CommonConstants';
import { customImmersiveViewModel } from '../viewmodel/CustomImmersiveViewModel';

/** 标题栏与底部页签共用的材质参数；L3 / 关闭时返回 undefined（整体不下发该字段）。 */
export function indexMaterialParams(): SystemMaterialParams | undefined {
  return MaterialController.paramsOfPlan(customImmersiveViewModel.plan, appSettings.materialType);
}

export function indexDynamicHideParams(): DynamicHideParams {
  const on: boolean = CommonConstants.CONTENT_UNDER_TITLE_BAR && CommonConstants.TITLE_BAR_DYNAMIC_HIDE;
  const params: DynamicHideParams = {
    hideTitleArea: on,
    hideStatusBar: on,
    hideBottomBuilder: false,
    mode: HideMode.SCROLL_UP_TO,
    hideOffset: CommonConstants.TITLE_BAR_HIDE_OFFSET_VP,
    hideRatio: CommonConstants.TITLE_BAR_HIDE_RATIO
  };
  return params;
}

function titleBackdropColor(): ResourceColor {
  return MaterialController.immersiveActive(appSettings.immersiveOn)
    ? $r('app.color.hm_title_backdrop')
    : $r('sys.color.comp_background_gray');
}

export function indexMaterialTitleStyle(): TitleBarStyleOptions {
  const backdrop: ResourceColor = titleBackdropColor();
  const original: HdsNavigationTitleBarStyle = {
    backgroundStyle: {
      backgroundColor: Color.Transparent,
      // 静止态不模糊：内容未滚动时标题栏必须完全通透，否则首屏内容会被糊掉一条。
      blurRadius: CommonConstants.TITLE_BAR_REST_BLUR_RADIUS
    }
  };
  const scrolled: HdsNavigationTitleBarStyle = {
    backgroundStyle: {
      backgroundColor: backdrop,
      blurRadius: CommonConstants.TITLE_BAR_BLUR_RADIUS
    }
  };
  const scrollEffectOpts: ScrollEffectOptions = {
    enableScrollEffect: CommonConstants.CONTENT_UNDER_TITLE_BAR,
    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
    blurEffectiveStartOffset: LengthMetrics.vp(CommonConstants.TITLE_BAR_BLUR_START_VP),
    blurEffectiveEndOffset: LengthMetrics.vp(CommonConstants.TITLE_BAR_BLUR_END_VP)
  };
  const style: TitleBarStyleOptions = {
    scrollEffectOpts: scrollEffectOpts,
    originalStyle: original,
    scrollEffectStyle: scrolled
  };
  // 关闭 / L3 时整体不下发 systemMaterialEffect（用 undefined 字段冒充关闭会失效）。
  const effect: SystemMaterialParams | undefined = indexMaterialParams();
  if (effect !== undefined) {
    style.systemMaterialEffect = effect;
  }
  return style;
}

export function indexTitleOptions(mainTitle: ResourceStr,
  menu?: HdsNavigationMenuContentOptions): HdsNavigationTitleBarOptions {
  const title: HdsNavigationTitle = { mainTitle: mainTitle };
  const content: TitleBarContentOptions = { title: title };
  if (menu !== undefined) {
    content.menu = menu;
  }
  const options: HdsNavigationTitleBarOptions = {
    avoidLayoutSafeArea: true,
    enableComponentSafeArea: false,
    content: content,
    style: indexMaterialTitleStyle()
  };
  return options;
}
