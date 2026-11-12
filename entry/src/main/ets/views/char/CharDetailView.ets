/*
 * CharDetailView.ets — 字详情：笔顺播放 / 描红、读音、字形、组词。
 *
 * 画布固定在顶部（不放进 Scroll），避免描红时手指拖动触发页面滚动。
 */

import { common } from '@kit.AbilityKit';
import { CharacterEntry, Reading, WordEntry } from '../../model/CurriculumModels';
import { Point, StrokeData, StrokeTheme } from '../../model/StrokeModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { hanziDataRepository } from '../../service/HanziDataRepository';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { themePalette } from '../../model/ThemePalette';
import { CharRouteParam } from '../../model/RouteParams';
import { StrokeCanvas } from '../practice/StrokeCanvas';
import { ResponsiveContent } from '../ResponsiveContent';

const CANVAS_SIZE: number = 280;
const CANVAS_PADDING: number = 20;
const WORD_PREVIEW: number = 10;

@ComponentV2
export struct CharDetailView {
  @Param char: string = '';
  @Param lessonId: string = '';
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  @Local strokeData: StrokeData | undefined = undefined;
  @Local loading: boolean = true;
  @Local strokeIndex: number = 0;
  @Local mistakes: number = 0;
  @Local quizStarted: boolean = false;
  @Local playTrigger: number = 0;
  @Local quizTrigger: number = 0;
  @Local wordsExpanded: boolean = false;

  private theme: StrokeTheme = new StrokeTheme();

  aboutToAppear(): void {
    this.loadStrokeData();
  }

