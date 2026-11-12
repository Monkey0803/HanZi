/*
 * AppBootstrap.ets — 启动加载编排。
 *
 * 顺序：解析数据根（full → seed）→ 载入课程数据。学习进度（RDB）在进度层接入后
 * 追加到 ready 之前。@ObservedV2 单例，页面直接读 state。
 */

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataRootResolver } from './DataRootResolver';
import { curriculumRepository } from './CurriculumRepository';
import { progressStore } from './ProgressStore';
import { readingRepository } from './ReadingRepository';

/** 启动状态。 */
export enum BootstrapState {
  IDLE = 'idle',
  LOADING = 'loading',
  READY = 'ready',
  ERROR = 'error'
}

@ObservedV2
export class AppBootstrap {
  @Trace state: string = BootstrapState.IDLE;
  @Trace errorMessage: string = '';
  /** 'full' | 'seed'。 */
  @Trace dataMode: string = '';

  /** 启动一次；已就绪或正在加载时直接返回。 */
  async start(context: common.Context): Promise<void> {
    if (this.state === BootstrapState.LOADING || this.state === BootstrapState.READY) {
      return;
    }
    this.state = BootstrapState.LOADING;
    this.errorMessage = '';
    try {
      await dataRootResolver.resolve(context);
      this.dataMode = dataRootResolver.currentMode();
      await curriculumRepository.load(context);
      // 阅读短文是可选增强数据：缺失或解析失败时只隐藏阅读区，不影响课本浏览。
      try {
        await readingRepository.load(context);
      } catch (readingErr) {
        const readingError: BusinessError = readingErr as BusinessError;
        console.error(`AppBootstrap reading load failed: ${readingError.code} ${readingError.message}`);
      }
      // 学习进度是增强能力：数据库打不开时仍允许浏览课本，复习页自行降级。
      try {
        await progressStore.load(context);
      } catch (progressErr) {
        const progressError: BusinessError = progressErr as BusinessError;
        console.error(`AppBootstrap progress load failed: ${progressError.code} ${progressError.message}`);
      }
      this.state = BootstrapState.READY;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      this.errorMessage = error.message.length > 0 ? error.message : '数据加载失败';
      this.state = BootstrapState.ERROR;
      console.error(`AppBootstrap.start failed: ${error.code} ${this.errorMessage}`);
    }
  }

  /** 失败后重试。 */
  async retry(context: common.Context): Promise<void> {
    if (this.state === BootstrapState.LOADING) {
      return;
    }
    this.state = BootstrapState.IDLE;
    await this.start(context);
  }
}

export const appBootstrap: AppBootstrap = new AppBootstrap();
