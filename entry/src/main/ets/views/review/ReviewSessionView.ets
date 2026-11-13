/*
 * ReviewSessionView.ets — 复习会话：翻卡 + 自评 + 结束总结。
 *
 * 队列与评分由 ReviewViewModel / ProgressStore 处理；本页只负责渲染与事件上报。
 */

import { common } from '@kit.AbilityKit';
import { ReviewCard, ReviewRating } from '../../model/ProgressModels';
import { ReviewMode } from '../../model/RouteParams';
import { ReviewCardMode, ReviewConstants } from '../../common/constants/ReviewConstants';
import { reviewViewModel, ReviewViewModel } from '../../viewmodel/ReviewViewModel';
import { progressStore } from '../../service/ProgressStore';
import { themePalette } from '../../model/ThemePalette';
import { safeArea } from '../../service/SafeAreaController';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';
import { InkCard } from '../books/InkCard';

@ComponentV2
export struct ReviewSessionView {
  @Param mode: string = ReviewMode.ALL;
  @Param bookId: string = '';
  @Param unit: number = 0;
  @Param limit: number = ReviewConstants.DEFAULT_LIMIT;
  @Param cardMode: string = ReviewCardMode.CHAR;
  @Param navPathStack: NavPathStack = new NavPathStack();

  private viewModel: ReviewViewModel = reviewViewModel;

  aboutToAppear(): void {
    this.viewModel.start(this.mode, this.bookId, this.unit, this.limit, this.cardMode);
  }

  private card(): ReviewCard | undefined {
    return this.viewModel.current();
  }

  private modeLabel(): ResourceStr {
    return this.viewModel.cardMode === ReviewCardMode.PINYIN
      ? $r('app.string.review_mode_pinyin')
      : $r('app.string.review_mode_char');
  }

  private pinyinText(): ResourceStr {
    const card: ReviewCard | undefined = this.card();
    if (card === undefined || card.pinyin.length === 0) {
      return $r('app.string.review_accuracy_empty');
    }
    return card.pinyin;
  }

  private charText(): string {
    const card: ReviewCard | undefined = this.card();
    return card !== undefined ? card.char : '';
  }

  private wordText(): string {
    const card: ReviewCard | undefined = this.card();
    return card !== undefined ? card.word : '';
  }

  private rate(rating: ReviewRating): void {
    this.viewModel.rate(rating);
  }

  private retry(): void {
    const host: common.Context | undefined = this.getUIContext().getHostContext();
    if (host === undefined) {
      return;
    }
    progressStore.load(host).then(() => {
      this.viewModel.start(this.mode, this.bookId, this.unit, this.limit, this.cardMode);
    });
  }

  @Builder
  cardFace() {
    Column({ space: $r('app.float.space_m') }) {
      if (this.viewModel.cardMode === ReviewCardMode.PINYIN) {
        Text(this.pinyinText())
          .fontSize($r('app.float.review_number_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor(themePalette.accent())
        if (this.viewModel.flipped) {
          Text(this.charText())
            .fontSize($r('app.float.review_char_size'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.hanzi_ink'))
        }
      } else {
        Text(this.charText())
          .fontSize($r('app.float.review_char_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hanzi_ink'))
        if (this.viewModel.flipped) {
          Text(this.pinyinText())
            .fontSize($r('app.float.font_size_title'))
            .fontColor($r('app.color.hm_text_secondary'))
        }
      }

      if (this.viewModel.flipped && this.wordText().length > 0) {
        Text(this.wordText())
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
      }

      Text($r('app.string.review_card_flip_hint'))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
    }
    .width('100%')
    .height($r('app.float.review_card_height'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  sessionBody() {
    Column({ space: $r('app.float.space_l') }) {
      Row({ space: $r('app.float.space_s') }) {
        Text($r('app.string.review_progress', this.viewModel.index + 1, this.viewModel.cards.length))
          .fontSize($r('app.float.font_size_caption'))
          .fontColor($r('app.color.hm_text_secondary'))
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
      .alignItems(VerticalAlign.Center)

      Column() {
        InkCard() {
          this.cardFace()
        }
      }
      .width('100%')
      .id('review_card')
      .onClick(() => {
        this.viewModel.flip();
      })

      Row({ space: $r('app.float.space_m') }) {
        Button($r('app.string.review_again'))
          .buttonStyle(ButtonStyleMode.NORMAL)
          .fontColor($r('app.color.hanzi_error'))
          .layoutWeight(1)
          .enabled(this.viewModel.flipped)
          .id('review_again')
          .onClick(() => {
            this.rate(ReviewRating.AGAIN);
          })
        Button($r('app.string.review_good'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(themePalette.fill())
          .fontColor($r('app.color.hm_on_brand'))
          .layoutWeight(1)
          .enabled(this.viewModel.flipped)
          .id('review_good')
          .onClick(() => {
            this.rate(ReviewRating.GOOD);
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  summaryBody() {
    Column() {
      InkCard() {
        Column({ space: $r('app.float.space_m') }) {
        Text($r('app.string.review_summary_title'))
          .fontSize($r('app.float.font_size_title'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.hm_text_primary'))
          .width('100%')
        Text($r('app.string.review_summary_reviewed', this.viewModel.reviewedCount))
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
          .width('100%')
        Text($r('app.string.review_summary_again', this.viewModel.againCount))
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_secondary'))
          .width('100%')
        Button($r('app.string.review_done'))
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(themePalette.fill())
          .fontColor($r('app.color.hm_on_brand'))
          .width('100%')
          .id('review_done')
          .onClick(() => {
            this.navPathStack.pop();
          })
      }
      .width('100%')
      .padding($r('app.float.space_l'))
      .alignItems(HorizontalAlign.Start)
    }
    }
    .width('100%')
  }

  @Builder
  unavailableBody() {
    Column({ space: $r('app.float.space_m') }) {
      Text($r('app.string.review_unavailable'))
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_primary'))
        .width('100%')
      Button($r('app.string.review_retry'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .onClick(() => {
          this.retry();
        })
      Button($r('app.string.review_done'))
        .buttonStyle(ButtonStyleMode.EMPHASIZED)
        .backgroundColor(themePalette.fill())
        .fontColor($r('app.color.hm_on_brand'))
        .width('100%')
        .onClick(() => {
          this.navPathStack.pop();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    ResponsiveContent() {
      Column({ space: $r('app.float.space_l') }) {
        PageTopSpacer()

        if (this.viewModel.unavailable) {
          this.unavailableBody()
        } else if (this.viewModel.finished && !this.viewModel.empty) {
          this.summaryBody()
        } else if (this.viewModel.empty) {
          Column({ space: $r('app.float.space_m') }) {
            Text($r('app.string.review_none_due'))
              .fontSize($r('app.float.font_size_body'))
              .fontColor($r('app.color.hm_text_secondary'))
              .width('100%')
            Button($r('app.string.review_done'))
              .buttonStyle(ButtonStyleMode.EMPHASIZED)
              .backgroundColor(themePalette.fill())
              .fontColor($r('app.color.hm_on_brand'))
              .width('100%')
              .onClick(() => {
                this.navPathStack.pop();
              })
          }
          .width('100%')
        } else {
          this.sessionBody()
        }

        Blank().height(safeArea.contentBottomInsetVp)
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    }
  }
}
