/*
 * PracticeView.ets — 全屏专注练字（对应 animCJK 的 Size：把画布放到最大）。
 *
 * 画布尺寸由容器实际区域计算（手机约 300vp，平板最多 480vp）；
 * 宽屏左右分栏：左侧画布，右侧字卡信息。
 */

import { common } from '@kit.AbilityKit';
import { CharacterEntry, WordEntry } from '../../model/CurriculumModels';
import { StrokeData, StrokeTheme } from '../../model/StrokeModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { hanziDataRepository } from '../../service/HanziDataRepository';
import { progressStore } from '../../service/ProgressStore';
import { StrokeThemeFactory } from '../../service/StrokeThemeFactory';
import { deviceService } from '../../service/DeviceService';
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
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';

const AREA_MARGIN: number = 32;
const CONTROL_RESERVE: number = 190;
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
  @Local strokeIndex: number = 0;
  @Local mistakes: number = 0;
  @Local selectedStroke: number = -1;
  /** 本次描红开始时间；0 表示未开始。 */
  @Local quizStartAt: number = 0;

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

  private words(): WordEntry[] {
    return curriculumRepository.wordsFor(this.char).slice(0, 5);
  }

  private applyArea(width: number, height: number): void {
    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
      return;
    }
    const limitWidth: number = width - AREA_MARGIN;
    const limitHeight: number = height - CONTROL_RESERVE;
    let size: number = Math.min(limitWidth, limitHeight);
    if (!Number.isFinite(size) || size <= 0) {
      return;
    }
    size = Math.max(220, Math.min(480, size));
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
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onAreaChange((oldArea: Area, newArea: Area) => {
      const width: number = Number.parseFloat(`${newArea.width}`);
      const height: number = Number.parseFloat(`${newArea.height}`);
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
    .width('100%')
  }

  @Builder
  actionRow() {
    Row({ space: $r('app.float.space_m') }) {
      Button($r('app.string.practice_play'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.selectedStroke = -1;
          this.playTrigger += 1;
        })
      Button($r('app.string.practice_quiz'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.mistakes = 0;
          this.quizStartAt = Date.now();
          this.selectedStroke = -1;
          this.quizTrigger += 1;
        })
      Button($r('app.string.practice_reset'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .layoutWeight(1)
        .enabled(this.strokeData !== undefined)
        .onClick(() => {
          this.selectedStroke = -1;
          this.strokeIndex = 0;
          this.mistakes = 0;
          this.quizStartAt = Date.now();
          this.quizTrigger += 1;
          this.playTrigger += 1;
        })
    }
    .width('100%')
  }

  @Builder
  infoPanel() {
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
      if (this.entry() !== undefined) {
        Text(`${this.entry()?.radical ?? ''}  ${this.entry()?.decomposition ?? ''}`)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
      }
      if (this.words().length > 0) {
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding($r('app.float.space_l'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.radius_card'))
  }

  build() {
    ResponsiveContent() {
      Column({ space: $r('app.float.space_s') }) {
        PageTopSpacer({ underTitleBar: this.underTitleBar })

        if (deviceService.wide) {
          Row({ space: $r('app.float.space_l') }) {
            this.canvasCard()
            Column() {
              this.infoPanel()
            }
            .width(260)
            .height('100%')
            .justifyContent(FlexAlign.Start)
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          this.canvasCard()
        }

        this.toolsRow()
        this.actionRow()

        Blank().height(safeArea.contentBottomInsetVp)
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    }
  }
}
