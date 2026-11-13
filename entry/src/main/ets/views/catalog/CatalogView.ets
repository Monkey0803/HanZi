/*
 * CatalogView.ets — 字表 / 查字。
 *
 * 默认按部首分组浏览，可切换拼音 / 笔画；系统 AlphabetIndexer 与吸顶分组头
 * 双向同步。搜索时切换为扁平结果，清空后恢复搜索前的分组位置。
 */

import { CharacterEntry } from '../../model/CurriculumModels';
import { CatalogBrowseMode, CatalogGridRow, CatalogGroup } from '../../model/CatalogModels';
import { CATALOG_BAND_OPTIONS, CATALOG_SCOPE_OPTIONS } from '../../model/SettingsOptions';
import { appSettings } from '../../model/AppSettings';
import { MaterialController } from '../../service/MaterialController';
import { deviceService } from '../../service/DeviceService';
import { safeArea } from '../../service/SafeAreaController';
import { themePalette } from '../../model/ThemePalette';
import { CatalogDataSource } from '../../viewmodel/CatalogDataSource';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { CharRouteParam } from '../../model/RouteParams';
import { AppMenu } from '../../common/components/AppMenu';
import { choiceMenu } from '../../common/components/ChoiceMenu';
import { ChoiceValueChip } from '../../common/components/ChoiceField';
import { AppSheet } from '../../common/components/AppSheet';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';

/** 顶部固定两项：标题栏占位、搜索/模式/摘要控件组。 */
const GROUP_LIST_OFFSET: number = 2;
/** List / ListItemGroup 的 space 只接受 number|string，无法直接传 Resource。 */
const LIST_SPACE: number = 8;

@Builder
function emptyFilterMenu() {
}

/** 筛选面板的取值行：用 V2 @Param 保证菜单选择后当前值立即刷新。 */
@ComponentV2
struct CatalogFilterSelectRow {
  @Param title: ResourceStr = '';
  @Param value: ResourceStr = '';
  @BuilderParam menu: () => void = emptyFilterMenu;

  build() {
    Row({ space: $r('app.float.space_s') }) {
      Text(this.title)
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_primary'))
        .layoutWeight(1)
      ChoiceValueChip({ label: this.value })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
    .bindMenu(this.menu(),
      MaterialController.menuOptionsFor({ placement: Placement.BottomRight }, appSettings.immersiveOn,
        appSettings.lightEffectEnabled))
  }
}

@ComponentV2
export struct CatalogView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = false;
  @Param initialQuery: string = '';

  @Local data: CatalogDataSource = new CatalogDataSource();
  @Local showFilter: boolean = false;
  @Local indexControlsHeight: number = 0;
  private listScroller: Scroller = new Scroller();
  private restoreTimer: number = -1;

  aboutToAppear(): void {
    if (this.initialQuery.length > 0) {
      this.data.keyword = this.initialQuery;
    }
    this.data.reload();
  }

  aboutToDisappear(): void {
    if (this.restoreTimer >= 0) {
      clearTimeout(this.restoreTimer);
      this.restoreTimer = -1;
    }
  }

