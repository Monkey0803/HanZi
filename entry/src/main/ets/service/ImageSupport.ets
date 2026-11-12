/*
 * ImageSupport.ets — ImageKit（@kit.ImageKit）通用封装。
 *
 * 基础模板与图片领域共用：
 * - 动图（GIF / WebP）按**文件头**识别（不看扩展名：单帧 GIF / 静态 WebP 很常见）；
 * - 解码成 PixelMap，可按目标尺寸降采样（desiredSize），并可选 HDR 动态范围；
 * - 支持从媒体资源（$r('app.media.*')）、rawfile、或已创建的 ImageSource 解码。
 */

import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ImageSupport {
  /** 文件头判定：GIF87a/GIF89a、或 RIFF....WEBP。 */
  static isAnimatedFormat(header: ArrayBuffer): boolean {
    const bytes: Uint8Array = new Uint8Array(header);
    if (bytes.length >= 6) {
      const isGif: boolean = bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46;
      if (isGif) {
        return true;
      }
    }
    if (bytes.length >= 12) {
      const isRiff: boolean = bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46;
      const isWebp: boolean = bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50;
      if (isRiff && isWebp) {
        return true;
      }
    }
    return false;
  }

  /** 解码成 PixelMap；hdr=true 时请求 HDR 动态范围（无尺寸约束）。 */
  static async decode(source: image.ImageSource, hdr: boolean): Promise<image.PixelMap | undefined> {
    return await ImageSupport.decodeInternal(source, hdr, undefined);
  }

  /** 按目标像素尺寸解码媒体资源（$r('app.media.*')）：降采样可降低解码内存（BG-04）。 */
  static async decodeMedia(context: common.Context, resId: number, hdr: boolean,
    desiredSize?: image.Size): Promise<image.PixelMap | undefined> {
    try {
      const bytes: Uint8Array = await context.resourceManager.getMediaContent(resId);
      return await ImageSupport.decodeBuffer(bytes, hdr, desiredSize);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('ImageSupport.decodeMedia failed: ' + error.code.toString());
      return undefined;
    }
  }

  /** 解码 rawfile 图片（全屏预览用：可不传 desiredSize 拿到全分辨率）。 */
  static async decodeRawFile(context: common.Context, path: string, hdr: boolean,
    desiredSize?: image.Size): Promise<image.PixelMap | undefined> {
    try {
      const bytes: Uint8Array = await context.resourceManager.getRawFileContent(path);
      return await ImageSupport.decodeBuffer(bytes, hdr, desiredSize);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('ImageSupport.decodeRawFile failed: ' + error.code.toString());
      return undefined;
    }
  }

  /** 从字节缓冲解码。 */
  static async decodeBuffer(bytes: Uint8Array, hdr: boolean,
    desiredSize?: image.Size): Promise<image.PixelMap | undefined> {
    try {
      const buffer: ArrayBuffer = bytes.buffer as ArrayBuffer;
      const source: image.ImageSource = image.createImageSource(buffer);
      const pixelMap: image.PixelMap | undefined = await ImageSupport.decodeInternal(source, hdr, desiredSize);
      await source.release();
      return pixelMap;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('ImageSupport.decodeBuffer failed: ' + error.code.toString());
      return undefined;
    }
  }

  private static async decodeInternal(source: image.ImageSource, hdr: boolean,
    desiredSize?: image.Size): Promise<image.PixelMap | undefined> {
    try {
      const options: image.DecodingOptions = {
        desiredDynamicRange: hdr ? image.DecodingDynamicRange.HDR : image.DecodingDynamicRange.SDR
      };
      if (desiredSize !== undefined) {
        options.desiredSize = desiredSize;
      }
      return await source.createPixelMap(options);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('ImageSupport.decode failed: ' + error.code.toString());
      return undefined;
    }
  }
}
