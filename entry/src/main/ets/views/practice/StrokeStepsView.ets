/*
 * StrokeStepsView.ets — 笔顺步骤条：每格显示「前 i 笔」，点击定位。
 *
 * 只用一张 Canvas（不为每笔创建组件），横向溢出由外层 Scroll 处理。
 */

import { StrokeData, StrokeTheme } from '../../model/StrokeModels';
import { StrokeRenderer } from '../../service/StrokeRenderer';
import {
  STEPS_CELL_PADDING,
  STEPS_CELL_WIDTH,
  STEPS_HEIGHT,
  STEPS_NUMBER_FONT_SIZE
} from '../../common/constants/StrokeConstants';

@ComponentV2
export struct StrokeStepsView {
  @Param data: StrokeData | undefined = undefined;
  @Param selected: number = -1;
  @Param theme: StrokeTheme = new StrokeTheme();
  @Param showNumbers: boolean = true;
  @Event onSelect: (index: number) => void = () => {};

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private redrawTimer: number = -1;

  aboutToDisappear(): void {
    if (this.redrawTimer >= 0) {
      clearTimeout(this.redrawTimer);
      this.redrawTimer = -1;
    }
  }

  @Monitor('data')
  onDataChanged(): void {
    this.scheduleDraw();
  }

  @Monitor('selected')
  onSelectedChanged(): void {
    this.scheduleDraw();
  }

  @Monitor('showNumbers')
  onNumbersChanged(): void {
    this.scheduleDraw();
  }

  private count(): number {
    const data: StrokeData | undefined = this.data;
    return data === undefined ? 0 : data.strokeCount;
  }

  private canvasWidth(): number {
    return Math.max(1, this.count()) * STEPS_CELL_WIDTH;
  }

  /** 尺寸变化后布局才生效，延一帧重绘避免画在旧 surface 上。 */
  private scheduleDraw(): void {
    if (this.redrawTimer >= 0) {
      clearTimeout(this.redrawTimer);
    }
    this.redrawTimer = setTimeout(() => {
      this.redrawTimer = -1;
      this.draw();
    }, 16);
  }

  private draw(): void {
    if (!this.ready) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.ctx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasWidth(), STEPS_HEIGHT);
    const data: StrokeData | undefined = this.data;
    if (data === undefined || data.strokeCount === 0) {
      return;
    }
    const inner: number = Math.min(STEPS_CELL_WIDTH, STEPS_HEIGHT) - 2 * STEPS_CELL_PADDING - 8;
    const scale: number = inner / 1024;
    for (let i = 0; i < data.strokeCount; i += 1) {
      const x0: number = i * STEPS_CELL_WIDTH;
      const active: boolean = i === this.selected;
      if (active) {
        ctx.save();
        ctx.globalAlpha = 0.12;
        ctx.fillStyle = this.theme.active;
        ctx.fillRect(x0 + 1, 1, STEPS_CELL_WIDTH - 2, STEPS_HEIGHT - 2);
        ctx.restore();
      }
      ctx.strokeStyle = active ? this.theme.active : this.theme.grid;
      ctx.lineWidth = active ? 1.5 : 1;
      ctx.strokeRect(x0 + 1, 1, STEPS_CELL_WIDTH - 2, STEPS_HEIGHT - 2);

      const tx: number = x0 + (STEPS_CELL_WIDTH - inner) / 2;
      const ty: number = (STEPS_HEIGHT + inner) / 2;
      ctx.save();
      ctx.setTransform(scale, 0, 0, -scale, tx, ty);
      StrokeRenderer.fillStrokes(ctx, data, data.commands.length, this.theme.outline);
      StrokeRenderer.fillStrokes(ctx, data, i + 1, this.theme.ink);
      ctx.restore();

      if (this.showNumbers) {
        ctx.fillStyle = active ? this.theme.active : this.theme.numberText;
        const fontPx: number = this.getUIContext().vp2px(STEPS_NUMBER_FONT_SIZE);
        ctx.font = `${fontPx}px sans-serif`;
        ctx.textAlign = 'left';
        ctx.textBaseline = 'top';
        ctx.fillText(`${i + 1}`, x0 + 4, 3);
      }
    }
  }

  build() {
    Canvas(this.ctx)
      .width(this.canvasWidth())
      .height(STEPS_HEIGHT)
      .onReady(() => {
        this.ready = true;
        this.draw();
      })
      .onTouch((event: TouchEvent) => {
        if (event.type !== TouchType.Up) {
          return;
        }
        const cell: number = Math.floor(event.touches[0].x / STEPS_CELL_WIDTH);
        if (cell >= 0 && cell < this.count()) {
          this.onSelect(cell);
        }
      })
  }
}
