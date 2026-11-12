/*
 * StrokeCanvas.ets — 双层 Canvas 笔顺播放 / 描红练习。
 *
 * base：田字格 + 全部轮廓 + 已完成笔画（仅在状态变化时重绘）。
 * overlay：动画中的当前笔画、用户轨迹、错误闪烁（每帧只清 overlay）。
 * 父组件通过 playTrigger / quizTrigger / resetTrigger 递增触发，不直接持有 canvas 上下文。
 */

import { StrokeData, StrokeMatcherOptions, StrokeMatchResult, StrokeTheme, Point } from '../../model/StrokeModels';
import { StrokeRenderer } from '../../service/StrokeRenderer';
import { StrokeGeometry } from '../../service/StrokeGeometry';
import { StrokeMatcher } from '../../service/StrokeMatcher';

const MASK_HALF_WIDTH: number = 140;
const STROKE_PAUSE_MS: number = 180;
const FRAME_MS: number = 16;
const QUIZ_TRAIL_WIDTH: number = 12;

@ComponentV2
export struct StrokeCanvas {
  @Param data: StrokeData | undefined = undefined;
  @Param theme: StrokeTheme = new StrokeTheme();
  @Param canvasSize: number = 300;
  @Param canvasPadding: number = 24;
  @Param showOutline: boolean = true;
  @Param strokeDuration: number = 400;
  @Param playTrigger: number = 0;
  @Param quizTrigger: number = 0;
  @Param resetTrigger: number = 0;
  @Event onStrokeIndexChange: (index: number) => void = () => {};
  @Event onQuizComplete: (mistakes: number) => void = () => {};

