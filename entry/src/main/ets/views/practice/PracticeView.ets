/*
 * PracticeView.ets — 全屏专注练字（对应 animCJK 的 Size：把画布放到最大）。
 *
 * 画布尺寸由容器实际区域计算（手机约 300vp，平板最多 480vp）；
 * 宽屏左右分栏：左侧画布，右侧字卡信息。
 */

import { common } from '@kit.AbilityKit';
import { ExpandedRegionLayoutOptions, FoldedRegionLayoutOptions, FoldSplitContainer, HoverModeRegionLayoutOptions,
  HoverModeStatus, PresetSplitRatio } from '@kit.ArkUI';
import { CharacterEntry, WordEntry } from '../../model/CurriculumModels';
import { StrokeData, StrokeTheme } from '../../model/StrokeModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { hanziDataRepository } from '../../service/HanziDataRepository';
import { progressStore } from '../../service/ProgressStore';
import { StrokeThemeFactory } from '../../service/StrokeThemeFactory';
import { safeArea } from '../../service/SafeAreaController';
import { themePalette } from '../../model/ThemePalette';
import { appSettings } from '../../model/AppSettings';
import { settingsViewModel } from '../../viewmodel/SettingsViewModel';
import { GRID_OPTIONS } from '../../model/SettingsOptions';
import { MaterialController } from '../../service/MaterialController';
import { AppMenu } from '../../common/components/AppMenu';
import { choiceMenu } from '../../common/components/ChoiceMenu';
import { StrokeCanvas } from './StrokeCanvas';
import { StrokeToggleChip } from './StrokeToggleChip';
import { PageTopSpacer } from '../PageTopSpacer';
import { StrokeSpeed } from '../../common/constants/StrokeConstants';
import { BreakpointConstants } from '../../common/constants/BreakpointConstants';
import { PracticeLayoutPolicy } from '../../common/utils/PracticeLayoutPolicy';

const PADDING_RATIO: number = 0.07;

@ComponentV2
export struct PracticeView {
  @Param char: string = '';
  @Param lessonId: string = '';
  @Param underTitleBar: boolean = false;

  @Local strokeData: StrokeData | undefined = undefined;
  @Local loading: boolean = true;
  @Local theme: StrokeTheme = new StrokeTheme();
  @Local canvasSize: number = 280;
  @Local canvasPadding: number = 16;
  @Local playTrigger: number = 0;
  @Local quizTrigger: number = 0;
  @Local resetTrigger: number = 0;
  @Local strokeIndex: number = 0;
  @Local mistakes: number = 0;
  @Local selectedStroke: number = -1;
  @Local pageWidth: number = 0;
  @Local pageHeight: number = 0;
  @Local hoverMode: boolean = false;
  @Local gridHovering: boolean = false;
  @Local expandedLayoutOptions: ExpandedRegionLayoutOptions = {
    horizontalSplitRatio: PresetSplitRatio.LAYOUT_3V2,
    verticalSplitRatio: PresetSplitRatio.LAYOUT_3V2,
    isExtraRegionPerpendicular: true
  };
  @Local hoverLayoutOptions: HoverModeRegionLayoutOptions = {
    horizontalSplitRatio: PresetSplitRatio.LAYOUT_3V2,
    showExtraRegion: false
  };
  @Local foldedLayoutOptions: FoldedRegionLayoutOptions = {
    verticalSplitRatio: PresetSplitRatio.LAYOUT_3V2
  };
  /** 本次描红开始时间；0 表示未开始。 */
  @Local quizStartAt: number = 0;
  private canvasMin: number = 220;
  private canvasCompactMin: number = 144;
  private canvasCap: number = 480;
  private canvasAreaMargin: number = 32;

  aboutToAppear(): void {
    this.loadLayoutMetrics();
    this.buildTheme();
    this.loadStrokeData();
  }

