/*
 * LessonDetailView.ets — 单课详情：生字、会写的字、本课词语。
 */

import { Lesson, LessonChar, WordEntry } from '../../model/CurriculumModels';
import { Passage } from '../../model/ReadingModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { ttsService } from '../../service/TtsService';
import { ReadingViewModel } from '../../viewmodel/ReadingViewModel';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { themePalette } from '../../model/ThemePalette';
import { CharRouteParam, LessonRouteParam } from '../../model/RouteParams';
import { ReadingQuiz } from '../../common/utils/ReadingQuiz';
import { ResponsiveContent } from '../ResponsiveContent';
import { PassageCard } from './PassageCard';

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
  @Local showReadingPinyin: boolean = true;
  @Local quizTarget: string = '';
  @Local quizResult: number = 0;

  private reading: ReadingViewModel = new ReadingViewModel();
  private quizCursor: number = 0;

  aboutToAppear(): void {
    this.reading.load(this.lessonId);
    if (this.reading.hasReading()) {
      ttsService.init();
    }
  }

  aboutToDisappear(): void {
    ttsService.stop();
  }

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

  /** 阅读区点击汉字：小测进行中先判分，否则进字详情。 */
  private handleReadingChar(char: string): void {
    const result: number = ReadingQuiz.judge(this.quizTarget, char);
    if (result === 0) {
      this.openChar(char);
      return;
    }
    this.quizResult = result;
    if (result === 1) {
      this.quizTarget = '';
    }
  }

  /** 「找一找」：按本课生字顺序轮取下一个目标字。 */
  private nextQuiz(): void {
    const chars: string[] = this.reading.focusChars();
    const target: string = ReadingQuiz.nextTarget(chars, this.quizCursor);
    if (target.length === 0) {
      return;
    }
    this.quizTarget = target;
    this.quizCursor += 1;
    this.quizResult = 0;
  }

  private speakPassage(passageId: string, text: string): void {
    ttsService.speak(passageId, text);
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

  /** 读一读：识字短文点读 + 找一找小测（无短文数据时整段不渲染）。 */
  @Builder
  readingSection() {
    if (this.reading.hasReading()) {
      Column({ space: $r('app.float.space_m') }) {
        Row({ space: $r('app.float.space_s') }) {
          Text($r('app.string.reading_section_title'))
            .fontSize($r('app.float.font_size_section'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.hm_text_primary'))
            .layoutWeight(1)
          Text($r('app.string.reading_pinyin'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
          Toggle({ type: ToggleType.Switch, isOn: this.showReadingPinyin })
            .onChange((value: boolean) => {
              this.showReadingPinyin = value;
            })
          Button($r('app.string.reading_quiz_start'))
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(themePalette.accent())
            .onClick(() => {
              this.nextQuiz();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.quizTarget.length > 0) {
          Text($r('app.string.reading_quiz_prompt', this.reading.pinyinOf(this.quizTarget)))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(themePalette.accent())
            .width('100%')
        }
        if (this.quizResult === 1) {
          Text($r('app.string.reading_quiz_correct'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hanzi_success'))
            .width('100%')
        } else if (this.quizResult === 2) {
          Text($r('app.string.reading_quiz_retry'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hanzi_error'))
            .width('100%')
        }

        ForEach(this.reading.passages, (passage: Passage) => {
          PassageCard({
            passage: passage,
            glyphs: this.reading.glyphsOf(passage.id),
            showPinyin: this.showReadingPinyin,
            playing: ttsService.speakingId === passage.id,
            canSpeak: ttsService.available,
            onCharClick: (char: string): void => {
              this.handleReadingChar(char);
            },
            onSpeak: (passageId: string, text: string): void => {
              this.speakPassage(passageId, text);
            }
          })
        }, (passage: Passage) => passage.id)
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

            this.readingSection()

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
