/*
 * CharDetailView.ets — 字详情：笔顺播放 / 描红、读音、字形、组词。
 *
 * 整页可滚动；描红时锁定滚动并回到顶部，避免手指画字触发页面滚动。
 */

import { common } from '@kit.AbilityKit';
import { CharacterEntry, Reading, WordEntry } from '../../model/CurriculumModels';
import { StrokeData, StrokeTheme } from '../../model/StrokeModels';
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
import { PageTopSpacer } from '../PageTopSpacer';
import { ttsService } from '../../service/TtsService';
import { deviceService } from '../../service/DeviceService';
import { STEPS_CELL_WIDTH } from '../../common/constants/StrokeConstants';

const WORD_PREVIEW: number = 10;
const CANVAS_MIN: number = 220;
const CANVAS_MAX: number = 320;
const CANVAS_PADDING_RATIO: number = 0.07;
/** 与 app.float.space_l 保持一致，用于从卡片宽度反推画布可用宽度。 */
const CARD_PADDING_VP: number = 16;
/** 自动滚动步骤条时，当前格左侧保留的格数。 */
const STEPS_SCROLL_LEAD: number = 2;

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
  @Local resetTrigger: number = 0;
  @Local wordsExpanded: boolean = false;
  @Local theme: StrokeTheme = new StrokeTheme();
  /** 本次描红开始时间；0 表示未开始。 */
  @Local quizStartAt: number = 0;
  /** 步骤条选中笔；-1 表示跟随播放/描红。 */
  @Local selectedStroke: number = -1;
  @Local canvasSize: number = 280;
  @Local canvasPadding: number = 20;

  private pageScroller: Scroller = new Scroller();
  private stepsScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.buildTheme();
    this.loadStrokeData();
    ttsService.init();
  }

  aboutToDisappear(): void {
    ttsService.stop();
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

  /** 只展示部件本身，避免 IDS 结构符（如 ⿱）在没有对应字体的设备上显示成方框。 */
  private decompositionText(): string {
    const info: DecompositionInfo = this.decomposition();
    if (info.components.length > 0) {
      return info.components.join('');
    }
    return this.entry()?.decomposition ?? '';
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

  /** 按卡片宽度计算画布尺寸；画布不放进固定高度里，避免小屏溢出。 */
  private applyCanvasWidth(width: number): void {
    if (!Number.isFinite(width) || width <= 0) {
      return;
    }
    const available: number = width - 2 * CARD_PADDING_VP;
    if (available <= 0) {
      return;
    }
    const size: number = Math.round(Math.max(CANVAS_MIN, Math.min(CANVAS_MAX, available)));
    if (size !== this.canvasSize) {
      this.canvasSize = size;
      this.canvasPadding = Math.round(size * CANVAS_PADDING_RATIO);
    }
  }

  private totalStrokes(): number {
    return this.strokeData?.strokeCount ?? 0;
  }

  private stepsVisible(): boolean {
    return appSettings.showStrokeSteps && this.strokeData !== undefined;
  }

  private progressLabel(): ResourceStr {
    const total: number = this.totalStrokes();
    if (this.selectedStroke >= 0) {
      return $r('app.string.char_strokes', this.selectedStroke + 1, total);
    }
    if (this.strokeIndex > 0) {
      return $r('app.string.char_strokes', this.strokeIndex, total);
    }
    return $r('app.string.char_stroke_count', total);
  }

  private progressValue(): number {
    if (this.selectedStroke >= 0) {
      return this.selectedStroke + 1;
    }
    return this.strokeIndex;
  }

  private scrollStepsTo(index: number): void {
    if (!appSettings.showStrokeSteps || index < 0) {
      return;
    }
    const offset: number = Math.max(0, (index - STEPS_SCROLL_LEAD) * STEPS_CELL_WIDTH);
    this.stepsScroller.scrollTo({ xOffset: offset, yOffset: 0, animation: true });
  }

  private startQuiz(): void {
    this.mistakes = 0;
    this.quizStarted = true;
    this.quizStartAt = Date.now();
    this.strokeIndex = 0;
    this.selectedStroke = -1;
    this.quizTrigger += 1;
    this.pageScroller.scrollEdge(Edge.Top);
  }

  private stopQuiz(): void {
    this.quizStarted = false;
    this.quizStartAt = 0;
    this.mistakes = 0;
    this.strokeIndex = 0;
    this.selectedStroke = -1;
    this.resetTrigger += 1;
  }

  private startPlayback(): void {
    this.quizStarted = false;
    this.quizStartAt = 0;
    this.mistakes = 0;
    this.strokeIndex = 0;
    this.selectedStroke = -1;
    this.playTrigger += 1;
  }

  private openFullscreen(): void {
    this.quizStarted = false;
    this.quizStartAt = 0;
    this.navPathStack.pushPathByName(RouterConstants.PAGE_PRACTICE,
      new PracticeRouteParam(this.char, this.lessonId));
  }

  private toggleStep(index: number): void {
    this.selectedStroke = this.selectedStroke === index ? -1 : index;
  }

  private onStrokeIndexChanged(index: number): void {
    this.strokeIndex = index;
    this.scrollStepsTo(index);
  }

  private onQuizFinished(mistakes: number): void {
    this.mistakes = mistakes;
    this.quizStarted = false;
    const startAt: number = this.quizStartAt;
    this.quizStartAt = 0;
    const durationMs: number = startAt > 0 ? Date.now() - startAt : 0;
    progressStore.recordPractice(this.char, this.lessonId, mistakes, durationMs);
  }

  private toggleLearned(): void {
    progressStore.toggleLearned(this.char, this.lessonId);
  }

  private speak(): void {
    ttsService.speak(this.char, this.char);
  }

  private speaking(): boolean {
    return ttsService.speakingId === this.char;
  }

  private showSpeak(): boolean {
    return ttsService.available;
  }

  private canvasA11y(): Resource {
    return $r('app.string.char_canvas_a11y', this.totalStrokes());
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
    Row({ space: $r('app.float.space_xxs') }) {
      Text(GRID_OPTIONS.labelOf(appSettings.gridStyle))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
      SymbolGlyph($r('sys.symbol.arrowtriangle_down_fill'))
        .fontSize($r('app.float.icon_size_tiny'))
        .fontColor([$r('app.color.hm_text_secondary')])
    }
    .height($r('app.float.value_chip_height'))
    .padding({
      left: $r('app.float.space_m'),
      right: $r('app.float.space_m')
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
    Flex({ wrap: FlexWrap.Wrap }) {
      Row() {
        StrokeToggleChip({
          label: $r('app.string.char_numbers'),
          active: appSettings.showStrokeNumbers,
          onTap: () => {
            settingsViewModel.setShowStrokeNumbers(!appSettings.showStrokeNumbers);
          }
        })
      }
      .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })

      Row() {
        StrokeToggleChip({
          label: $r('app.string.char_skeleton'),
          active: appSettings.showSkeleton,
          onTap: () => {
            settingsViewModel.setShowSkeleton(!appSettings.showSkeleton);
          }
        })
      }
      .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })

      Row() {
        StrokeToggleChip({
          label: $r('app.string.char_steps'),
          active: appSettings.showStrokeSteps,
          onTap: () => {
            settingsViewModel.setShowStrokeSteps(!appSettings.showStrokeSteps);
          }
        })
      }
      .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })

      Row() {
        this.gridChip()
      }
      .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })
    }
    .width('100%')
  }

  @Builder
  speakChip() {
    Row({ space: $r('app.float.space_xxs') }) {
      SymbolGlyph($r('sys.symbol.speaker_wave_2'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([this.speaking() ? themePalette.accent() : $r('app.color.hm_text_secondary')])
      Text(this.speaking() ? $r('app.string.reading_stop') : $r('app.string.char_speak'))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor(this.speaking() ? themePalette.accent() : $r('app.color.hm_text_secondary'))
    }
    .height($r('app.float.value_chip_height'))
    .padding({ left: $r('app.float.space_s'), right: $r('app.float.space_s') })
    .borderRadius($r('app.float.radius_chip'))
    .backgroundColor($r('app.color.hm_divider'))
    .onClick(() => {
      this.speak();
    })
  }

  @Builder
  learnedChip() {
    Row({ space: $r('app.float.space_xxs') }) {
      SymbolGlyph(this.isLearned() ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.circle'))
        .fontSize($r('app.float.icon_size_tiny'))
        .fontColor([this.isLearned() ? $r('app.color.hm_on_brand') : $r('app.color.hm_text_secondary')])
      Text(this.isLearned() ? $r('app.string.char_learned') : $r('app.string.char_mark_learned'))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor(this.isLearned() ? $r('app.color.hm_on_brand') : $r('app.color.hm_text_secondary'))
    }
    .height($r('app.float.value_chip_height'))
    .padding({ left: $r('app.float.space_s'), right: $r('app.float.space_s') })
    .backgroundColor(this.isLearned() ? themePalette.fill() : $r('app.color.hm_divider'))
    .borderRadius($r('app.float.radius_chip'))
    .id('char_mark_learned')
    .onClick(() => {
      this.toggleLearned();
    })
  }

  @Builder
  progressRow() {
    Row({ space: $r('app.float.space_m') }) {
      Text(this.progressLabel())
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
      Text($r('app.string.char_mistakes', this.mistakes))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor(this.mistakes > 0 ? $r('app.color.hanzi_error') : $r('app.color.hm_text_secondary'))
      Blank()
      this.learnedChip()
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  progressBar() {
    if (this.totalStrokes() > 0) {
      Progress({
        value: this.progressValue(),
        total: this.totalStrokes(),
        type: ProgressType.Linear
      })
        .width('100%')
        .height($r('app.float.char_progress_height'))
        .color(themePalette.accent())
        .backgroundColor($r('app.color.hm_divider'))
    }
  }

  @Builder
  actionRow() {
    Row({ space: $r('app.float.space_m') }) {
      Button($r('app.string.char_play'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .height($r('app.float.action_button_height'))
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.startPlayback();
        })
      Button(this.quizStarted ? $r('app.string.char_quiz_stop') : $r('app.string.char_quiz'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .height($r('app.float.action_button_height'))
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          if (this.quizStarted) {
            this.stopQuiz();
          } else {
            this.startQuiz();
          }
        })
      Button($r('app.string.char_fullscreen'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .height($r('app.float.action_button_height'))
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.openFullscreen();
        })
    }
    .width('100%')
  }

  @Builder
  stepsStrip() {
    if (this.stepsVisible() && this.strokeData !== undefined) {
      Scroll(this.stepsScroller) {
        StrokeStepsView({
          data: this.strokeData,
          selected: this.selectedStroke,
          theme: this.theme,
          showNumbers: appSettings.showStrokeNumbers,
          onSelect: (index: number) => {
            this.toggleStep(index);
          }
        })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
  }

  @Builder
  practiceCard() {
    Column({ space: $r('app.float.space_s') }) {
      Row({ space: $r('app.float.space_s') }) {
        Text(this.char)
          .fontSize($r('app.float.font_size_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hanzi_ink'))
        Text(this.pinyinText())
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        if (this.showSpeak()) {
          this.speakChip()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column() {
        if (this.loading) {
          Text($r('app.string.char_loading'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
        } else if (this.strokeData === undefined) {
          Text($r('app.string.char_no_strokes'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hanzi_error'))
        } else {
          StrokeCanvas({
            data: this.strokeData,
            theme: this.theme,
            canvasSize: this.canvasSize,
            canvasPadding: this.canvasPadding,
            showOutline: true,
            playTrigger: this.playTrigger,
            quizTrigger: this.quizTrigger,
            resetTrigger: this.resetTrigger,
            gridStyle: appSettings.gridStyle,
            showNumbers: appSettings.showStrokeNumbers,
            showSkeleton: appSettings.showSkeleton,
            staticReveal: this.selectedStroke,
            onStrokeIndexChange: (index: number) => {
              this.onStrokeIndexChanged(index);
            },
            onStrokeError: (total: number) => {
              this.mistakes = total;
            },
            onQuizComplete: (value: number) => {
              this.onQuizFinished(value);
            }
          })
        }
      }
      .width(this.canvasSize)
      .height(this.canvasSize)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.hm_page_background'))
      .borderRadius($r('app.float.space_m'))
      .clip(true)
      .accessibilityText(this.canvasA11y())

      this.strokeTools()
      this.progressRow()
      this.progressBar()
      this.actionRow()
      this.stepsStrip()
    }
    .width('100%')
    .padding($r('app.float.space_l'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.book_card_radius'))
    .onAreaChange((oldArea: Area, newArea: Area) => {
      const width: number = Number.parseFloat(`${newArea.width}`);
      this.applyCanvasWidth(width);
    })
  }

  @Builder
  sections() {
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
            Text(this.decompositionText())
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
    }
    .width('100%')
  }

  build() {
    ResponsiveContent() {
      Column() {
        PageTopSpacer({ underTitleBar: this.underTitleBar })

        Scroll(this.pageScroller) {
          Column() {
            if (deviceService.wide) {
              Row({ space: $r('app.float.space_l') }) {
                Column() {
                  this.practiceCard()
                }
                .width('50%')

                Column() {
                  this.sections()
                }
                .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            } else {
              Column() {
                this.practiceCard()
                this.sections()
              }
              .width('100%')
            }

            Blank().height(safeArea.contentBottomInsetVp)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .enableScrollInteraction(!this.quizStarted)
        .margin({ top: $r('app.float.space_s') })
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    }
  }
}
