/* PrivacyPolicyView.ets — 应用内隐私政策。 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataRootResolver } from '../../service/DataRootResolver';
import { safeArea } from '../../service/SafeAreaController';
import { ResponsiveContent } from '../ResponsiveContent';
import { PageTopSpacer } from '../PageTopSpacer';

@ComponentV2
export struct PrivacyPolicyView {
  @Param underTitleBar: boolean = true;
  @Local content: string = '';
  @Local failed: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.failed = true;
      return;
    }
    try {
      this.content = await dataRootResolver.readText(context, 'privacy_policy.txt');
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`PrivacyPolicyView.load failed: ${error.code}`);
      this.failed = true;
    }
  }

  build() {
    ResponsiveContent() {
      Scroll() {
        Column() {
          PageTopSpacer({ underTitleBar: this.underTitleBar })
          Text(this.failed ? $r('app.string.document_load_failed') : this.content)
            .fontSize($r('app.float.font_size_body'))
            .fontColor($r('app.color.hm_text_primary'))
            .lineHeight($r('app.float.font_size_title'))
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
