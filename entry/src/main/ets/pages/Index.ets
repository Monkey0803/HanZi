/*
 * Index.ets — 应用外壳（组装 View 与 ViewModel）。
 *
 * 结构：Stack（纯白背景）→ HdsNavigation（HDS 标题栏 + 路由）→ HdsTabs（HDS 悬浮页签）
 *       → BooksTabView / ReviewTabView / SettingsTabView /（图片领域时）ImageTabView；防窥遮罩盖在内容之上、页签栏之下。
 * 全局沉浸：窗口层设白色背景兜底，根容器铺满白色，子页面背景透明；二级页用不透明白底避免推入残影。
 * 所有尺寸 / 颜色走 resources，逻辑常量走 common/constants。
 */

import { common } from '@kit.AbilityKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import {
  HdsTabs,
  HdsTabsController,
  HdsNavigation,
  HdsNavDestination,
  HdsNavigationTitleMode,
  HdsNavigationMenuContentOptions,
  HdsNavigationMenuItemOptions,
  HdsTabsFloatingStyle,
  HdsSideBar,
  HdsSideMenu,
  HdsSideMenuMainItem,
  SystemMaterialParams
} from '@kit.UIDesignKit';
import { appSettings } from '../model/AppSettings';
import { themePalette } from '../model/ThemePalette';
import { settingsViewModel } from '../viewmodel/SettingsViewModel';
import { customImmersiveViewModel } from '../viewmodel/CustomImmersiveViewModel';
import { antiPeep } from '../service/AntiPeep';
import { gripSensor } from '../service/GripSensor';
import { deviceService } from '../service/DeviceService';
import { scrollers } from '../service/ScrollerRegistry';
import { safeArea } from '../service/SafeAreaController';
import { CommonConstants } from '../common/constants/CommonConstants';
import { TabIndex } from '../common/constants/NavigationConstants';
import { RouterConstants } from '../common/constants/RouterConstants';
import { IMAGE_DOMAIN } from '../common/constants/DomainConstants';
import { indexDynamicHideParams, indexMaterialParams, indexTitleOptions } from './IndexTitleStyle';
import { BooksTabView } from '../views/books/BooksTabView';
import { BookDetailView } from '../views/books/BookDetailView';
import { LessonDetailView } from '../views/books/LessonDetailView';
import { CharDetailView } from '../views/char/CharDetailView';
import { PracticeView } from '../views/practice/PracticeView';
import { CatalogView } from '../views/catalog/CatalogView';
import { ReviewTabView } from '../views/review/ReviewTabView';
import { DetailPageView } from '../views/DetailPageView';
import { SettingsTabView } from '../views/SettingsTabView';
import { ImageTabView } from '../views/ImageTabView';
import { ImagePreviewView } from '../views/ImagePreviewView';
import { PrivacyVeil } from '../views/PrivacyVeil';
import { appBootstrap, BootstrapState } from '../service/AppBootstrap';
import { BookRouteParam, LessonRouteParam, CharRouteParam, PracticeRouteParam, CatalogRouteParam } from '../model/RouteParams';

@Entry
@ComponentV2
struct Index {
  @Local currentTab: number = CommonConstants.DEFAULT_TAB_INDEX;
  @Local navPathStack: NavPathStack = new NavPathStack();
  private tabsController: HdsTabsController = new HdsTabsController();

  aboutToAppear(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    settingsViewModel.init(context as common.Context);
    // 自定义沉浸光感：先按设备能力算一次，设置恢复完成后 SettingsViewModel 会再重算。
    customImmersiveViewModel.recompute();
    // 代码侧断点：宽屏（>= 840vp）用 HdsSideBar + 侧栏导航替换底部页签。
    // 由外壳单独持有订阅，子页面只读 deviceService.wide。
    deviceService.start(this.getUIContext());
    // 课程 / 笔顺数据启动加载（full → seed 回退）；失败时覆盖错误态并允许重试。
    if (context !== undefined) {
      appBootstrap.start(context);
    }
  }

  aboutToDisappear(): void {
    antiPeep.stop();
    gripSensor.stop();
    deviceService.stop();
  }

  /** 当前分区标题（底部页签与宽屏侧栏共用）。 */
  private currentTitle(): ResourceStr {
    if (this.currentTab === TabIndex.BOOKS) {
      return $r('app.string.books_title');
    }
    if (this.currentTab === TabIndex.REVIEW) {
      return $r('app.string.review_title');
    }
    if (this.currentTab === TabIndex.SETTINGS) {
      return $r('app.string.settings_title');
    }
    return $r('app.string.tab_images');
  }

