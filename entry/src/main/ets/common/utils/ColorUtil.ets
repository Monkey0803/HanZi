/*
 * ColorUtil.ets — 资源色 → Canvas 可用的 #RRGGBB。
 *
 * CanvasRenderingContext2D 的 fillStyle / strokeStyle 只接受字符串，
 * 资源色需要经 resourceManager 取值后转成十六进制；alpha 由 globalAlpha 控制。
 */

import { common } from '@kit.AbilityKit';

export class ColorUtil {
  /** 0xAARRGGBB（或 0xRRGGBB）→ '#RRGGBB'。 */
  static argbToHex(value: number): string {
    const rgb: number = value & 0xFFFFFF;
    return '#' + rgb.toString(16).padStart(6, '0').toUpperCase();
  }

  /** 按资源 id 取当前配置（深浅色自动生效）下的颜色。 */
  static fromResource(context: common.Context, resId: number): string {
    const value: number = context.resourceManager.getColorSync(resId);
    return ColorUtil.argbToHex(value);
  }
}
