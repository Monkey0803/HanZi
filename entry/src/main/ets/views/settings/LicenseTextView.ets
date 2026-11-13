/* LicenseTextView.ets — 当前数据包中的许可全文。 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataRootResolver } from '../../service/DataRootResolver';
import { safeArea } from '../../service/SafeAreaController';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';

@ComponentV2
export struct LicenseTextView {
  @Param fileName: string = '';
  @Param underTitleBar: boolean = true;
  @Local content: string = '';
  @Local failed: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined || this.fileName.indexOf('/') >= 0 || this.fileName.indexOf('..') >= 0) {
      this.failed = true;
      return;
    }
    try {
      this.content = await dataRootResolver.readRootText(context, `licenses/${this.fileName}`);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`LicenseTextView.load failed: ${error.code}`);
      this.failed = true;
    }
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column() {
          PageTopSpacer({ underTitleBar: this.underTitleBar })
          Text(this.failed ? $r('app.string.document_load_failed') : this.content)
            .fontSize($r('app.float.font_size_caption'))
            .fontColor($r('app.color.hm_text_primary'))
            .width('100%')
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
