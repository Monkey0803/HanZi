/*
 * HanziGridCell.ets — 「田字格 + 一个大字」的展示单元（首页每日一字 / 册卡年级字）。
 *
 * 格线用 Canvas 复用 StrokeRenderer.drawGrid（与笔顺页一致的画法），字用 Text 叠在上层，
 * 避免 Canvas 画字的字体栅格差异；颜色全部走资源，深色模式自动生效。
 */

import { common } from '@kit.AbilityKit';
import { StrokeRenderer } from '../../service/StrokeRenderer';
import { StrokeTheme } from '../../model/StrokeModels';
import { ColorUtil } from '../../common/utils/ColorUtil';
import { GridStyleId } from '../../common/constants/StrokeConstants';

@ComponentV2
export struct HanziGridCell {
  /** 格内大字。 */
  @Param char: string = '';
  /** 格子边长（vp）。 */
  @Param cellSize: number = 44;
  /** 字格样式：田 / 米 / 九宫 / 无。 */
  @Param gridStyle: string = GridStyleId.TIAN;
  /** 字号；0 时按格宽推算。 */
  @Param charSize: number = 0;

  private ctx: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));

  @Monitor('cellSize', 'gridStyle')
  onCellChange(): void {
    this.drawGridLines();
  }

  private drawGridLines(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const theme: StrokeTheme = new StrokeTheme();
    theme.grid = ColorUtil.fromResource(context, $r('app.color.hanzi_grid').id);
    this.ctx.clearRect(0, 0, this.cellSize, this.cellSize);
    StrokeRenderer.drawGrid(this.ctx, this.cellSize, 1, theme, this.gridStyle);
  }

  private resolvedCharSize(): number {
    return this.charSize > 0 ? this.charSize : Math.round(this.cellSize * 0.62);
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width(this.cellSize)
        .height(this.cellSize)
        .onReady(() => {
          this.drawGridLines();
        })
      Text(this.char)
        .fontSize(this.resolvedCharSize())
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hanzi_ink'))
        .textAlign(TextAlign.Center)
        .width(this.cellSize)
    }
    .width(this.cellSize)
    .height(this.cellSize)
  }
}
