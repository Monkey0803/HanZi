/*
 * BookDetailView.ets — 单册详情：按单元列出课文。
 *
 * 结构：水墨册头（InkCard + 年级田字格）→ 单元分组列表。
 * 窄屏用 List + ListItemGroup 吸顶单元头；宽屏用两列瀑布式单元卡。
 * 行数据在 aboutToAppear 预计算，避免 build 期重复拼字符串。
 */

import { Book, Lesson, Unit } from '../../model/CurriculumModels';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { deviceService } from '../../service/DeviceService';
import { safeArea } from '../../service/SafeAreaController';
import { themePalette } from '../../model/ThemePalette';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { gradeGlyphOf } from '../../common/constants/CurriculumConstants';
import { LessonRouteParam } from '../../model/RouteParams';
import { ResponsiveContent } from '../ResponsiveContent';
import { HanziGridCell } from './HanziGridCell';
import { InkCard } from './InkCard';

const PREVIEW_CHARS: number = 8;
const GRADE_TILE: number = 64;

/** 课文行的展示数据（构建期一次性算好）。 */
class LessonRowMeta {
  id: string = '';
  title: string = '';
  preview: string = '';
  truncated: boolean = false;
  charCount: number = 0;
  writeCount: number = 0;

  constructor(lesson: Lesson = new Lesson()) {
    this.id = lesson.id;
    this.title = lesson.title;
    this.charCount = lesson.chars.length;
    let write: number = 0;
    let preview: string = '';
    for (let i = 0; i < lesson.chars.length; i += 1) {
      if (lesson.chars[i].isWrite === 1) {
        write += 1;
      }
      if (i < PREVIEW_CHARS) {
        preview += lesson.chars[i].char;
      }
    }
    this.writeCount = write;
    this.preview = preview;
    this.truncated = lesson.chars.length > PREVIEW_CHARS;
  }
}

@ComponentV2
export struct BookDetailView {
  @Param bookId: string = '';
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  @Local bookInfo: Book | undefined = undefined;
  @Local units: Unit[] = [];
  @Local metas: Map<string, LessonRowMeta> = new Map<string, LessonRowMeta>();
  private evenUnits: Unit[] = [];
  private oddUnits: Unit[] = [];

  aboutToAppear(): void {
    this.bookInfo = curriculumRepository.book(this.bookId);
    this.units = curriculumRepository.unitsOfBook(this.bookId);
    const metas: Map<string, LessonRowMeta> = new Map<string, LessonRowMeta>();
    const even: Unit[] = [];
    const odd: Unit[] = [];
    for (let i = 0; i < this.units.length; i += 1) {
      const unit: Unit = this.units[i];
      for (let j = 0; j < unit.lessons.length; j += 1) {
        metas.set(unit.lessons[j].id, new LessonRowMeta(unit.lessons[j]));
      }
      if (i % 2 === 0) {
        even.push(unit);
      } else {
        odd.push(unit);
      }
    }
    this.metas = metas;
    this.evenUnits = even;
    this.oddUnits = odd;
  }

  private metaOf(lesson: Lesson): LessonRowMeta {
    return this.metas.get(lesson.id) ?? new LessonRowMeta(lesson);
  }

  private previewText(meta: LessonRowMeta): string {
    return meta.truncated ? `${meta.preview}…` : meta.preview;
  }

  /** 会写字数与总字数相同时只显示字数，避免「6 字 · 6 会写」这类冗余。 */
  private lessonMetaText(meta: LessonRowMeta): ResourceStr {
    if (meta.writeCount > 0 && meta.writeCount !== meta.charCount) {
      return $r('app.string.lesson_meta', meta.charCount, meta.writeCount);
    }
    return $r('app.string.lesson_char_count', meta.charCount);
  }

  /** 会写字数与总字数不同时补「会写」，否则只显示单元数。 */
  private bookMetaText(): ResourceStr {
    const unitCount: number = this.units.length;
    const writeCount: number = this.bookInfo?.writeCount ?? 0;
    const charCount: number = this.bookInfo?.charCount ?? 0;
    if (writeCount > 0 && writeCount !== charCount) {
      return $r('app.string.book_meta_extra', unitCount, writeCount);
    }
    return $r('app.string.book_unit_count', unitCount);
  }

