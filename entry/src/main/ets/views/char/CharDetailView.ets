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
import { progressStore } from '../../service/ProgressStore';
import { safeArea } from '../../service/SafeAreaController';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { themePalette } from '../../model/ThemePalette';
import { appSettings } from '../../model/AppSettings';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { GRID_OPTIONS } from '../../model/SettingsOptions';
import { MaterialController } from '../../service/MaterialController';
import { StrokeThemeFactory } from '../../service/StrokeThemeFactory';
import { DecompositionInfo, IdeographDecomposition, StructureKind } from '../../service/IdeographDecomposition';
import { AppMenu } from '../../common/components/AppMenu';
import { choiceMenu } from '../../common/components/ChoiceMenu';
import { CharRouteParam, PracticeRouteParam } from '../../model/RouteParams';
import { StrokeCanvas } from '../practice/StrokeCanvas';
import { StrokeStepsView } from '../practice/StrokeStepsView';
import { StrokeToggleChip } from '../practice/StrokeToggleChip';
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
  @Local theme: StrokeTheme = new StrokeTheme();
  /** 本次描红开始时间；0 表示未开始。 */
  @Local quizStartAt: number = 0;
  /** 步骤条选中笔；-1 表示跟随播放/描红。 */
  @Local selectedStroke: number = -1;

  aboutToAppear(): void {
    this.buildTheme();
    this.loadStrokeData();
  }

  private buildTheme(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.theme = StrokeThemeFactory.fromContext(context);
    }
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

  private isLearned(): boolean {
    return progressStore.isLearned(this.char);
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

  private decomposition(): DecompositionInfo {
    return IdeographDecomposition.parse(this.entry()?.decomposition ?? '');
  }

  private hasStructure(): boolean {
    return this.decomposition().kind !== StructureKind.UNKNOWN;
  }

  private structureLabel(): ResourceStr {
    const kind: StructureKind = this.decomposition().kind;
    if (kind === StructureKind.LEFT_RIGHT) {
      return $r('app.string.char_structure_lr');
    }
    if (kind === StructureKind.TOP_BOTTOM) {
      return $r('app.string.char_structure_tb');
    }
    if (kind === StructureKind.LEFT_MIDDLE_RIGHT) {
      return $r('app.string.char_structure_lcr');
    }
    if (kind === StructureKind.TOP_MIDDLE_BOTTOM) {
      return $r('app.string.char_structure_tcb');
    }
    if (kind === StructureKind.SURROUND) {
      return $r('app.string.char_structure_surround');
    }
    if (kind === StructureKind.SEMI_SURROUND) {
      return $r('app.string.char_structure_semi');
    }
    if (kind === StructureKind.OVERLAY) {
      return $r('app.string.char_structure_overlay');
    }
    return '';
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
  partChips(parts: string[]) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(parts, (part: string) => {
        Text(part)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hanzi_ink'))
          .width($r('app.float.hanzi_cell_size'))
          .height($r('app.float.hanzi_cell_size'))
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.hm_divider'))
          .borderRadius($r('app.float.space_s'))
          .margin({ right: $r('app.float.hanzi_cell_gap'), bottom: $r('app.float.hanzi_cell_gap') })
      }, (part: string) => part)
    }
    .width('100%')
  }

  @Builder
  GridMenu() {
    AppMenu(choiceMenu(GRID_OPTIONS, appSettings.gridStyle, (id: string) => {
      settingsViewModel.setGridStyle(id);
    }))
  }

  /** 字格当前值 chip：点开 4 种格子样式。 */
  @Builder
  gridChip() {
    Text(GRID_OPTIONS.labelOf(appSettings.gridStyle))
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
      .bindMenu(this.GridMenu(),
        MaterialController.menuOptionsFor({ placement: Placement.BottomLeft }, appSettings.immersiveOn,
          appSettings.lightEffectEnabled))
  }

  /** 笔顺显示开关：序号 / 透视 / 步骤条 / 字格。 */
  @Builder
  strokeTools() {
    Row({ space: $r('app.float.space_s') }) {
      StrokeToggleChip({
        label: $r('app.string.char_numbers'),
        active: appSettings.showStrokeNumbers,
        onTap: () => {
          settingsViewModel.setShowStrokeNumbers(!appSettings.showStrokeNumbers);
        }
      })
      StrokeToggleChip({
        label: $r('app.string.char_skeleton'),
        active: appSettings.showSkeleton,
        onTap: () => {
          settingsViewModel.setShowSkeleton(!appSettings.showSkeleton);
        }
      })
      StrokeToggleChip({
        label: $r('app.string.char_steps'),
        active: appSettings.showStrokeSteps,
        onTap: () => {
          settingsViewModel.setShowStrokeSteps(!appSettings.showStrokeSteps);
        }
      })
      this.gridChip()
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
        gridStyle: appSettings.gridStyle,
        showNumbers: appSettings.showStrokeNumbers,
        showSkeleton: appSettings.showSkeleton,
        staticReveal: this.selectedStroke,
        onStrokeIndexChange: (index: number) => {
          this.strokeIndex = index;
        },
        onStrokeError: (total: number) => {
          this.mistakes = total;
        },
          onQuizComplete: (mistakes: number) => {
            this.mistakes = mistakes;
            this.quizStarted = false;
            const startAt: number = this.quizStartAt;
            this.quizStartAt = 0;
            const durationMs: number = startAt > 0 ? Date.now() - startAt : 0;
            progressStore.recordPractice(this.char, this.lessonId, mistakes, durationMs);
          }
      })

      this.strokeTools()

      if (appSettings.showStrokeSteps && this.strokeData !== undefined) {
        Scroll() {
          StrokeStepsView({
            data: this.strokeData,
            selected: this.selectedStroke,
            theme: this.theme,
            showNumbers: appSettings.showStrokeNumbers,
            onSelect: (index: number) => {
              this.selectedStroke = index;
            }
          })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }

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
            this.selectedStroke = -1;
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
            this.quizStartAt = Date.now();
            this.strokeIndex = 0;
            this.selectedStroke = -1;
            this.quizTrigger += 1;
          })
        Button($r('app.string.char_fullscreen'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .fontColor(themePalette.accent())
          .layoutWeight(1)
          .enabled(this.strokeData !== undefined)
          .onClick(() => {
            this.navPathStack.pushPathByName(RouterConstants.PAGE_PRACTICE,
              new PracticeRouteParam(this.char, this.lessonId));
          })
      }
      .width('100%')

      Button(this.isLearned() ? $r('app.string.char_learned') : $r('app.string.char_mark_learned'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .width('100%')
        .id('char_mark_learned')
        .onClick(() => {
          progressStore.toggleLearned(this.char, this.lessonId);
        })
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

                Row({ space: $r('app.float.space_s') }) {
                  Text($r('app.string.char_stroke_count', this.entry()?.strokeCount ?? 0))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor($r('app.color.hm_text_secondary'))
                  if (this.hasStructure()) {
                    Text($r('app.string.char_structure'))
                      .fontSize($r('app.float.font_size_caption'))
                      .fontColor($r('app.color.hm_text_secondary'))
                    Text(this.structureLabel())
                      .fontSize($r('app.float.font_size_body'))
                      .fontColor($r('app.color.hanzi_ink'))
                  }
                }
                .width('100%')

                if (this.decomposition().components.length > 0) {
                  Text($r('app.string.char_components'))
                    .fontSize($r('app.float.font_size_caption'))
                    .fontColor($r('app.color.hm_text_secondary'))
                    .width('100%')
                  this.partChips(this.decomposition().components)
                }

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