  private openChar(char: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR, new CharRouteParam(char, '', false));
  }

  private pinyinOf(entry: CharacterEntry): string {
    return entry.pinyins.length > 0 ? entry.pinyins[0] : '';
  }

  private columns(): string {
    return deviceService.wide ? '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr' : '1fr 1fr 1fr 1fr 1fr';
  }

  private rowsOf(group: CatalogGroup): CatalogGridRow[] {
    return deviceService.wide ? group.wideRows : group.narrowRows;
  }

  private modeLabel(mode: CatalogBrowseMode): ResourceStr {
    if (mode === CatalogBrowseMode.PINYIN) {
      return $r('app.string.catalog_mode_pinyin');
    }
    if (mode === CatalogBrowseMode.STROKE) {
      return $r('app.string.catalog_mode_stroke');
    }
    return $r('app.string.catalog_mode_radical');
  }

  private groupTitle(group: CatalogGroup): ResourceStr {
    if (group.key === '#') {
      return $r('app.string.catalog_group_other', group.entries.length);
    }
    if (this.data.browseMode === CatalogBrowseMode.PINYIN) {
      return $r('app.string.catalog_group_pinyin', group.displayTitle, group.entries.length);
    }
    if (this.data.browseMode === CatalogBrowseMode.STROKE) {
      return $r('app.string.catalog_group_stroke', group.displayTitle, group.entries.length);
    }
    return $r('app.string.catalog_group_radical', group.displayTitle, group.entries.length);
  }

  private charA11y(entry: CharacterEntry): Resource {
    return $r('app.string.catalog_char_a11y', entry.char, this.pinyinOf(entry), entry.radical, entry.strokeCount);
  }

  private scrollToGroup(index: number, smooth: boolean = true): void {
    if (index < 0 || index >= this.data.groups.length) {
      return;
    }
    this.data.selectedGroupIndex = index;
    this.listScroller.scrollToIndex(GROUP_LIST_OFFSET + index, smooth, ScrollAlign.START);
  }

  private scheduleBrowseRestore(): void {
    if (this.restoreTimer >= 0) {
      clearTimeout(this.restoreTimer);
    }
    this.restoreTimer = setTimeout(() => {
      this.scrollToGroup(this.data.selectedGroupIndex, false);
      this.restoreTimer = -1;
    }, 0);
  }

  private onListIndexChange(start: number): void {
    if (this.data.searching() || start < GROUP_LIST_OFFSET || this.data.groups.length === 0) {
      return;
    }
    this.data.selectedGroupIndex = Math.min(start - GROUP_LIST_OFFSET, this.data.groups.length - 1);
  }

  @Builder
  scopeMenu() {
    AppMenu(choiceMenu(CATALOG_SCOPE_OPTIONS, this.data.scope, (id: string) => {
      this.data.setScope(id);
      this.scheduleBrowseRestore();
    }))
  }

  @Builder
  bandMenu() {
    AppMenu(choiceMenu(CATALOG_BAND_OPTIONS, this.data.band, (id: string) => {
      this.data.setBand(id);
      this.scheduleBrowseRestore();
    }))
  }

  @Builder
  radicalMenu() {
    AppMenu(choiceMenu(this.data.radicalChoice(), this.data.radical, (id: string) => {
      this.data.setRadical(id);
      this.scheduleBrowseRestore();
    }))
  }

  @Builder
  modeButton(mode: CatalogBrowseMode) {
    Text(this.modeLabel(mode))
      .fontSize($r('app.float.font_size_caption'))
      .fontWeight(this.data.browseMode === mode ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.data.browseMode === mode
        ? $r('app.color.hm_on_brand')
        : $r('app.color.hm_text_secondary'))
      .height($r('app.float.value_chip_height'))
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.data.browseMode === mode
        ? themePalette.fill()
        : $r('app.color.hm_page_transparent'))
      .borderRadius($r('app.float.catalog_cell_radius'))
      .accessibilitySelected(this.data.browseMode === mode)
      .onClick(() => {
        this.data.setBrowseMode(mode);
        this.scheduleBrowseRestore();
      })
  }

  @Builder
  browseModeBar() {
    Row({ space: $r('app.float.space_xs') }) {
      this.modeButton(CatalogBrowseMode.RADICAL)
      this.modeButton(CatalogBrowseMode.PINYIN)
      this.modeButton(CatalogBrowseMode.STROKE)
    }
    .width('100%')
    .height($r('app.float.action_button_height'))
    .padding($r('app.float.space_xs'))
    .backgroundColor($r('app.color.hm_divider'))
    .borderRadius($r('app.float.radius_chip'))
  }

  @Builder
  filterButton() {
    Row({ space: $r('app.float.space_xs') }) {
      SymbolGlyph($r('sys.symbol.slider_horizontal_2'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([themePalette.accent()])
      Text($r('app.string.catalog_filter'))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_primary'))
      if (this.data.activeFilterCount() > 0) {
        Text(this.data.activeFilterCount().toString())
          .fontSize($r('app.float.tab_font_size'))
          .fontColor($r('app.color.hm_on_brand'))
          .width($r('app.float.catalog_filter_badge_size'))
          .height($r('app.float.catalog_filter_badge_size'))
          .textAlign(TextAlign.Center)
          .backgroundColor(themePalette.fill())
          .borderRadius($r('app.float.radius_chip'))
      }
    }
    .height($r('app.float.action_button_height'))
    .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
    .backgroundColor(this.data.activeFilterCount() > 0 ? themePalette.tint() : $r('app.color.hm_divider'))
    .borderRadius($r('app.float.radius_chip'))
    .accessibilityText($r('app.string.catalog_filter'))
    .onClick(() => {
      this.showFilter = true;
    })
  }

  @Builder
  resultSummary() {
    Column({ space: $r('app.float.space_xxs') }) {
      Row() {
        Text($r('app.string.catalog_result_count', this.data.total))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .layoutWeight(1)
        this.filterButton()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      if (this.data.limitedData) {
        Text($r('app.string.catalog_seed_hint'))
          .fontSize($r('app.float.tab_font_size'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  catalogControls() {
    Column({ space: LIST_SPACE }) {
      Search({ value: this.data.keyword, placeholder: $r('app.string.catalog_search_hint') })
        .width('100%')
        .height($r('app.float.hanzi_cell_size'))
        .textFont({ size: $r('app.float.font_size_body') })
        .fontColor($r('app.color.hm_text_primary'))
        .placeholderColor($r('app.color.hm_text_secondary'))
        .cancelButton({ style: CancelButtonStyle.INPUT })
        .backgroundColor($r('app.color.hanzi_card'))
        .borderRadius($r('app.float.radius_chip'))
        .onChange((value: string) => {
          const wasSearching: boolean = this.data.searching();
          this.data.setKeyword(value);
          if (wasSearching && !this.data.searching()) {
            this.scheduleBrowseRestore();
          }
        })
      this.browseModeBar()
      this.resultSummary()
    }
    .width('100%')
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const measuredHeight: number = Number.parseFloat(String(newArea.height));
      if (measuredHeight > 0) {
        this.indexControlsHeight = measuredHeight + LIST_SPACE * 2;
      }
    })
  }

  @Builder
  charCell(entry: CharacterEntry) {
    Column({ space: $r('app.float.space_xxs') }) {
      Text(entry.char)
        .fontSize($r('app.float.font_size_title'))
        .fontColor($r('app.color.hanzi_ink'))
        .maxLines(1)
      if (this.data.showPinyin) {
        Text(this.pinyinOf(entry))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .justifyContent(FlexAlign.Center)
    .borderRadius($r('app.float.catalog_cell_radius'))
    .stateStyles({
      pressed: {
        .backgroundColor(themePalette.tint())
      },
      normal: {
        .backgroundColor($r('app.color.hanzi_card'))
      }
    })
    .accessibilityText(this.charA11y(entry))
    .onClick(() => {
      this.openChar(entry.char);
    })
  }

  @Builder
  gridRow(row: CatalogGridRow) {
    Grid() {
      ForEach(row.entries, (entry: CharacterEntry) => {
        GridItem() {
          this.charCell(entry)
        }
      }, (entry: CharacterEntry) => entry.char)
    }
    .columnsTemplate(this.columns())
    .columnsGap($r('app.float.space_s'))
    .width('100%')
    .height($r('app.float.row_height'))
    .padding({ right: this.data.searching() ? 0 : $r('app.float.catalog_index_width') })
  }

  @Builder
  groupHeader(group: CatalogGroup) {
    Row() {
      Text(this.groupTitle(group))
        .fontSize($r('app.float.font_size_section'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height($r('app.float.catalog_group_header_height'))
    .padding({ right: $r('app.float.catalog_index_width') })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.hm_page_background'))
  }

  @Builder
  catalogList() {
    List({ space: LIST_SPACE, scroller: this.listScroller }) {
      ListItem() {
        PageTopSpacer({ underTitleBar: this.underTitleBar })
      }

      ListItem() {
        this.catalogControls()
      }

      if (this.data.items.length === 0) {
        ListItem() {
          Text($r('app.string.catalog_empty'))
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding($r('app.float.space_xl'))
        }
      } else if (this.data.searching()) {
        Repeat<CatalogGridRow>(this.data.searchRows(deviceService.wide))
          .each((repeatItem: RepeatItem<CatalogGridRow>) => {
          ListItem() {
            this.gridRow(repeatItem.item)
          }
          })
          .key((row: CatalogGridRow) => row.id)
          .virtualScroll()
      } else {
        ForEach(this.data.groups, (group: CatalogGroup) => {
          ListItemGroup({ header: this.groupHeader(group), space: LIST_SPACE }) {
            Repeat<CatalogGridRow>(this.rowsOf(group))
              .each((repeatItem: RepeatItem<CatalogGridRow>) => {
              ListItem() {
                this.gridRow(repeatItem.item)
              }
              })
              .key((row: CatalogGridRow) => row.id)
              .virtualScroll()
          }
        }, (group: CatalogGroup) => group.key)
      }

      ListItem() {
        Row().width('100%').height(safeArea.contentBottomInsetVp)
      }
    }
    .sticky(StickyStyle.Header)
    .cachedCount(GROUP_LIST_OFFSET)
    .width('100%')
    .height('100%')
    .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    .scrollBar(BarState.Off)
    .onScrollIndex((start: number, _end: number) => {
      this.onListIndexChange(start);
    })
  }

  @Builder
  indexOverlay() {
    Column() {
      PageTopSpacer({ underTitleBar: this.underTitleBar })
      Row()
        .height(this.indexControlsHeight)
      AlphabetIndexer({
        arrayValue: this.data.indexLabels(),
        selected: this.data.selectedGroupIndex
      })
        .width($r('app.float.catalog_index_width'))
        .layoutWeight(1)
        .color($r('app.color.hm_text_secondary'))
        .selectedColor(themePalette.accent())
        .popupColor($r('app.color.hm_text_primary'))
        .selectedBackgroundColor(themePalette.tint())
        .popupBackground($r('app.color.hanzi_card'))
        .usingPopup(true)
        .autoCollapse(true)
        .enableHapticFeedback(false)
        .onSelect((index: number) => {
          this.scrollToGroup(index);
        })
      Row()
        .height(safeArea.contentBottomInsetVp)
    }
    .width($r('app.float.catalog_index_width'))
    .height('100%')
  }

  @Builder
  filterSheet() {
    Column({ space: $r('app.float.space_m') }) {
      Row() {
        Text($r('app.string.catalog_filter_title'))
          .fontSize($r('app.float.font_size_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hm_text_primary'))
          .layoutWeight(1)
        Button($r('app.string.catalog_filter_reset'))
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .fontColor(themePalette.accent())
          .onClick(() => {
            this.data.resetFilters();
            this.scheduleBrowseRestore();
          })
      }
      .width('100%')

      Column() {
        CatalogFilterSelectRow({
          title: $r('app.string.catalog_scope'),
          value: CATALOG_SCOPE_OPTIONS.labelOf(this.data.scope)
        }) {
          this.scopeMenu()
        }
        Divider().color($r('app.color.hm_divider'))
        CatalogFilterSelectRow({
          title: $r('app.string.catalog_stroke_band'),
          value: CATALOG_BAND_OPTIONS.labelOf(this.data.band)
        }) {
          this.bandMenu()
        }
        Divider().color($r('app.color.hm_divider'))
        CatalogFilterSelectRow({
          title: $r('app.string.catalog_radical'),
          value: this.data.radical.length > 0 ? this.data.radical : $r('app.string.catalog_radical_all')
        }) {
          this.radicalMenu()
        }
        Divider().color($r('app.color.hm_divider'))
        Row() {
          Text($r('app.string.catalog_show_pinyin'))
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.data.showPinyin })
            .selectedColor(themePalette.fill())
            .onChange((value: boolean) => {
              this.data.setShowPinyin(value);
            })
        }
        .width('100%')
        .height($r('app.float.row_height'))
        .padding({ left: $r('app.float.space_m'), right: $r('app.float.space_m') })
      }
      .width('100%')
      .backgroundColor($r('app.color.hm_card_background'))
      .borderRadius($r('app.float.radius_card'))

      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({
      left: $r('app.float.space_l'),
      right: $r('app.float.space_l'),
      top: $r('app.float.space_m'),
      bottom: $r('app.float.space_m')
    })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Stack() {
      ResponsiveContent() {
        Stack({ alignContent: Alignment.TopEnd }) {
          this.catalogList()
          if (!this.data.searching() && this.data.groups.length > 0 && this.indexControlsHeight > 0) {
            this.indexOverlay()
          }
        }
        .width('100%')
        .height('100%')
      }

      AppSheet({
        visible: this.showFilter,
        initialSize: SheetSize.MEDIUM,
        onDismiss: () => {
          this.showFilter = false;
        }
      }) {
        this.filterSheet()
      }
    }
    .width('100%')
    .height('100%')
  }
}
