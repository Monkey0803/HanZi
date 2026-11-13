/* AboutDataView.ets — 当前数据模式、版本、统计与许可入口。 */

import { LicenseRouteParam } from '../../model/RouteParams';
import { RouterConstants } from '../../common/constants/RouterConstants';
import { appBootstrap } from '../../service/AppBootstrap';
import { curriculumRepository } from '../../service/CurriculumRepository';
import { safeArea } from '../../service/SafeAreaController';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';

const LICENSE_FILES: string[] = [
  'ARPHICPL.txt',
  'CHINESE_TEXTBOOK_MIT.txt',
  'LGPL.txt',
  'LICENSE-hanzi-writer.txt'
];

@ComponentV2
export struct AboutDataView {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param underTitleBar: boolean = true;

  @Builder
  dataRow(label: ResourceStr, value: string) {
    Row({ space: $r('app.float.space_m') }) {
      Text(label)
        .fontSize($r('app.float.font_size_body'))
        .fontColor($r('app.color.hm_text_primary'))
        .layoutWeight(1)
      Text(value)
        .fontSize($r('app.float.font_size_caption'))
        .fontColor($r('app.color.hm_text_secondary'))
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding($r('app.float.space_m'))
  }

  @Builder
  licenseRow(fileName: string, index: number) {
    Column() {
      if (index > 0) {
        Divider().color($r('app.color.hm_divider'))
      }
      Row() {
        Text(fileName)
          .fontSize($r('app.float.font_size_body'))
          .fontColor($r('app.color.hm_text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize($r('app.float.icon_size_small'))
          .fontColor([$r('app.color.hm_text_secondary')])
      }
      .width('100%')
      .padding($r('app.float.space_m'))
      .onClick(() => {
        this.navPathStack.pushPathByName(RouterConstants.PAGE_LICENSE, new LicenseRouteParam(fileName));
      })
    }
    .width('100%')
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column({ space: $r('app.float.space_l') }) {
          PageTopSpacer({ underTitleBar: this.underTitleBar })
          Column() {
            this.dataRow($r('app.string.about_data_mode'), appBootstrap.dataMode)
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_version'), curriculumRepository.meta('dataVersion', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_books'), curriculumRepository.meta('books', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_lessons'), curriculumRepository.meta('lessons', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_chars'), curriculumRepository.meta('uniqueChars', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_strokes'), curriculumRepository.meta('strokeChars', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_missing_strokes'),
              curriculumRepository.meta('missingStrokes', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_catalog_chars'),
              curriculumRepository.meta('catalogChars', '-'))
            Divider().color($r('app.color.hm_divider'))
            this.dataRow($r('app.string.about_data_generated'), curriculumRepository.meta('generatedAt', '-'))
          }
          .width('100%')
          .backgroundColor($r('app.color.hm_card_background'))
          .borderRadius($r('app.float.radius_card'))
          .clip(true)
          Text($r('app.string.about_data_source_summary'))
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_secondary'))
            .width('100%')
          Column() {
            ForEach(LICENSE_FILES, (fileName: string, index: number) => {
              this.licenseRow(fileName, index)
            }, (fileName: string) => fileName)
          }
          .width('100%')
          .backgroundColor($r('app.color.hm_card_background'))
          .borderRadius($r('app.float.radius_card'))
          .clip(true)
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
