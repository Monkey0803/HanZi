/*
 * LessonDetailView.ets — 单课详情：生字、会写的字、本课词语。
 */

import { Lesson, LessonChar, WordEntry } from '../../model/CurriculumModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { themePalette } from '../../model/ThemePalette';
import { CharRouteParam, LessonRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';

const CELL_SIZE: number = 64;
const CELL_GAP: number = 8;
const COLUMNS: number = 5;
const WORD_LIMIT: number = 24;

class WordItem {
  word: string = '';
  pinyin: string = '';

  constructor(word: string = '', pinyin: string = '') {
    this.word = word;
    this.pinyin = pinyin;
  }
}

@ComponentV2
export struct LessonDetailView {
  @Param lessonId: string = '';
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  @Local hidePinyin: boolean = false;

  private lesson(): Lesson | undefined {
    return curriculumRepository.lesson(this.lessonId);
  }

  private readChars(): LessonChar[] {
    const all: LessonChar[] = curriculumRepository.charsOfLesson(this.lessonId);
    const result: LessonChar[] = [];
    for (let i = 0; i < all.length; i += 1) {
      if (all[i].isWrite === 0) {
        result.push(all[i]);
      }
    }
    return result;
  }

  private writeChars(): LessonChar[] {
    const all: LessonChar[] = curriculumRepository.charsOfLesson(this.lessonId);
    const result: LessonChar[] = [];
    for (let i = 0; i < all.length; i += 1) {
      if (all[i].isWrite === 1) {
        result.push(all[i]);
      }
    }
    return result;
  }

  private gridHeight(count: number): number {
    const rows: number = Math.max(1, Math.ceil(count / COLUMNS));
    return rows * CELL_SIZE + (rows - 1) * CELL_GAP;
  }

  private words(): WordItem[] {
    const result: WordItem[] = [];
    const seen: Set<string> = new Set<string>();
    const chars: LessonChar[] = curriculumRepository.charsOfLesson(this.lessonId);
    for (let i = 0; i < chars.length; i += 1) {
      const list: WordEntry[] = curriculumRepository.wordsFor(chars[i].char);
      for (let j = 0; j < list.length; j += 1) {
        if (seen.has(list[j].word)) {
          continue;
        }
        seen.add(list[j].word);
        result.push(new WordItem(list[j].word, list[j].readingPinyin));
        if (result.length >= WORD_LIMIT) {
          return result;
        }
      }
    }
    return result;
  }

  private openChar(char: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR,
      new CharRouteParam(char, this.lessonId, false));
  }

  private siblingLesson(offset: number): Lesson | undefined {
    const lesson: Lesson | undefined = this.lesson();
    if (lesson === undefined) {
      return undefined;
    }
    const lessons: Lesson[] = curriculumRepository.lessonsOfBook(lesson.bookId);
    for (let i = 0; i < lessons.length; i += 1) {
      if (lessons[i].id === lesson.id) {
        const target: number = i + offset;
        return target >= 0 && target < lessons.length ? lessons[target] : undefined;
      }
    }
    return undefined;
  }

  private openSibling(offset: number): void {
    const target: Lesson | undefined = this.siblingLesson(offset);
    if (target !== undefined) {
      this.navPathStack.pushPathByName(RouterConstants.PAGE_LESSON,
        new LessonRouteParam(target.id, 'lesson'));
    }
  }

  @Builder
  charCell(item: LessonChar) {
    Column({ space: $r('app.float.space_xxs') }) {
      Text(this.hidePinyin ? '' : item.pinyin)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .height($r('app.float.font_size_caption'))
      Stack() {
        Text(item.char)
          .fontSize($r('app.float.font_size_title'))
          .fontColor($r('app.color.hanzi_ink'))
      }
      .width(CELL_SIZE - 16)
      .height(CELL_SIZE - 16)
      .border({ width: 1, color: $r('app.color.hanzi_grid') })
      .borderRadius($r('app.float.space_xs'))
    }
    .width(CELL_SIZE)
    .height(CELL_SIZE)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.openChar(item.char);
    })
  }

  @Builder
  charSection(title: ResourceStr, chars: LessonChar[]) {
    if (chars.length > 0) {
      Column({ space: $r('app.float.space_s') }) {
        Text(title)
          .fontSize($r('app.float.font_size_section'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
        Grid() {
          ForEach(chars, (item: LessonChar) => {
            GridItem() {
              this.charCell(item)
            }
          }, (item: LessonChar) => `${item.lessonId}-${item.char}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(CELL_GAP)
        .rowsGap(CELL_GAP)
        .width('100%')
        .height(this.gridHeight(chars.length))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding($r('app.float.space_l'))
      .backgroundColor($r('app.color.hanzi_card'))
      .borderRadius($r('app.float.radius_card'))
    }
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column({ space: $r('app.float.space_l') }) {
          Row().width('100%')
            .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

          if (this.lesson() !== undefined) {
            Column({ space: $r('app.float.space_xs') }) {
              Text(this.lesson()?.title ?? '')
                .fontSize($r('app.float.font_size_title'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.hm_text_primary'))
                .width('100%')
              Row() {
                Text($r('app.string.lesson_hide_pinyin'))
                  .fontSize($r('app.float.font_size_caption'))
                  .fontColor($r('app.color.hm_text_secondary'))
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.hidePinyin })
                  .onChange((value: boolean) => {
                    this.hidePinyin = value;
                  })
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding($r('app.float.space_l'))
            .backgroundColor($r('app.color.hanzi_card'))
            .borderRadius($r('app.float.book_card_radius'))

            this.charSection($r('app.string.lesson_chars'), this.readChars())
            this.charSection($r('app.string.lesson_write_chars'), this.writeChars())

            if (this.words().length > 0) {
              Column({ space: $r('app.float.space_s') }) {
                Text($r('app.string.lesson_words'))
                  .fontSize($r('app.float.font_size_section'))
                  .fontColor($r('app.color.hm_text_secondary'))
                  .width('100%')
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.words(), (item: WordItem) => {
                    Text(item.word)
                      .fontSize($r('app.float.font_size_body'))
                      .fontColor($r('app.color.hm_text_primary'))
                      .padding({
                        left: $r('app.float.space_m'),
                        right: $r('app.float.space_m'),
                        top: $r('app.float.space_xs'),
                        bottom: $r('app.float.space_xs')
                      })
                      .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })
                      .backgroundColor($r('app.color.hm_divider'))
                      .borderRadius($r('app.float.radius_chip'))
                  }, (item: WordItem) => item.word)
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding($r('app.float.space_l'))
              .backgroundColor($r('app.color.hanzi_card'))
              .borderRadius($r('app.float.radius_card'))
            }

            Row({ space: $r('app.float.space_m') }) {
              Button($r('app.string.lesson_prev'))
                .buttonStyle(ButtonStyleMode.NORMAL)
                .fontColor(themePalette.accent())
                .enabled(this.siblingLesson(-1) !== undefined)
                .layoutWeight(1)
                .onClick(() => {
                  this.openSibling(-1);
                })
              Button($r('app.string.lesson_next'))
                .buttonStyle(ButtonStyleMode.NORMAL)
                .fontColor(themePalette.accent())
                .enabled(this.siblingLesson(1) !== undefined)
                .layoutWeight(1)
                .onClick(() => {
                  this.openSibling(1);
                })
            }
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
