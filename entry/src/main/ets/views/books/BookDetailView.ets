/*
 * BookDetailView.ets — 单册详情：按单元列出课文。
 */

import { Book, Lesson, LessonChar, Unit } from '../../model/CurriculumModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { LessonRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';

const PREVIEW_CHARS: number = 8;

@ComponentV2
export struct BookDetailView {
  @Param bookId: string = '';
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  private book(): Book | undefined {
    return curriculumRepository.book(this.bookId);
  }

  private previewOf(lesson: Lesson): string {
    let text: string = '';
    const chars: LessonChar[] = lesson.chars;
    const limit: number = Math.min(PREVIEW_CHARS, chars.length);
    for (let i = 0; i < limit; i += 1) {
      text += chars[i].char;
    }
    return text;
  }

  private openLesson(lesson: Lesson): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_LESSON,
      new LessonRouteParam(lesson.id, 'book'));
  }

  @Builder
  lessonRow(lesson: Lesson) {
    Row({ space: $r('app.float.space_m') }) {
      Column({ space: $r('app.float.space_xxs') }) {
        Text(lesson.title)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.previewOf(lesson))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([$r('app.color.hm_text_secondary')])
    }
    .width('100%')
    .padding({ top: $r('app.float.space_m'), bottom: $r('app.float.space_m') })
    .onClick(() => {
      this.openLesson(lesson);
    })
  }

  @Builder
  unitSection(unit: Unit) {
    Column({ space: 0 }) {
      Text($r('app.string.unit_title', unit.index))
        .fontSize($r('app.float.font_size_section'))
        .fontColor($r('app.color.hm_text_secondary'))
        .width('100%')
        .padding({ top: $r('app.float.space_l'), bottom: $r('app.float.space_s') })

      Column() {
        ForEach(unit.lessons, (lesson: Lesson, index: number) => {
          if (index > 0) {
            Divider().color($r('app.color.hm_divider'))
          }
          this.lessonRow(lesson)
        }, (lesson: Lesson) => lesson.id)
      }
      .width('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      .backgroundColor($r('app.color.hanzi_card'))
      .borderRadius($r('app.float.radius_card'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column() {
          Row().width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          if (this.book() !== undefined) {
            Column({ space: $r('app.float.space_xs') }) {
              Text(this.book()?.title ?? '')
                .fontSize($r('app.float.font_size_title'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.hm_text_primary'))
                .width('100%')
              Text($r('app.string.books_lesson_count',
                this.book()?.lessonCount ?? 0, this.book()?.charCount ?? 0))
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding($r('app.float.space_l'))
            .backgroundColor($r('app.color.hanzi_card'))
            .borderRadius($r('app.float.book_card_radius'))

            ForEach(curriculumRepository.unitsOfBook(this.bookId), (unit: Unit) => {
              this.unitSection(unit)
            }, (unit: Unit) => `${this.bookId}-${unit.index}`)
          } else {
            Text($r('app.string.bootstrap_error_title'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
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
