/*
 * ReviewTabView.ets — 复习页签。
 *
 * 数据来自 ProgressStore（RDB）：今日复习主卡、四项统计、错题本预览。
 * 没有进度时显示空态并引导去课本；点「开始复习」进入 ReviewSessionView。
 */

import { common } from '@kit.AbilityKit';
import { scrollers } from '../../service/ScrollerRegistry';
import { themePalette } from '../../model/ThemePalette';
import { safeArea } from '../../service/SafeAreaController';
import { deviceService } from '../../service/DeviceService';
import { progressStore } from '../../service/ProgressStore';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { ReviewCardMode, ReviewConstants } from '../../common/constants/ReviewConstants';
import { CharRouteParam, ReviewMode, ReviewRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';
import { PaperBackground } from '../PaperBackground';
import { InkCard } from '../books/InkCard';
import { HanziGridCell } from '../books/HanziGridCell';
import { StrokeToggleChip } from '../practice/StrokeToggleChip';
import { ReviewStatCard } from './ReviewStatCard';
import { appSettings } from '../../model/AppSettings';

const EMPTY_CELL_SIZE: number = 72;
const MISTAKE_CELL_SIZE: number = 44;

@ComponentV2
export struct ReviewTabView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;
  @Event onGoBooks: () => void = () => {};

  @Local cardMode: string = ReviewCardMode.CHAR;

  private context(): common.Context | undefined {
    return this.getUIContext().getHostContext();
  }

  private accuracyText(): ResourceStr {
    if (progressStore.attemptCount === 0) {
      return $r('app.string.review_accuracy_empty');
    }
    return `${progressStore.accuracy}%`;
  }

  private dueTitle(): ResourceStr {
    if (progressStore.dueCount > 0) {
      return $r('app.string.review_due_unit', progressStore.dueCount);
    }
    return $r('app.string.review_due_zero');
  }

  private startLabel(): ResourceStr {
    return progressStore.dueCount > 0 ? $r('app.string.review_start') : $r('app.string.review_consolidate');
  }

  private previewMistakes(): string[] {
    return progressStore.mistakeChars.slice(0, ReviewConstants.MISTAKE_PREVIEW);
  }

  private startSession(): void {
    if (!progressStore.ready || progressStore.learnedCount === 0) {
      return;
    }
    this.navPathStack.pushPathByName(RouterConstants.PAGE_REVIEW_SESSION,
      new ReviewRouteParam(ReviewMode.ALL, '', 0, ReviewConstants.DEFAULT_LIMIT, this.cardMode));
  }

  private openChar(char: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_CHAR,
      new CharRouteParam(char, progressStore.lessonOf(char)));
  }

  private openMistakes(): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_MISTAKES, '');
  }

  private retryProgress(): void {
    const host: common.Context | undefined = this.context();
    if (host !== undefined) {
      progressStore.load(host);
    }
  }

  @Builder
  emptyState() {
    Column({ space: $r('app.float.space_m') }) {
      Row({ space: $r('app.float.space_m') }) {
        HanziGridCell({ char: '复', cellSize: EMPTY_CELL_SIZE })
        Column({ space: $r('app.float.space_xs') }) {
          Text($r('app.string.review_empty_title'))
            .fontSize($r('app.float.font_size_body'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.hm_text_primary'))
            .width('100%')
          Text($r('app.string.review_empty_desc'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Button($r('app.string.review_go_books'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .width('100%')
        .id('review_go_books')
        .onClick(() => {
          this.onGoBooks();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  readyState() {
    Column({ space: $r('app.float.space_m') }) {
      Row({ space: $r('app.float.space_s') }) {
        Text(`${progressStore.dueCount}`)
          .fontSize($r('app.float.review_number_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor(themePalette.accent())
        Column({ space: $r('app.float.space_xxs') }) {
          Text(this.dueTitle())
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
            .width('100%')
          if (progressStore.dueCount === 0) {
            Text($r('app.string.review_none_due'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Progress({
        value: Math.min(progressStore.todayCount, appSettings.dailyGoal),
        total: appSettings.dailyGoal,
        type: ProgressType.Linear
      })
        .width('100%')
        .color(themePalette.accent())

      Row({ space: $r('app.float.space_s') }) {
        Column() {
          StrokeToggleChip({
            label: $r('app.string.review_mode_char'),
            active: this.cardMode === ReviewCardMode.CHAR,
            onTap: () => {
              this.cardMode = ReviewCardMode.CHAR;
            }
          })
        }
        .id('review_mode_char')

        Column() {
          StrokeToggleChip({
            label: $r('app.string.review_mode_pinyin'),
            active: this.cardMode === ReviewCardMode.PINYIN,
            onTap: () => {
              this.cardMode = ReviewCardMode.PINYIN;
            }
          })
        }
        .id('review_mode_pinyin')
      }
      .width('100%')

      Button(this.startLabel())
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .width('100%')
        .id('review_start')
        .onClick(() => {
          this.startSession();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  heroCard() {
    Column() {
      InkCard() {
        Column({ space: $r('app.float.space_m') }) {
        Row({ space: $r('app.float.space_s') }) {
          Text($r('app.string.review_today_title'))
            .fontSize($r('app.float.font_size_title'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.hm_text_primary'))
            .layoutWeight(1)
          Text($r('app.string.review_today_progress', progressStore.todayCount, appSettings.dailyGoal))
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

        if (progressStore.loading && !progressStore.ready) {
          Row({ space: $r('app.float.space_s') }) {
            LoadingProgress()
              .width($r('app.float.icon_size_small'))
              .height($r('app.float.icon_size_small'))
              .color(themePalette.accent())
            Text($r('app.string.review_loading'))
              .fontSize($r('app.float.font_size_caption'))
              .fontColor($r('app.color.hm_text_secondary'))
          }
          .width('100%')
        } else if (!progressStore.ready) {
          Column({ space: $r('app.float.space_s') }) {
            Text($r('app.string.review_unavailable'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_primary'))
              .width('100%')
            if (progressStore.errorMessage.length > 0) {
              Text(progressStore.errorMessage)
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .width('100%')
            }
            Button($r('app.string.review_retry'))
              .buttonStyle(ButtonStyleMode.NORMAL)
              .fontColor(themePalette.accent())
              .onClick(() => {
                this.retryProgress();
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else if (progressStore.learnedCount === 0) {
          this.emptyState()
        } else {
          this.readyState()
        }
      }
      .width('100%')
      .padding($r('app.float.space_l'))
      .alignItems(HorizontalAlign.Start)
    }
    }
    .width('100%')
  }

  @Builder
  statsGrid() {
    if (deviceService.wide) {
      Row({ space: $r('app.float.space_s') }) {
        ReviewStatCard({ value: `${progressStore.dueCount}`, label: $r('app.string.review_due_label') })
        ReviewStatCard({ value: `${progressStore.learnedCount}`, label: $r('app.string.review_learned') })
        ReviewStatCard({ value: this.accuracyText(), label: $r('app.string.review_accuracy') })
        ReviewStatCard({
          value: $r('app.string.review_streak_value', progressStore.streakDays),
          label: $r('app.string.review_streak')
        })
      }
      .width('100%')
    } else {
      Column({ space: $r('app.float.space_s') }) {
        Row({ space: $r('app.float.space_s') }) {
          ReviewStatCard({ value: `${progressStore.dueCount}`, label: $r('app.string.review_due_label') })
          ReviewStatCard({ value: `${progressStore.learnedCount}`, label: $r('app.string.review_learned') })
        }
        .width('100%')
        Row({ space: $r('app.float.space_s') }) {
          ReviewStatCard({ value: this.accuracyText(), label: $r('app.string.review_accuracy') })
          ReviewStatCard({
            value: $r('app.string.review_streak_value', progressStore.streakDays),
            label: $r('app.string.review_streak')
          })
        }
        .width('100%')
      }
      .width('100%')
    }
  }

  @Builder
  mistakeSection() {
    Column({ space: $r('app.float.space_s') }) {
      Row({ space: $r('app.float.space_s') }) {
        Column()
          .width($r('app.float.space_xs'))
          .height($r('app.float.font_size_title'))
          .borderRadius($r('app.float.space_xxs'))
          .backgroundColor($r('app.color.ink_seal'))
        Text($r('app.string.review_mistakes_title'))
          .fontSize($r('app.float.font_size_section'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hm_text_primary'))
          .layoutWeight(1)
        Text(`${progressStore.mistakeCount}`)
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
        if (progressStore.mistakeChars.length > 0) {
          Button($r('app.string.review_mistakes_all'))
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontSize($r('app.float.font_size_caption'))
            .fontColor(themePalette.accent())
            .onClick(() => {
              this.openMistakes();
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (progressStore.mistakeChars.length === 0) {
        Text($r('app.string.review_mistakes_empty'))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.previewMistakes(), (char: string, index: number) => {
            Column() {
              HanziGridCell({ char: char, cellSize: MISTAKE_CELL_SIZE })
            }
            .id(`review_mistake_${index}`)
            .margin({ right: $r('app.float.space_s'), bottom: $r('app.float.space_s') })
            .onClick(() => {
              this.openChar(char);
            })
          }, (char: string) => char)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding($r('app.float.space_l'))
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.ink_card'))
    .borderRadius($r('app.float.ink_radius_card'))
    .border({ width: 1, color: $r('app.color.ink_line') })
  }

  build() {
    Stack() {
      PaperBackground()

      ResponsiveContent() {
        Scroll(scrollers.review) {
          Column({ space: $r('app.float.space_l') }) {
            PageTopSpacer({ underTitleBar: this.underTitleBar })

            this.heroCard()
            this.statsGrid()
            this.mistakeSection()

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
    .width('100%')
    .height('100%')
  }
}