  private async loadStrokeData(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.loading = false;
      return;
    }
    const data: StrokeData | undefined = await hanziDataRepository.get(context, this.char);
    this.strokeData = data;
    this.loading = false;
  }

  private entry(): CharacterEntry | undefined {
    return curriculumRepository.character(this.char);
  }

  private pinyinText(): string {
    const entry: CharacterEntry | undefined = this.entry();
    if (entry === undefined) {
      return '';
    }
    return entry.pinyins.join(' / ');
  }

  private readings(): Reading[] {
    return curriculumRepository.readingsFor(this.char);
  }

  private words(): WordEntry[] {
    return curriculumRepository.wordsFor(this.char);
  }

  private visibleWords(): WordEntry[] {
    const all: WordEntry[] = this.words();
    return this.wordsExpanded ? all : all.slice(0, WORD_PREVIEW);
  }

  private homophones(): CharacterEntry[] {
    return curriculumRepository.homophones(this.char).slice(0, 12);
  }

  private sameRadical(): CharacterEntry[] {
    return curriculumRepository.sameRadical(this.char).slice(0, 12);
  }

  private openChar(char: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR,
      new CharRouteParam(char, this.lessonId, false));
  }

  @Builder
  sectionTitle(title: ResourceStr) {
    Text(title)
      .fontSize($r('app.float.font_size_section'))
      .fontColor($r('app.color.hm_text_secondary'))
      .width('100%')
      .margin({ top: $r('app.float.space_l'), bottom: $r('app.float.space_s') })
  }

  @Builder
  charChips(entries: CharacterEntry[]) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(entries, (entry: CharacterEntry) => {
        Text(entry.char)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hanzi_ink'))
          .width($r('app.float.hanzi_cell_size'))
          .height($r('app.float.hanzi_cell_size'))
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.hanzi_card'))
          .borderRadius($r('app.float.space_s'))
          .margin({ right: $r('app.float.hanzi_cell_gap'), bottom: $r('app.float.hanzi_cell_gap') })
          .onClick(() => {
            this.openChar(entry.char);
          })
      }, (entry: CharacterEntry) => entry.char)
    }
    .width('100%')
  }

  @Builder
  header() {
    Column({ space: $r('app.float.space_s') }) {
      Row({ space: $r('app.float.space_m') }) {
        Text(this.char)
          .fontSize($r('app.float.font_size_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hanzi_ink'))
        Text(this.pinyinText())
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_secondary'))
          .layoutWeight(1)
      }
      .width('100%')

      StrokeCanvas({
        data: this.strokeData,
        theme: this.theme,
        canvasSize: CANVAS_SIZE,
        canvasPadding: CANVAS_PADDING,
        showOutline: true,
        playTrigger: this.playTrigger,
        quizTrigger: this.quizTrigger,
        onStrokeIndexChange: (index: number) => {
          this.strokeIndex = index;
        },
        onQuizComplete: (mistakes: number) => {
          this.mistakes = mistakes;
          this.quizStarted = false;
        }
      })

      if (this.loading) {
        Text($r('app.string.char_loading'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
      } else if (this.strokeData === undefined) {
        Text($r('app.string.char_no_strokes'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hanzi_error'))
      } else {
        Row({ space: $r('app.float.space_m') }) {
          Text($r('app.string.char_strokes', this.strokeIndex, this.strokeData?.strokeCount ?? 0))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
          Text($r('app.string.char_mistakes', this.mistakes))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(this.mistakes > 0 ? $r('app.color.hanzi_error') : $r('app.color.hm_text_secondary'))
        }
        .width('100%')
      }

      Row({ space: $r('app.float.space_m') }) {
        Button($r('app.string.char_play'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .fontColor(themePalette.accent())
          .layoutWeight(1)
          .enabled(this.strokeData !== undefined)
          .onClick(() => {
            this.playTrigger += 1;
          })
        Button($r('app.string.char_quiz'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(themePalette.fill())
          .fontColor($r('app.color.hm_on_brand'))
          .layoutWeight(1)
          .enabled(this.strokeData !== undefined)
          .onClick(() => {
            this.mistakes = 0;
            this.quizStarted = true;
            this.quizTrigger += 1;
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.space_l'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.book_card_radius'))
  }

  build() {
    ResponsiveContent() {
      Column() {
        Row().width('100%')
          .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

        this.header()

        Scroll() {
          Column() {
            if (this.readings().length > 0) {
              this.sectionTitle($r('app.string.char_readings'))
              Column({ space: $r('app.float.space_s') }) {
                ForEach(this.readings(), (reading: Reading) => {
                  Column({ space: $r('app.float.space_xxs') }) {
                    Text(`${reading.pinyin}  ${reading.words.length > 0 ? reading.words[0] : ''}`)
                      .fontSize($r('app.float.font_size_body'))
                      .fontColor($r('app.color.hm_text_primary'))
                      .width('100%')
                    Text(reading.lessonId)
                      .fontSize($r('app.float.font_size_caption'))
                      .fontColor($r('app.color.hm_text_secondary'))
                      .width('100%')
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }, (reading: Reading) => `${reading.char}-${reading.pinyin}`)
              }
              .width('100%')
              .padding($r('app.float.space_l'))
              .backgroundColor($r('app.color.hanzi_card'))
              .borderRadius($r('app.float.radius_card'))
            }

            if (this.entry() !== undefined) {
              this.sectionTitle($r('app.string.char_shape'))
              Column({ space: $r('app.float.space_s') }) {
                Row({ space: $r('app.float.space_s') }) {
                  Text($r('app.string.char_radical'))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor($r('app.color.hm_text_secondary'))
                  Text(this.entry()?.radical ?? '')
                    .fontSize($r('app.float.font_size_body'))
                    .fontColor($r('app.color.hanzi_ink'))
                  Text($r('app.string.char_decomposition'))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor($r('app.color.hm_text_secondary'))
                  Text(this.entry()?.decomposition ?? '')
                    .fontSize($r('app.float.font_size_body'))
                    .fontColor($r('app.color.hanzi_ink'))
                }
                .width('100%')

                if (this.sameRadical().length > 0) {
                  Text($r('app.string.char_same_radical'))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor($r('app.color.hm_text_secondary'))
                    .width('100%')
                  this.charChips(this.sameRadical())
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding($r('app.float.space_l'))
              .backgroundColor($r('app.color.hanzi_card'))
              .borderRadius($r('app.float.radius_card'))
            }

            if (this.homophones().length > 0) {
              this.sectionTitle($r('app.string.char_same_pinyin'))
              this.charChips(this.homophones())
            }

            if (this.words().length > 0) {
              this.sectionTitle($r('app.string.char_words'))
              Column({ space: $r('app.float.space_s') }) {
                ForEach(this.visibleWords(), (entry: WordEntry) => {
                  Row() {
                    Text(entry.word)
                      .fontSize($r('app.float.font_size_body'))
                      .fontColor($r('app.color.hm_text_primary'))
                      .layoutWeight(1)
                    Text(entry.readingPinyin)
                      .fontSize($r('app.float.font_size_caption'))
                      .fontColor($r('app.color.hm_text_secondary'))
                  }
                  .width('100%')
                }, (entry: WordEntry) => entry.word)
                if (this.words().length > WORD_PREVIEW) {
                  Text(this.wordsExpanded ? $r('app.string.char_less') : $r('app.string.char_more'))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor(themePalette.accent())
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.wordsExpanded = !this.wordsExpanded;
                    })
                }
              }
              .width('100%')
              .padding($r('app.float.space_l'))
              .backgroundColor($r('app.color.hanzi_card'))
              .borderRadius($r('app.float.radius_card'))
            }

            Blank().height(safeArea.contentBottomInsetVp)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .margin({ top: $r('app.float.space_s') })
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    }
  }
}
