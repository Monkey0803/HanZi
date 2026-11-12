/*
 * BooksTabView.ets — 课本页签（首页）。
 *
 * 今日学习卡片 + 12 册卡片；点击进入 BookDetailView。
 * 进度数据在 Phase 5 接入 ProgressStore，这里先显示册的字数统计。
 */

import { Book } from '../../model/CurriculumModels';
import { themePalette } from '../../model/ThemePalette';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { appBootstrap } from '../../service/AppBootstrap';
import { deviceService } from '../../service/DeviceService';
import { scrollers } from '../../service/ScrollerRegistry';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { BookRouteParam, LessonRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';

const CARD_HEIGHT: number = 120;
const CARD_GAP: number = 12;

@ComponentV2
export struct BooksTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  private totalChars(): number {
    let total: number = 0;
    const books: Book[] = curriculumRepository.books();
    for (let i = 0; i < books.length; i += 1) {
      total += books[i].charCount;
    }
    return total;
  }

  private modeLabel(): ResourceStr {
    return appBootstrap.dataMode === 'full'
      ? $r('app.string.books_mode_full')
      : $r('app.string.books_mode_seed');
  }

  private columns(): number {
    return deviceService.wide ? 4 : 2;
  }

  private gridHeight(): number {
    const count: number = curriculumRepository.books().length;
    const rows: number = Math.max(1, Math.ceil(count / this.columns()));
    return rows * CARD_HEIGHT + (rows - 1) * CARD_GAP;
  }

  private openFirstBook(): void {
    const books: Book[] = curriculumRepository.books();
    if (books.length === 0) {
      return;
    }
    const book: Book = books[0];
    this.navPathStack.pushPathByName(RouterConstants.PAGE_BOOK, new BookRouteParam(book.id));
  }

  private openBook(book: Book): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_BOOK, new BookRouteParam(book.id));
  }

  private openFirstLesson(book: Book): void {
    const units = curriculumRepository.unitsOfBook(book.id);
    if (units.length === 0 || units[0].lessons.length === 0) {
      return;
    }
    this.navPathStack.pushPathByName(RouterConstants.PAGE_LESSON,
      new LessonRouteParam(units[0].lessons[0].id));
  }

  @Builder
  todayCard() {
    Column({ space: $r('app.float.space_s') }) {
      Row() {
        Text($r('app.string.books_today_title'))
          .fontSize($r('app.float.font_size_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hm_text_primary'))
          .layoutWeight(1)
        Text(this.modeLabel())
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .padding({
            left: $r('app.float.space_s'),
            right: $r('app.float.space_s'),
            top: $r('app.float.space_xxs'),
            bottom: $r('app.float.space_xxs')
          })
          .backgroundColor($r('app.color.hm_divider'))
          .borderRadius($r('app.float.radius_chip'))
      }
      .width('100%')

      Text($r('app.string.books_progress', 0, this.totalChars()))
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_secondary'))
        .width('100%')

      Progress({ value: 0, total: Math.max(1, this.totalChars()), type: ProgressType.Linear })
        .width('100%')
        .color(themePalette.accent())

      Button($r('app.string.books_continue'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .fontColor($r('app.color.hm_on_brand'))
        .backgroundColor(themePalette.fill())
        .onClick(() => {
          this.openFirstBook();
        })
    }
    .width('100%')
    .padding($r('app.float.space_l'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.book_card_radius'))
  }

  @Builder
  bookCard(book: Book) {
    Column({ space: $r('app.float.space_xs') }) {
      Text(book.title)
        .fontSize($r('app.float.font_size_body'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text($r('app.string.books_lesson_count', book.lessonCount, book.charCount))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .maxLines(1)
      Blank()
      Progress({ value: 0, total: Math.max(1, book.charCount), type: ProgressType.Linear })
        .width('100%')
        .color(themePalette.accent())
    }
    .width('100%')
    .height(CARD_HEIGHT)
    .alignItems(HorizontalAlign.Start)
    .padding($r('app.float.space_m'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.book_card_radius'))
    .onClick(() => {
      this.openBook(book);
    })
  }

  build() {
    ResponsiveContent() {
      List({ scroller: scrollers.home }) {
        ListItem() {
          Column({ space: $r('app.float.space_l') }) {
            Row().width('100%')
              .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))
            this.todayCard()
            Row() {
              Text($r('app.string.books_title'))
                .fontSize($r('app.float.font_size_section'))
                .fontColor($r('app.color.hm_text_secondary'))
                .layoutWeight(1)
              Button($r('app.string.books_search'))
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .fontSize($r('app.float.font_size_caption'))
                .fontColor(themePalette.accent())
            }
            .width('100%')
          }
          .width('100%')
        }

        ListItem() {
          Grid() {
            ForEach(curriculumRepository.books(), (book: Book) => {
              GridItem() {
                this.bookCard(book)
              }
            }, (book: Book) => book.id)
          }
          .columnsTemplate(deviceService.wide ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
          .columnsGap(CARD_GAP)
          .rowsGap(CARD_GAP)
          .width('100%')
          .height(this.gridHeight())
          .margin({ top: $r('app.float.space_m') })
        }

        ListItem() {
          Row()
            .width('100%')
            .height(safeArea.contentBottomInsetVp)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      .scrollBar(BarState.Off)
    }
  }
}