  /** 首页标题栏右侧：查字（HM Symbol 搜索图标）。 */
  private titleMenu(): HdsNavigationMenuContentOptions | undefined {
    if (this.currentTab !== TabIndex.BOOKS) {
      return undefined;
    }
    const searchItem: HdsNavigationMenuItemOptions = {
      content: {
        icon: $r('sys.symbol.magnifyingglass'),
        label: $r('app.string.books_search'),
        action: (): void => {
          this.navPathStack.pushPathByName(RouterConstants.PAGE_CATALOG, new CatalogRouteParam(''));
        }
      }
    };
    const menu: HdsNavigationMenuContentOptions = { value: [searchItem] };
    return menu;
  }

  private floatingStyle(): HdsTabsFloatingStyle {
    const style: HdsTabsFloatingStyle = {
      // 悬浮页签栏默认贴底；全屏布局下会压住系统导航条，按避让高度上抬。
      barBottomMargin: safeArea.bottomInsetVp,
      adaptToHandedness: appSettings.gripEnabled,
      // 不使用 miniBar（迷你栏）：页签栏始终保持完整形态。
      // 去掉默认的整块浅灰蒙层，让白色背景直接透到屏幕底部。
      gradientMask: { maskColor: Color.Transparent }
    };
    // 标题栏与页签栏共用同一份 CustomPlan；L3 / 关闭时整体不下发。
    const effect: SystemMaterialParams | undefined = indexMaterialParams();
    if (effect !== undefined) {
      style.systemMaterialEffect = effect;
    }
    return style;
  }

  /** 交给 HdsNavigation 做滚动联动的控制器；图片页签未挂载时不绑定它。 */
  private boundScrollers(): Scroller[] {
    if (IMAGE_DOMAIN) {
      return [scrollers.home, scrollers.review, scrollers.settings, scrollers.images];
    }
    return [scrollers.home, scrollers.review, scrollers.settings];
  }

  /** 宽屏侧栏的导航项（与底部页签同源）。 */
  private railItems(): HdsSideMenuMainItem[] {
    const items: HdsSideMenuMainItem[] = [];
    items.push(new HdsSideMenuMainItem({
      itemId: 'books',
      label: $r('app.string.tab_books'),
      symbol: new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2')),
      action: () => {
        this.currentTab = TabIndex.BOOKS;
      }
    }));
    items.push(new HdsSideMenuMainItem({
      itemId: 'review',
      label: $r('app.string.tab_review'),
      symbol: new SymbolGlyphModifier($r('sys.symbol.checkmark_circle')),
      action: () => {
        this.currentTab = TabIndex.REVIEW;
      }
    }));
    items.push(new HdsSideMenuMainItem({
      itemId: 'settings',
      label: $r('app.string.tab_settings'),
      symbol: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
      action: () => {
        this.currentTab = TabIndex.SETTINGS;
      }
    }));
    if (IMAGE_DOMAIN) {
      items.push(new HdsSideMenuMainItem({
        itemId: 'images',
        label: $r('app.string.tab_images'),
        symbol: new SymbolGlyphModifier($r('sys.symbol.picture')),
        action: () => {
          this.currentTab = TabIndex.IMAGES;
        }
      }));
    }
    return items;
  }

  /** 各页签内容（底部页签外壳与宽屏侧栏外壳共用，避免重复声明）。 */
  @Builder
  booksContent() {
    BooksTabView({ navPathStack: this.navPathStack,
      underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR })
  }

  @Builder
  reviewContent() {
    ReviewTabView({ navPathStack: this.navPathStack,
      underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR })
  }

  @Builder
  settingsContent() {
    SettingsTabView({
      underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR
    })
  }

  @Builder
  imagesContent() {
    ImageTabView({
      underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR,
      navPathStack: this.navPathStack
    })
  }

