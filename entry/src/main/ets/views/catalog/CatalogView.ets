/*
 * CatalogView.ets — 字表 / 查字。
 *
 * 支持按汉字、拼音、部首检索，按教材/通用与笔画数分段筛选；
 * 结果以字符格展示，点击进入字详情。
 */

import { CharacterEntry } from '../../model/CurriculumModels';
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
import { ResponsiveContent } from '../ResponsiveContent';

const LIST_SPACE: number = 8;

@ComponentV2
export struct CatalogView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = false;
  @Param initialQuery: string = '';

  @Local data: CatalogDataSource = new CatalogDataSource();

  aboutToAppear(): void {
    if (this.initialQuery.length > 0) {
      this.data.keyword = this.initialQuery;
    }
    this.data.reload();
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

  @Builder
  scopeMenu() {
    AppMenu(choiceMenu(CATALOG_SCOPE_OPTIONS, this.data.scope, (id: string) => {
      this.data.setScope(id);
    }))
  }

  @Builder
  bandMenu() {
    AppMenu(choiceMenu(CATALOG_BAND_OPTIONS, this.data.band, (id: string) => {
      this.data.setBand(id);
    }))
  }

  @Builder
  radicalMenu() {
    AppMenu(choiceMenu(this.data.radicalChoice(), this.data.radical, (id: string) => {
      this.data.setRadical(id);
    }))
  }

  @Builder
  filterChip(label: ResourceStr, type: string) {
    Text(label)
      .fontSize($r('app.float.font_size_caption'))
      .fontColor($r('app.color.hm_text_secondary'))
      .padding({
        left: $r('app.float.space_m'),
        right: $r('app.float.space_m'),
        top: $r('app.float.space_xs'),
        bottom: $r('app.float.space_xs')
      })
      .backgroundColor($r('app.color.hm_divider'))
      .borderRadius($r('app.float.radius_chip'))
      .bindMenu(type === 'scope' ? this.scopeMenu() : (type === 'band' ? this.bandMenu() : this.radicalMenu()),
        MaterialController.menuOptionsFor({ placement: Placement.BottomLeft }, appSettings.immersiveOn,
          appSettings.lightEffectEnabled))
  }

  @Builder
  charCell(entry: CharacterEntry) {
    Column({ space: $r('app.float.space_xxs') }) {
      Text(entry.char)
        .fontSize($r('app.float.font_size_title'))
        .fontColor($r('app.color.hanzi_ink'))
        .maxLines(1)
      Text(this.pinyinOf(entry))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height($r('app.float.row_height'))
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.radius_chip'))
    .onClick(() => {
      this.openChar(entry.char);
    })
  }

  build() {
    ResponsiveContent() {
      List({ space: LIST_SPACE }) {
        ListItem() {
          Row().width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))
        }

        ListItem() {
          TextInput({ text: this.data.keyword, placeholder: $r('app.string.catalog_search_hint') })
            .width('100%')
            .height($r('app.float.hanzi_cell_size'))
            .fontSize($r('app.float.font_size_body'))
            .backgroundColor($r('app.color.hanzi_card'))
            .borderRadius($r('app.float.radius_chip'))
            .onChange((value: string) => {
              this.data.setKeyword(value);
            })
        }

        ListItem() {
          Flex({ wrap: FlexWrap.Wrap }) {
            this.filterChip(CATALOG_SCOPE_OPTIONS.labelOf(this.data.scope), 'scope')
            this.filterChip(CATALOG_BAND_OPTIONS.labelOf(this.data.band), 'band')
            this.filterChip(this.data.radical.length > 0 ? this.data.radical : $r('app.string.catalog_radical_all'),
              'radical')
          }
          .width('100%')
        }

        ListItem() {
          Text($r('app.string.catalog_result_count', this.data.total))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
            .width('100%')
        }

        if (this.data.limitedData) {
          ListItem() {
            Text($r('app.string.catalog_seed_hint'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
          }
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
        } else {
          ListItem() {
            Grid() {
              ForEach(this.data.items, (entry: CharacterEntry) => {
                GridItem() {
                  this.charCell(entry)
                }
              }, (entry: CharacterEntry) => entry.char)
            }
            .columnsTemplate(this.columns())
            .columnsGap($r('app.float.space_s'))
            .rowsGap($r('app.float.space_s'))
            .width('100%')
          }

          if (this.data.hasMore()) {
            ListItem() {
              Button($r('app.string.char_more'))
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .fontColor(themePalette.accent())
                .width('100%')
                .onClick(() => {
                  this.data.loadMore();
                })
            }
          }
        }

        ListItem() {
          Row().width('100%').height(safeArea.contentBottomInsetVp)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      .scrollBar(BarState.Off)
    }
  }
}
