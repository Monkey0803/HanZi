/*
 * BooksTabView.ets — 课本页签（首页，水墨卷轴风）。
 *
 * 结构：纸色底层（渐变 + 两团低透明度墨晕）→
 *   今日学习卡（每日一字 + 进度 + 继续学习）、分区头（课本 · 查字）、12 册卷轴册签。
 * 每日一字来自 DailyCharService（同一天稳定、跨天轮换），点「看这个字」进字详情。
 * 进度数据在 Phase 5 接入 ProgressStore，这里先显示册的字数统计。
 */

import { Book } from '../../model/CurriculumModels';
import { themePalette } from '../../model/ThemePalette';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { appBootstrap } from '../../service/AppBootstrap';
import { deviceService } from '../../service/DeviceService';
import { dailyCharService, DailyChar } from '../../service/DailyCharService';
import { scrollers } from '../../service/ScrollerRegistry';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { gradeGlyphOf } from '../../common/constants/CurriculumConstants';
import { BookRouteParam, CharRouteParam, LessonRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';
import { PaperBackground } from '../PaperBackground';
import { HanziGridCell } from './HanziGridCell';
import { InkCard } from './InkCard';

const CARD_HEIGHT: number = 108;
const CARD_GAP: number = 12;
const HERO_TILE: number = 96;
const CARD_TILE: number = 44;

@ComponentV2
export struct BooksTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  /** 每日一字可能尚未就绪（数据加载中）；未就绪时返回空对象，由 hasDaily() 控制渲染。 */
  private daily(): DailyChar {
    const value: DailyChar | undefined = dailyCharService.current();
    return value !== undefined ? value : new DailyChar();
  }

  private hasDaily(): boolean {
    return dailyCharService.current() !== undefined;
  }

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

  private termLabel(book: Book): ResourceStr {
    return book.term === 1 ? $r('app.string.books_term_up') : $r('app.string.books_term_down');
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

  private openDailyChar(daily: DailyChar): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR,
      new CharRouteParam(daily.char, daily.lessonId));
  }

  /** 每日一字的文字信息块：拼音、部首·笔画、组词、出处。 */
  @Builder
  dailyInfo(daily: DailyChar) {
    Column({ space: $r('app.float.space_xs') }) {
      Text(daily.pinyin)
        .fontSize($r('app.float.font_size_title'))
        .fontWeight(FontWeight.Medium)
        .fontColor(themePalette.accent())
      Row({ space: $r('app.float.space_xs') }) {
        Text($r('app.string.books_daily_stroke', daily.strokeCount))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
        if (daily.radical.length > 0) {
          Text(daily.radical)
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
            .padding({
              left: $r('app.float.space_xs'),
              right: $r('app.float.space_xs'),
              top: $r('app.float.space_xxs'),
              bottom: $r('app.float.space_xxs')
            })
            .backgroundColor($r('app.color.hm_divider'))
            .borderRadius($r('app.float.space_xs'))
        }
      }
      if (daily.word.length > 0) {
        Text(daily.word)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
      }
      if (daily.bookTitle.length > 0) {
        Text($r('app.string.books_daily_from', daily.bookTitle))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  todayCard() {
    InkCard() {
      Column({ space: $r('app.float.space_m') }) {
        Row({ space: $r('app.float.space_s') }) {
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

        if (this.hasDaily()) {
          Row({ space: $r('app.float.space_m') }) {
            HanziGridCell({ char: this.daily().char, cellSize: HERO_TILE })
            this.dailyInfo(this.daily())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        Divider().color($r('app.color.ink_line'))

        Column({ space: $r('app.float.space_xs') }) {
          Text($r('app.string.books_progress', 0, this.totalChars()))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
            .width('100%')
          Progress({ value: 0, total: Math.max(1, this.totalChars()), type: ProgressType.Linear })
            .width('100%')
            .color(themePalette.accent())
        }
        .width('100%')

        Row({ space: $r('app.float.space_m') }) {
          Button($r('app.string.books_continue'))
            .buttonStyle(ButtonStyleMode.EMPHASIZED)
            .fontColor($r('app.color.hm_on_brand'))
            .backgroundColor(themePalette.fill())
            .layoutWeight(1)
            .onClick(() => {
              this.openFirstBook();
            })
          if (this.hasDaily()) {
            Button($r('app.string.books_daily_open'))
              .buttonStyle(ButtonStyleMode.NORMAL)
              .fontColor(themePalette.accent())
              .layoutWeight(1)
              .onClick(() => {
                this.openDailyChar(this.daily());
              })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding($r('app.float.space_l'))
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  sectionHeader() {
    Row({ space: $r('app.float.space_s') }) {
      Column()
        .width($r('app.float.space_xs'))
        .height($r('app.float.font_size_title'))
        .borderRadius($r('app.float.space_xxs'))
        .backgroundColor($r('app.color.ink_seal'))
      Text($r('app.string.books_title'))
        .fontSize($r('app.float.font_size_title'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_primary'))
      Divider()
        .color($r('app.color.ink_line'))
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  bookCard(book: Book) {
    Column() {
      InkCard() {
        Column({ space: $r('app.float.space_s') }) {
          Row({ space: $r('app.float.space_s') }) {
            HanziGridCell({ char: gradeGlyphOf(book), cellSize: CARD_TILE })
            Column({ space: $r('app.float.space_xxs') }) {
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
              Text(this.termLabel(book))
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .maxLines(1)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          Blank()

          Progress({ value: 0, total: Math.max(1, book.charCount), type: ProgressType.Linear })
            .width('100%')
            .color(themePalette.accent())
        }
        .width('100%')
        .height('100%')
        .padding($r('app.float.space_m'))
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height($r('app.float.books_card_height'))
    .onClick(() => {
      this.openBook(book);
    })
  }

  /** 纸色底 + 两团墨晕，营造宣纸质感（不使用位图素材）。 */
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      PaperBackground()

      ResponsiveContent() {
        List({ scroller: scrollers.home }) {
          ListItem() {
            Column({ space: $r('app.float.space_l') }) {
              Row().width('100%')
                .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))
              this.todayCard()
              this.sectionHeader()
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
    .width('100%')
    .height('100%')
  }
}
