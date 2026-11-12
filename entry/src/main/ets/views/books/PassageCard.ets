/*
 * PassageCard.ets — 识字短文卡片（逐字排版 / 点读 / 朗读）。
 *
 * 逐字渲染是为了让每个汉字都能点击进字详情；拼音开关与生字高亮都由 @Param 控制，
 * 点击与朗读通过 @Event 上报给课详情页，组件本身不持有业务状态。
 */

import { Passage, PassageGlyph } from '../../model/ReadingModels';
import { themePalette } from '../../model/ThemePalette';

@ComponentV2
export struct PassageCard {
  @Param passage: Passage = new Passage();
  @Param glyphs: PassageGlyph[] = [];
  @Param showPinyin: boolean = true;
  @Param playing: boolean = false;
  @Param canSpeak: boolean = false;
  @Event onCharClick: (char: string) => void = () => {};
  @Event onSpeak: (passageId: string, text: string) => void = () => {};

  @Builder
  hanGlyph(glyph: PassageGlyph) {
    Column() {
      if (this.showPinyin) {
        Text(glyph.pinyin)
          .fontSize($r('app.float.reading_pinyin_size'))
          .fontColor($r('app.color.hm_text_secondary'))
          .height($r('app.float.reading_pinyin_height'))
          .maxLines(1)
      }
      Text(glyph.char)
        .fontSize($r('app.float.reading_font_size'))
        .fontColor(glyph.isFocus ? themePalette.accent() : $r('app.color.hanzi_ink'))
        .backgroundColor(glyph.isFocus ? themePalette.tint() : Color.Transparent)
        .borderRadius($r('app.float.space_xxs'))
    }
    .height($r('app.float.reading_glyph_height'))
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: $r('app.float.reading_glyph_gap'), bottom: $r('app.float.reading_line_gap') })
    .accessibilityLevel('no')
    .onClick(() => {
      this.onCharClick(glyph.char);
    })
  }

  @Builder
  markGlyph(glyph: PassageGlyph) {
    Column() {
      Text(glyph.char)
        .fontSize($r('app.float.reading_font_size'))
        .fontColor($r('app.color.hanzi_ink'))
    }
    .height($r('app.float.reading_glyph_height'))
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: $r('app.float.reading_glyph_gap'), bottom: $r('app.float.reading_line_gap') })
    .accessibilityLevel('no')
  }

  @Builder
  speakButton() {
    Row({ space: $r('app.float.space_xxs') }) {
      SymbolGlyph($r('sys.symbol.speaker_wave_2'))
        .fontSize($r('app.float.icon_size_small'))
        .fontColor([this.playing ? themePalette.accent() : $r('app.color.hm_text_secondary')])
      Text(this.playing ? $r('app.string.reading_stop') : $r('app.string.reading_speak'))
        .fontSize($r('app.float.font_size_caption'))
        .fontColor(this.playing ? themePalette.accent() : $r('app.color.hm_text_secondary'))
    }
    .padding({
      left: $r('app.float.space_s'),
      right: $r('app.float.space_s'),
      top: $r('app.float.space_xxs'),
      bottom: $r('app.float.space_xxs')
    })
    .borderRadius($r('app.float.radius_chip'))
    .backgroundColor($r('app.color.hm_divider'))
    .onClick(() => {
      this.onSpeak(this.passage.id, this.passage.text);
    })
  }

  build() {
    Column({ space: $r('app.float.space_xs') }) {
      Row({ space: $r('app.float.space_s') }) {
        if (this.passage.title.length > 0) {
          Text(this.passage.title)
            .fontSize($r('app.float.font_size_body'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.hm_text_primary'))
            .layoutWeight(1)
        } else {
          Blank()
            .layoutWeight(1)
        }
        if (this.canSpeak) {
          this.speakButton()
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.glyphs, (glyph: PassageGlyph) => {
          if (glyph.isHan) {
            this.hanGlyph(glyph)
          } else {
            this.markGlyph(glyph)
          }
        }, (glyph: PassageGlyph, index: number) => `${this.passage.id}-${index}-${glyph.char}`)
      }
      .width('100%')
      .accessibilityText($r('app.string.reading_a11y', this.passage.title))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding($r('app.float.space_m'))
    .backgroundColor($r('app.color.hanzi_card'))
    .borderRadius($r('app.float.radius_card'))
  }
}
