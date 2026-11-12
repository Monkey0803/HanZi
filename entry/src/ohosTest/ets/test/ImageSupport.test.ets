import { describe, it, expect } from '@ohos/hypium';
import { ImageSupport } from '../../../main/ets/service/ImageSupport';

// 动图识别的纯字节单测：只看文件头，不解码、不碰设备能力。

function headerOf(values: number[]): ArrayBuffer {
  const bytes: Uint8Array = new Uint8Array(values);
  return bytes.buffer as ArrayBuffer;
}

export default function imageSupportTest() {
  describe('ImageSupport.isAnimatedFormat', () => {
    it('detects_gif87a_and_gif89a', 0, () => {
      const gif87a: number[] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61, 0x00];
      const gif89a: number[] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00];
      expect(ImageSupport.isAnimatedFormat(headerOf(gif87a))).assertTrue();
      expect(ImageSupport.isAnimatedFormat(headerOf(gif89a))).assertTrue();
    });

    it('detects_riff_webp', 0, () => {
      const webp: number[] = [0x52, 0x49, 0x46, 0x46, 0x10, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50];
      expect(ImageSupport.isAnimatedFormat(headerOf(webp))).assertTrue();
    });

    it('rejects_png_and_jpeg', 0, () => {
      const png: number[] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      const jpeg: number[] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01];
      expect(ImageSupport.isAnimatedFormat(headerOf(png))).assertFalse();
      expect(ImageSupport.isAnimatedFormat(headerOf(jpeg))).assertFalse();
    });

    it('rejects_short_or_empty_headers_without_throwing', 0, () => {
      const empty: number[] = [];
      const one: number[] = [0x47];
      const riffOnly: number[] = [0x52, 0x49, 0x46, 0x46, 0x00];
      expect(ImageSupport.isAnimatedFormat(headerOf(empty))).assertFalse();
      expect(ImageSupport.isAnimatedFormat(headerOf(one))).assertFalse();
      expect(ImageSupport.isAnimatedFormat(headerOf(riffOnly))).assertFalse();
    });
  });
}
