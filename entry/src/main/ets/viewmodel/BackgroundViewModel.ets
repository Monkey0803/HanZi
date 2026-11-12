/*
 * BackgroundViewModel.ets — 全局背景图（@ObservedV2，ImageKit 接入点）。
 *
 * 用 ImageKit 把 app.media.app_background 解码成 PixelMap：
 * - 按屏幕物理像素尺寸降采样（desiredSize），避免大图解出超大内存（符合 BG-04）；
 * - 解码完成前先用资源本身兜底，解码完成后无缝换成 PixelMap；
 * - 页面销毁时释放 PixelMap。
 */

import { common } from '@kit.AbilityKit';
import { display } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ImageSupport } from '../service/ImageSupport';

const FALLBACK: Resource = $r('app.media.app_background');

@ObservedV2
export class BackgroundViewModel {
  /** 背景来源：解码完成前是资源，完成后是 PixelMap。 */
  @Trace background: image.PixelMap | ResourceStr = FALLBACK;
  /** 已解码的 PixelMap 句柄，用于释放。 */
  private decoded: image.PixelMap | undefined = undefined;

  init(context: common.Context): void {
    this.load(context);
  }

  release(): void {
    const current: image.PixelMap | undefined = this.decoded;
    if (current !== undefined) {
      current.release();
      this.decoded = undefined;
    }
    this.background = FALLBACK;
  }

  private async load(context: common.Context): Promise<void> {
    try {
      const screen: display.Display = display.getDefaultDisplaySync();
      const target: image.Size = { width: screen.width, height: screen.height };
      const pixelMap: image.PixelMap | undefined =
        await ImageSupport.decodeMedia(context, FALLBACK.id, false, target);
      if (pixelMap !== undefined) {
        this.decoded = pixelMap;
        this.background = pixelMap;
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('BackgroundViewModel.load failed: ' + error.code.toString());
    }
  }
}

/** 全局唯一实例。 */
export const backgroundViewModel: BackgroundViewModel = new BackgroundViewModel();