  private baseSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private baseCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.baseSettings);
  private overlaySettings: RenderingContextSettings = new RenderingContextSettings(true);
  private overlayCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.overlaySettings);
  private baseReady: boolean = false;
  private overlayReady: boolean = false;
  private revealed: number = 0;
  private current: number = 0;
  private mistakes: number = 0;
  private playing: boolean = false;
  private quizMode: boolean = false;
  private playIndex: number = 0;
  private strokeStartMs: number = 0;
  private progress: number = 0;
  private userPoints: Point[] = [];
  private timerId: number = -1;
  private pauseTimerId: number = -1;
  private flashTimerId: number = -1;
  private matcherOptions: StrokeMatcherOptions = new StrokeMatcherOptions();

  aboutToDisappear(): void {
    this.stop();
  }

  @Monitor('playTrigger')
  onPlayTriggerChanged(): void {
    this.startPlayback();
  }

  @Monitor('quizTrigger')
  onQuizTriggerChanged(): void {
    this.startQuiz();
  }

  @Monitor('resetTrigger')
  onResetTriggerChanged(): void {
    this.stop();
    this.resetState();
    this.drawBase();
    this.clearOverlay();
  }

  @Monitor('data')
  onDataChanged(): void {
    this.stop();
    this.resetState();
    this.drawBase();
    this.clearOverlay();
  }

  /** 播放完整笔顺动画。 */
  startPlayback(): void {
    const data: StrokeData | undefined = this.data;
    if (data === undefined || data.strokeCount === 0) {
      return;
    }
    this.stop();
    this.resetState();
    this.quizMode = false;
    this.playing = true;
    this.drawBase();
    this.clearOverlay();
    this.beginStrokeAnimation();
  }

  /** 进入描红模式（等待用户逐笔书写）。 */
  startQuiz(): void {
    const data: StrokeData | undefined = this.data;
    if (data === undefined || data.strokeCount === 0) {
      return;
    }
    this.stop();
    this.resetState();
    this.quizMode = true;
    this.drawBase();
    this.clearOverlay();
  }

  /** 停止动画与所有定时器。 */
  stop(): void {
    this.playing = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    if (this.pauseTimerId >= 0) {
      clearTimeout(this.pauseTimerId);
      this.pauseTimerId = -1;
    }
    if (this.flashTimerId >= 0) {
      clearTimeout(this.flashTimerId);
      this.flashTimerId = -1;
    }
  }

  private resetState(): void {
    this.revealed = 0;
    this.current = 0;
    this.mistakes = 0;
    this.playIndex = 0;
    this.progress = 0;
    this.userPoints = [];
  }

  private beginStrokeAnimation(): void {
    this.progress = 0;
    this.strokeStartMs = Date.now();
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
    this.timerId = setInterval(() => {
      const elapsed: number = Date.now() - this.strokeStartMs;
      const value: number = this.strokeDuration <= 0 ? 1 : Math.min(1, elapsed / this.strokeDuration);
      this.progress = value;
      this.drawPlayback(this.playIndex, value);
      if (value >= 1) {
        this.finishCurrentStroke();
      }
    }, FRAME_MS);
  }

  private finishCurrentStroke(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.revealed = this.playIndex + 1;
    this.current = this.revealed;
    this.onStrokeIndexChange(this.revealed);
    this.drawBase();
    this.clearOverlay();
    this.playIndex += 1;
    const data: StrokeData | undefined = this.data;
    if (data !== undefined && this.playIndex < data.strokeCount && this.playing) {
      this.pauseTimerId = setTimeout(() => {
        this.pauseTimerId = -1;
        this.beginStrokeAnimation();
      }, STROKE_PAUSE_MS);
    } else {
      this.playing = false;
    }
  }

  private drawBase(): void {
    if (!this.baseReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.baseCtx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasSize, this.canvasSize);
    StrokeRenderer.drawGrid(ctx, this.canvasSize, this.canvasPadding, this.theme);
    const data: StrokeData | undefined = this.data;
    if (data === undefined) {
      return;
    }
    ctx.save();
    StrokeRenderer.applyTransform(ctx, this.canvasSize, this.canvasPadding);
    if (this.showOutline) {
      StrokeRenderer.fillStrokes(ctx, data, data.commands.length, this.theme.outline);
    }
    StrokeRenderer.fillStrokes(ctx, data, this.revealed, this.theme.ink);
    ctx.restore();
  }

  private clearOverlay(): void {
    if (!this.overlayReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.overlayCtx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasSize, this.canvasSize);
  }

  private drawPlayback(index: number, progress: number): void {
    if (!this.overlayReady) {
      return;
    }
    const data: StrokeData | undefined = this.data;
    if (data === undefined) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.overlayCtx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasSize, this.canvasSize);
    ctx.save();
    StrokeRenderer.applyTransform(ctx, this.canvasSize, this.canvasPadding);
    StrokeRenderer.fillStrokeProgress(ctx, data, index, progress, this.theme.ink, MASK_HALF_WIDTH);
    ctx.restore();
  }

  private drawQuiz(): void {
    if (!this.overlayReady) {
      return;
    }
    const data: StrokeData | undefined = this.data;
    const ctx: CanvasRenderingContext2D = this.overlayCtx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasSize, this.canvasSize);
    if (data === undefined) {
      return;
    }
    if (this.mistakes >= 2 && this.current < data.strokeCount) {
      ctx.save();
      StrokeRenderer.applyTransform(ctx, this.canvasSize, this.canvasPadding);
      StrokeRenderer.fillStroke(ctx, data, this.current, this.theme.outline);
      ctx.restore();
    }
    const screenPoints: Point[] = this.toScreenPoints(this.userPoints);
    StrokeRenderer.drawUserTrail(ctx, screenPoints, this.theme.active, QUIZ_TRAIL_WIDTH);
  }

  private handleTouch(event: TouchEvent): void {
    if (!this.quizMode || this.data === undefined || event.touches.length === 0) {
      return;
    }
    const touch: TouchObject = event.touches[0];
    const scale: number = StrokeRenderer.scaleFor(this.canvasSize, this.canvasPadding);
    const dataPoint: Point = StrokeGeometry.toData(new Point(touch.x, touch.y), scale, this.canvasPadding);
    if (event.type === TouchType.Down) {
      this.userPoints = [dataPoint];
      this.drawQuiz();
    } else if (event.type === TouchType.Move) {
      this.userPoints.push(dataPoint);
      this.drawQuiz();
    } else if (event.type === TouchType.Up) {
      this.userPoints.push(dataPoint);
      this.evaluateStroke();
    }
  }

  private evaluateStroke(): void {
    const data: StrokeData | undefined = this.data;
    if (data === undefined || this.current >= data.strokeCount) {
      return;
    }
    const median: Point[] = this.current < data.medians.length ? data.medians[this.current] : [];
    const result: StrokeMatchResult = StrokeMatcher.match(this.userPoints, median, this.matcherOptions);
    if (result.passed) {
      this.revealed = this.current + 1;
      this.current = this.revealed;
      this.userPoints = [];
      this.onStrokeIndexChange(this.revealed);
      this.drawBase();
      this.clearOverlay();
      if (this.current >= data.strokeCount) {
        this.quizMode = false;
        this.onQuizComplete(this.mistakes);
      }
    } else {
      this.mistakes += 1;
      this.flashError();
    }
  }

  private flashError(): void {
    if (!this.overlayReady) {
      return;
    }
    const ctx: CanvasRenderingContext2D = this.overlayCtx;
    StrokeRenderer.resetTransform(ctx);
    ctx.clearRect(0, 0, this.canvasSize, this.canvasSize);
    const screenPoints: Point[] = this.toScreenPoints(this.userPoints);
    StrokeRenderer.drawUserTrail(ctx, screenPoints, this.theme.error, QUIZ_TRAIL_WIDTH);
    if (this.flashTimerId >= 0) {
      clearTimeout(this.flashTimerId);
    }
    this.flashTimerId = setTimeout(() => {
      this.flashTimerId = -1;
      this.userPoints = [];
      this.clearOverlay();
    }, 300);
  }

  private toScreenPoints(points: Point[]): Point[] {
    const scale: number = StrokeRenderer.scaleFor(this.canvasSize, this.canvasPadding);
    const result: Point[] = [];
    for (let i = 0; i < points.length; i += 1) {
      result.push(new Point(
        this.canvasPadding + points[i].x * scale,
        this.canvasPadding + (900 - points[i].y) * scale
      ));
    }
    return result;
  }

  build() {
    Stack() {
      Canvas(this.baseCtx)
        .width(this.canvasSize)
        .height(this.canvasSize)
        .onReady(() => {
          this.baseReady = true;
          this.drawBase();
        })
      Canvas(this.overlayCtx)
        .width(this.canvasSize)
        .height(this.canvasSize)
        .onReady(() => {
          this.overlayReady = true;
          this.clearOverlay();
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })
    }
    .width(this.canvasSize)
    .height(this.canvasSize)
  }
}