  private loadLayoutMetrics(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    try {
      this.canvasMin = context.resourceManager.getNumber($r('app.float.practice_canvas_min').id);
      this.canvasCompactMin = context.resourceManager.getNumber($r('app.float.practice_canvas_compact_min').id);
      this.canvasCap = context.resourceManager.getNumber($r('app.float.practice_canvas_cap').id);
      this.canvasAreaMargin = context.resourceManager.getNumber($r('app.float.practice_canvas_area_margin').id);
    } catch (error) {
      console.warn('PracticeView: failed to load layout metrics');
    }
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

  private words(): WordEntry[] {
    return curriculumRepository.wordsFor(this.char).slice(0, 5);
  }

  private compactMode(): boolean {
    return PracticeLayoutPolicy.isCompactWindow(this.pageWidth, this.pageHeight);
  }

  private canvasA11y(): Resource {
    const data: StrokeData | undefined = this.strokeData;
    if (data === undefined) {
      return $r('app.string.char_loading');
    }
    return $r('app.string.char_canvas_a11y', data.strokeCount);
  }

  private applyArea(width: number, height: number): void {
    const size: number = PracticeLayoutPolicy.canvasSize(width, height, this.compactMode(), this.canvasMin,
      this.canvasCompactMin, this.canvasCap, this.canvasAreaMargin);
    if (size <= 0) {
      return;
    }
    const rounded: number = Math.round(size);
    if (rounded !== Math.round(this.canvasSize)) {
      this.canvasSize = rounded;
      this.canvasPadding = Math.round(this.canvasSize * PADDING_RATIO);
    }
  }

  @Builder
  GridMenu() {
    AppMenu(choiceMenu(GRID_OPTIONS, appSettings.gridStyle, (id: string) => {
      settingsViewModel.setGridStyle(id);
    }))
  }

  @Builder
  canvasCard() {
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
          strokeDuration: StrokeSpeed.durationOf(appSettings.strokeSpeed),
          playTrigger: this.playTrigger,
          quizTrigger: this.quizTrigger,
          resetTrigger: this.resetTrigger,
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
          onQuizComplete: (value: number) => {
            this.mistakes = value;
            const startAt: number = this.quizStartAt;
            this.quizStartAt = 0;
            const durationMs: number = startAt > 0 ? Date.now() - startAt : 0;
            progressStore.recordPractice(this.char, this.lessonId, value, durationMs);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .accessibilityText(this.canvasA11y())
    .onAreaChange((oldArea: Area, newArea: Area) => {
      const width: number = Number.parseFloat(String(newArea.width));
      const height: number = Number.parseFloat(String(newArea.height));
      this.applyArea(width, height);
    })
  }

  @Builder
  toolsRow() {
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
      Button(GRID_OPTIONS.labelOf(appSettings.gridStyle))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .height($r('app.float.practice_control_min_height'))
        .padding({
          left: $r('app.float.space_m'),
          right: $r('app.float.space_m')
        })
        .backgroundColor($r('app.color.hm_divider'))
        .opacity(this.gridHovering ? 0.82 : 1)
        .borderRadius($r('app.float.radius_chip'))
        .focusable(true)
        .onHover((isHovering: boolean) => {
          this.gridHovering = isHovering;
        })
        .bindMenu(this.GridMenu(),
          MaterialController.menuOptionsFor({ placement: Placement.BottomLeft }, appSettings.immersiveOn,
            appSettings.lightEffectEnabled))
    }
    .width('100%')
  }

  @Builder
  actionRow() {
    Row({ space: $r('app.float.space_m') }) {
      Button($r('app.string.practice_play'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .height($r('app.float.practice_control_min_height'))
        .fontColor(themePalette.accent())
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.selectedStroke = -1;
          this.strokeIndex = 0;
          this.playTrigger += 1;
        })
      Button($r('app.string.practice_quiz'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .height($r('app.float.practice_control_min_height'))
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.mistakes = 0;
          this.strokeIndex = 0;
          this.quizStartAt = Date.now();
          this.selectedStroke = -1;
          this.quizTrigger += 1;
        })
      Button($r('app.string.practice_reset'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .height($r('app.float.practice_control_min_height'))
        .fontColor(themePalette.accent())
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.selectedStroke = -1;
          this.strokeIndex = 0;
          this.mistakes = 0;
          this.quizStartAt = 0;
          this.resetTrigger += 1;
        })
    }
    .width('100%')
  }

  @Builder
  statusPanel() {
    Column({ space: this.compactMode() ? $r('app.float.space_xs') : $r('app.float.space_s') }) {
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

      if (this.strokeData !== undefined) {
        Text($r('app.string.char_strokes', this.strokeIndex, this.strokeData?.strokeCount ?? 0))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
      }
      if (this.mistakes > 0) {
        Text($r('app.string.char_mistakes', this.mistakes))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hanzi_error'))
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  detailsPanel() {
    Column({ space: $r('app.float.space_l') }) {
      if (this.entry() !== undefined) {
        Column({ space: $r('app.float.space_xs') }) {
          Text($r('app.string.char_radical'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
          Text(this.entry()?.radical ?? '')
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: $r('app.float.space_xs') }) {
          Text($r('app.string.char_decomposition'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
          Text(this.entry()?.decomposition ?? '')
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      if (this.words().length > 0) {
        Column({ space: $r('app.float.space_s') }) {
          Text($r('app.string.char_words'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.words(), (item: WordEntry) => {
              Text(item.word)
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_primary'))
                .padding({
                  left: $r('app.float.space_m'),
                  right: $r('app.float.space_m'),
                  top: $r('app.float.space_xxs'),
                  bottom: $r('app.float.space_xxs')
                })
                .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })
                .backgroundColor($r('app.color.hm_divider'))
                .borderRadius($r('app.float.radius_chip'))
            }, (item: WordEntry) => item.word)
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .height('100%')
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding($r('app.float.space_l'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.radius_card'))
  }

  @Builder
  primaryRegion() {
    Column() {
      this.canvasCard()
    }
    .width('100%')
    .height('100%')
    .padding(this.compactMode() ? $r('app.float.space_s') : $r('app.float.space_l'))
  }

  @Builder
  secondaryRegion() {
    Scroll() {
      Column({ space: this.compactMode() ? $r('app.float.space_s') : $r('app.float.space_l') }) {
        this.statusPanel()
        this.toolsRow()
        this.actionRow()
        Blank().height(safeArea.contentBottomInsetVp)
      }
      .width('100%')
      .padding(this.compactMode() ? $r('app.float.space_s') : $r('app.float.space_l'))
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  extraRegion() {
    Column() {
      this.detailsPanel()
    }
    .width('100%')
    .height('100%')
    .padding($r('app.float.space_l'))
  }

  build() {
    GridRow({
      columns: BreakpointConstants.GRID_COLUMNS,
      gutter: { x: $r('app.float.space_l') },
      breakpoints: {
        value: BreakpointConstants.WINDOW_BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    }) {
      GridCol({
        span: { xs: 12, sm: 12, md: 12, lg: 10 },
        offset: { xs: 0, sm: 0, md: 0, lg: 1 }
      }) {
        Column() {
          PageTopSpacer({ underTitleBar: this.underTitleBar })
          FoldSplitContainer({
            primary: () => {
              this.primaryRegion()
            },
            secondary: () => {
              this.secondaryRegion()
            },
            extra: () => {
              this.extraRegion()
            },
            expandedLayoutOptions: this.expandedLayoutOptions,
            hoverModeLayoutOptions: this.hoverLayoutOptions,
            foldedLayoutOptions: this.foldedLayoutOptions,
            animationOptions: null,
            onHoverStatusChange: (status: HoverModeStatus) => {
              this.hoverMode = status.isHoverMode;
            }
          })
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.pageWidth = Number.parseFloat(String(newArea.width));
          this.pageHeight = Number.parseFloat(String(newArea.height));
        })
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