  private gradeGlyph(): string {
    return this.bookInfo !== undefined ? gradeGlyphOf(this.bookInfo) : '';
  }

  private termLabel(): ResourceStr {
    const term: number = this.bookInfo?.term ?? 1;
    return term === 1 ? $r('app.string.books_term_up') : $r('app.string.books_term_down');
  }

  private openLesson(lessonId: string): void {
    this.navPathStack.pushPathByName(RouterConstants.PAGE_LESSON, new LessonRouteParam(lessonId, 'book'));
  }

  /** 水墨册头：年级田字格 + 册名 + 学期 / 统计。 */
  @Builder
  bookHeaderCard() {
    Column() {
      InkCard() {
        Column() {
          Row({ space: $r('app.float.space_m') }) {
            HanziGridCell({ char: this.gradeGlyph(), cellSize: GRADE_TILE })
            Column({ space: $r('app.float.space_xs') }) {
              Text(this.bookInfo?.title ?? '')
                .fontSize($r('app.float.font_size_title'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.hm_text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                Text(this.termLabel())
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
                Text($r('app.string.books_lesson_count',
                  this.bookInfo?.lessonCount ?? 0, this.bookInfo?.charCount ?? 0))
                  .fontSize($r('app.float.font_size_caption'))
                  .fontColor($r('app.color.hm_text_secondary'))
                  .margin({ left: $r('app.float.space_s') })
              }
              .width('100%')
              Text(this.bookMetaText())
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding($r('app.float.space_l'))
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .id('book-detail-header')
  }

  /** 单元头本体：印章红竖条 + 「第 N 单元 · M 课」+ 细线。 */
  @Builder
  unitHeader(unit: Unit) {
    Row({ space: $r('app.float.space_s') }) {
      Column()
        .width($r('app.float.unit_bar_width'))
        .height($r('app.float.unit_bar_height'))
        .borderRadius($r('app.float.unit_bar_radius'))
        .backgroundColor($r('app.color.ink_seal'))
      Text($r('app.string.unit_header', unit.index, unit.lessons.length))
        .fontSize($r('app.float.font_size_section'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hm_text_secondary'))
        .maxLines(1)
      Divider()
        .color($r('app.color.ink_line'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: $r('app.float.space_xl'), bottom: $r('app.float.space_s') })
  }

  /** 吸顶用的单元头：不透明纸色底，避免课文行透出。 */
  @Builder
  stickyUnitHeader(unit: Unit) {
    Column() {
      this.unitHeader(unit)
    }
    .width('100%')
    .backgroundColor($r('app.color.hm_page_background'))
    .id(`unit-header-${unit.index}`)
  }

  /** 课文行：课名 + 生字预览 + 字数 / 会写字数，整行可点。 */
  @Builder
  lessonRow(meta: LessonRowMeta, index: number, total: number) {
    Column() {
      if (index > 0) {
        Divider()
          .color($r('app.color.ink_line'))
          .margin({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
      }
      Row({ space: $r('app.float.space_m') }) {
        Column({ space: $r('app.float.space_xxs') }) {
          Text(meta.title)
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          if (meta.charCount > 0) {
            Row({ space: $r('app.float.space_s') }) {
              Text(this.previewText(meta))
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text(this.lessonMetaText(meta))
                .fontSize($r('app.float.font_size_caption'))
                .fontColor($r('app.color.hm_text_secondary'))
                .maxLines(1)
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize($r('app.float.icon_size_small'))
          .fontColor([$r('app.color.hm_text_secondary')])
          .accessibilityLevel('no')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: $r('app.float.lesson_row_min_height') })
      .padding({
        left: $r('app.float.space_l'),
        right: $r('app.float.space_l'),
        top: $r('app.float.space_m'),
        bottom: $r('app.float.space_m')
      })
      .stateStyles({
        pressed: {
          .backgroundColor($r('app.color.hm_divider'))
        },
        normal: {
          .backgroundColor($r('app.color.ink_card'))
        }
      })
      .onClick(() => {
        this.openLesson(meta.id);
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.ink_card'))
    .borderRadius({
      topLeft: index === 0 ? $r('app.float.ink_radius_card') : 0,
      topRight: index === 0 ? $r('app.float.ink_radius_card') : 0,
      bottomLeft: index === total - 1 ? $r('app.float.ink_radius_card') : 0,
      bottomRight: index === total - 1 ? $r('app.float.ink_radius_card') : 0
    })
    .clip(true)
    .accessibilityGroup(true)
    .accessibilityText($r('app.string.lesson_a11y', meta.title, meta.charCount))
    .id(`lesson-row-${meta.id}`)
  }

  /** 宽屏单元卡：透明单元头 + 一整张圆角卡。 */
  @Builder
  unitCard(unit: Unit) {
    Column() {
      this.unitHeader(unit)
      Column() {
        ForEach(unit.lessons, (lesson: Lesson, index: number) => {
          this.lessonRow(this.metaOf(lesson), index, unit.lessons.length)
        }, (lesson: Lesson) => lesson.id)
      }
      .width('100%')
      .backgroundColor($r('app.color.ink_card'))
      .borderRadius($r('app.float.ink_radius_card'))
      .clip(true)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .id(`unit-header-${unit.index}`)
  }

  @Builder
  errorState() {
    Column({ space: $r('app.float.space_m') }) {
      Text($r('app.string.book_not_found'))
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_secondary'))
        .textAlign(TextAlign.Center)
      Button($r('app.string.book_back'))
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontColor(themePalette.accent())
        .id('book-detail-back')
        .onClick(() => {
          this.navPathStack.pop();
        })
    }
    .width('100%')
    .height('100%')
    .padding($r('app.float.space_l'))
    .justifyContent(FlexAlign.Center)
    .id('book-detail-error')
  }

  /** 窄屏：List + ListItemGroup，单元头吸顶。 */
  @Builder
  narrowContent() {
    List() {
      ListItem() {
        Column() {
          this.bookHeaderCard()
        }
        .width('100%')
        .padding({ top: $r('app.float.space_s'), bottom: $r('app.float.space_s') })
      }

      ForEach(this.units, (unit: Unit) => {
        ListItemGroup({ header: this.stickyUnitHeader(unit) }) {
          ForEach(unit.lessons, (lesson: Lesson, index: number) => {
            ListItem() {
              this.lessonRow(this.metaOf(lesson), index, unit.lessons.length)
            }
          }, (lesson: Lesson) => lesson.id)
        }
      }, (unit: Unit) => `${this.bookId}-${unit.index}`)

      ListItem() {
        Row()
          .width('100%')
          .height(safeArea.contentBottomInsetVp)
      }
    }
    .sticky(StickyStyle.Header)
    .width('100%')
    .height('100%')
    .padding({
      top: this.underTitleBar ? safeArea.contentTopInsetVp : 0,
      left: $r('app.float.space_l'),
      right: $r('app.float.space_l')
    })
    .scrollBar(BarState.Off)
    .id('book-detail-list')
  }

  /** 宽屏：两列瀑布式单元卡。 */
  @Builder
  wideContent() {
    Scroll() {
      Column({ space: $r('app.float.space_l') }) {
        Row()
          .width('100%')
          .height(this.underTitleBar ? safeArea.contentTopInsetVp : $r('app.float.space_l'))

        this.bookHeaderCard()

        Row({ space: $r('app.float.space_l') }) {
          Column({ space: $r('app.float.space_l') }) {
            ForEach(this.evenUnits, (unit: Unit) => {
              this.unitCard(unit)
            }, (unit: Unit) => `even-${unit.index}`)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: $r('app.float.space_l') }) {
            ForEach(this.oddUnits, (unit: Unit) => {
              this.unitCard(unit)
            }, (unit: Unit) => `odd-${unit.index}`)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row()
          .width('100%')
          .height(safeArea.contentBottomInsetVp)
      }
      .width('100%')
      .padding({ left: $r('app.float.space_l'), right: $r('app.float.space_l') })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  build() {
    ResponsiveContent() {
      if (this.bookInfo === undefined) {
        this.errorState()
      } else if (deviceService.wide) {
        this.wideContent()
      } else {
        this.narrowContent()
      }
    }
  }
}