  /** 窄屏外壳：HDS 悬浮底部页签。 */
  @Builder
  tabShell() {
    HdsTabs({ controller: this.tabsController, index: this.currentTab }) {
      TabContent() {
        this.booksContent()
      }
      .tabBar(this.barItem($r('sys.symbol.square_grid_2x2'), $r('app.string.tab_books'), TabIndex.BOOKS))

      TabContent() {
        this.reviewContent()
      }
      .tabBar(this.barItem($r('sys.symbol.checkmark_circle'), $r('app.string.tab_review'), TabIndex.REVIEW))

      TabContent() {
        this.settingsContent()
      }
      .tabBar(this.barItem($r('sys.symbol.gearshape'), $r('app.string.tab_settings'), TabIndex.SETTINGS))

      if (IMAGE_DOMAIN) {
        TabContent() {
          this.imagesContent()
        }
        .tabBar(this.barItem($r('sys.symbol.picture'), $r('app.string.tab_images'), TabIndex.IMAGES))
      }
    }
    .barPosition(BarPosition.End)
    // barOverlap(true)：页签栏模糊悬浮并叠在内容之上（沉浸式外观，配合 barFloatingStyle + 材质）。
    // 代价是内容会延伸到页签栏下方，所以各页滚动内容底部要用 tab_clearance 预留避让。
    .barOverlap(true)
    .vertical(false)
    .barFloatingStyle(this.floatingStyle())
    .onChange((index: number) => {
      this.currentTab = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.hm_page_transparent'))
  }

  /** 宽屏侧栏面板：HDS 侧边菜单。 */
  @Builder
  sideRail() {
    HdsSideMenu({
      items: this.railItems(),
      selectedIndex: this.currentTab,
      $selectedIndex: (index: number) => {
        this.currentTab = index;
      }
    })
  }

  /** 宽屏内容面板：只渲染当前分区（此时没有底部页签）。 */
  @Builder
  wideContent() {
    Column() {
      if (this.currentTab === TabIndex.BOOKS) {
        this.booksContent()
      } else if (this.currentTab === TabIndex.REVIEW) {
        this.reviewContent()
      } else if (this.currentTab === TabIndex.SETTINGS) {
        this.settingsContent()
      } else if (IMAGE_DOMAIN && this.currentTab === TabIndex.IMAGES) {
        this.imagesContent()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 宽屏外壳：HdsSideBar 左侧栏 + 右侧内容，替掉底部页签。 */
  @Builder
  wideShell() {
    HdsSideBar({
      isShowSideBar: true,
      sideBarContainerType: SideBarContainerType.Embed,
      sideBarPosition: SideBarPosition.Start,
      autoHide: false,
      minSideBarWidth: $r('app.float.rail_min_width'),
      maxSideBarWidth: $r('app.float.rail_max_width'),
      sideBarPanelBuilder: () => {
        this.sideRail();
      },
      contentPanelBuilder: () => {
        this.wideContent();
      }
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 底部页签项。
   *
   * 关键：@Builder 传入 ≥2 个参数时参数本身不触发动态刷新（见 SettingsRows 注释），
   * 所以这里只把「第几个页签」当参数，选中态在 builder 内部读 this.currentTab —— 只有这样，
   * onChange 更新 currentTab 时图标与文字颜色才会跟着重建。
   */
  @Builder
  barItem(icon: Resource, label: ResourceStr, index: number) {
    Column({ space: $r('app.float.space_xxs') }) {
      SymbolGlyph(icon)
        .fontSize($r('app.float.tab_icon_size'))
        .fontColor([this.currentTab === index ? themePalette.accent() : $r('app.color.hm_text_secondary')])
      Text(label)
        .fontSize($r('app.float.tab_font_size'))
        .fontColor(this.currentTab === index ? themePalette.accent() : $r('app.color.hm_text_secondary'))
    }
    .width('100%')
    .height($r('app.float.tab_item_height'))
    .justifyContent(FlexAlign.Center)
  }

  /** 全局背景图层：纯白背景铺满整个窗口（含状态栏 / 导航条区域）。 */
  @Builder
  BackgroundLayer() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.hm_page_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  pageMap(name: string, pageInfos: Object) {
    if (name === RouterConstants.PAGE_BOOK) {
      HdsNavDestination() {
        BookDetailView({
          bookId: (pageInfos as BookRouteParam).bookId,
          navPathStack: this.navPathStack,
          underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR
        })
      }
      .titleBar(indexTitleOptions($r('app.string.books_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_LESSON) {
      HdsNavDestination() {
        LessonDetailView({
          lessonId: (pageInfos as LessonRouteParam).lessonId,
          navPathStack: this.navPathStack,
          underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR
        })
      }
      .titleBar(indexTitleOptions($r('app.string.books_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_CHAR) {
      HdsNavDestination() {
        CharDetailView({
          char: (pageInfos as CharRouteParam).char,
          lessonId: (pageInfos as CharRouteParam).lessonId,
          navPathStack: this.navPathStack,
          underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR
        })
      }
      .titleBar(indexTitleOptions((pageInfos as CharRouteParam).char))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_PRACTICE) {
      HdsNavDestination() {
        PracticeView({
          char: (pageInfos as PracticeRouteParam).char,
          lessonId: (pageInfos as PracticeRouteParam).lessonId,
          underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR
        })
      }
      .titleBar(indexTitleOptions($r('app.string.practice_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_CATALOG) {
      HdsNavDestination() {
        CatalogView({
          navPathStack: this.navPathStack,
          underTitleBar: CommonConstants.CONTENT_UNDER_TITLE_BAR,
          initialQuery: (pageInfos as CatalogRouteParam).query
        })
      }
      .titleBar(indexTitleOptions($r('app.string.catalog_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_DETAIL) {
      HdsNavDestination() {
        DetailPageView({ navPathStack: this.navPathStack })
      }
      .titleBar(indexTitleOptions($r('app.string.detail_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    } else if (name === RouterConstants.PAGE_PREVIEW) {
      HdsNavDestination() {
        ImagePreviewView({ navPathStack: this.navPathStack })
      }
      .titleBar(indexTitleOptions($r('app.string.image_preview_title')))
      .dynamicHideTitleBar(indexDynamicHideParams())
      .backgroundColor($r('app.color.hm_page_background'))
    }
  }

  /** 启动数据加载失败时的兜底页：说明 + 重试。 */
  @Builder
  bootstrapErrorOverlay() {
    Column({ space: 16 }) {
      Text($r('app.string.bootstrap_error_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_primary'))
      Text(appBootstrap.errorMessage)
        .fontSize(14)
        .fontColor($r('app.color.hm_text_secondary'))
        .textAlign(TextAlign.Center)
      Button($r('app.string.bootstrap_retry'))
        .onClick(() => {
          const context: common.Context | undefined = this.getUIContext().getHostContext();
          if (context !== undefined) {
            appBootstrap.retry(context);
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.start_window_background'))
  }

  /** 启动数据加载中的占位：数据就绪后再挂载 HdsNavigation，避免首帧空列表。 */
  @Builder
  bootstrapLoadingOverlay() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(themePalette.accent())
      Text($r('app.string.bootstrap_loading'))
        .fontSize(14)
        .fontColor($r('app.color.hm_text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.start_window_background'))
  }

  build() {
    Stack() {
      this.BackgroundLayer()

      if (appBootstrap.state === BootstrapState.READY) {
        HdsNavigation(this.navPathStack) {
          // 窄屏：HDS 悬浮底部页签；宽屏（>= 840vp）：HdsSideBar 左侧栏替掉底部页签。
          if (deviceService.wide) {
            this.wideShell()
          } else {
            this.tabShell()
          }
        }
        .titleBar(indexTitleOptions(this.currentTitle(), this.titleMenu()))
        // 紧凑标题栏：FREE 大标题会与首屏占位重叠，模板统一使用 MINI。
        .titleMode(HdsNavigationTitleMode.MINI)
        .hideBackButton(true)
        // 标题栏 / 状态栏动态显隐：先声明 dynamicHideTitleBar，再 bindToScrollable（真机验证的顺序要求）。
        .dynamicHideTitleBar(indexDynamicHideParams())
        .mode(NavigationMode.Stack)
        .navDestination(this.pageMap)
        // 内容穿透标题栏：把各页滚动控制器交给 HdsNavigation，滚动时标题栏联动变模糊。
        .bindToScrollable(this.boundScrollers())
        // 自由多窗：标题栏隐藏后三键区下沉到页面，右侧留出三键宽度避免遮挡。
        .padding({ right: safeArea.freeWindow ? safeArea.titleButtonWidthVp : 0 })
        .width('100%')
        .height('100%')
      } else if (appBootstrap.state === BootstrapState.ERROR) {
        this.bootstrapErrorOverlay()
      } else {
        this.bootstrapLoadingOverlay()
      }

      if (antiPeep.peeking) {
        PrivacyVeil()
      }
    }
    .width('100%')
    .height('100%')
    // 全局纯白背景（与窗口层一致，含深浅色适配）。
    .backgroundColor($r('app.color.hm_page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
