/* MistakeBookView.ets — 完整错题本与错题复习入口。 */

import { CharacterEntry, Lesson } from '../../model/CurriculumModels';
import { CharRouteParam, ReviewMode, ReviewRouteParam } from '../../model/RouteParams';
import { ReviewCardMode, ReviewConstants } from '../../common/constants/ReviewConstants';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { progressStore } from '../../service/ProgressStore';
import { safeArea } from '../../service/SafeAreaController';
import { themePalette } from '../../model/ThemePalette';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';
import { HanziGridCell } from '../books/HanziGridCell';

const CELL_SIZE: number = 52;

@ComponentV2
export struct MistakeBookView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  private pinyinOf(char: string): string {
    const entry: CharacterEntry | undefined = curriculumRepository.character(char);
    return entry !== undefined && entry.pinyins.length > 0 ? entry.pinyins[0] : '';
  }

  private lessonTitleOf(char: string): string {
    const lesson: Lesson | undefined = curriculumRepository.lesson(progressStore.lessonOf(char));
    return lesson !== undefined ? lesson.title : '';
  }

  private openChar(char: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR,
      new CharRouteParam(char, progressStore.lessonOf(char)));
  }

  private startReview(): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_REVIEW_SESSION,
      new ReviewRouteParam(ReviewMode.MISTAKE, '', 0, ReviewConstants.MAX_LIMIT, ReviewCardMode.CHAR));
  }

  @Builder
  mistakeRow(char: string, index: number) {
    Column() {
      if (index > 0) {
        Divider().color($r('app.color.hm_divider'))
      }
      Row({ space: $r('app.float.space_m') }) {
        HanziGridCell({ char: char, cellSize: CELL_SIZE })
        Column({ space: $r('app.float.space_xxs') }) {
          Text(this.pinyinOf(char))
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
          if (this.lessonTitleOf(char).length > 0) {
            Text(this.lessonTitleOf(char))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text($r('app.string.mistake_count', progressStore.mistakeOf(char)))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hanzi_error'))
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize($r('app.float.icon_size_small'))
          .fontColor([$r('app.color.hm_text_secondary')])
      }
      .width('100%')
      .padding($r('app.float.space_m'))
      .onClick(() => {
        this.openChar(char);
      })
    }
    .width('100%')
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column({ space: $r('app.float.space_l') }) {
          PageTopSpacer({ underTitleBar: this.underTitleBar })
          if (progressStore.mistakeChars.length === 0) {
            Text($r('app.string.review_mistakes_empty'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding($r('app.float.space_xl'))
          } else {
            Column() {
              ForEach(progressStore.mistakeChars, (char: string, index: number) => {
                this.mistakeRow(char, index)
              }, (char: string) => char)
            }
            .width('100%')
            .backgroundColor($r('app.color.hm_card_background'))
            .borderRadius($r('app.float.radius_card'))
            .clip(true)
            Button($r('app.string.mistake_review_start'))
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .backgroundColor(themePalette.fill())
              .fontColor($r('app.color.hm_on_brand'))
              .width('100%')
              .onClick(() => {
                this.startReview();
              })
          }
          Blank().height(safeArea.contentBottomInsetVp)
        }
        .width('100%')
        .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
  }
}
