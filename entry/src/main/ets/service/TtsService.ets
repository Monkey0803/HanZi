/*
 * TtsService.ets — 识字短文朗读（CoreSpeechKit 离线中文引擎）。
 *
 * 能力是可选增强：引擎创建失败（如模拟器无 SystemCapability.AI.TextToSpeech）时
 * available 置 false，页面据此隐藏朗读入口；所有平台调用都走 try/catch 降级。
 */

import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

class TtsListener implements textToSpeech.SpeakListener {
  private onDone: () => void;
  private onFailed: () => void;

  constructor(onDone: () => void, onFailed: () => void) {
    this.onDone = onDone;
    this.onFailed = onFailed;
  }

  onStart(requestId: string, response: textToSpeech.StartResponse): void {
  }

  onStop(requestId: string, response: textToSpeech.StopResponse): void {
  }

  onComplete(requestId: string, response: textToSpeech.CompleteResponse): void {
    if (response.type === 1) {
      this.onDone();
    }
  }

  onError(requestId: string, errorCode: number, errorMessage: string): void {
    console.warn(`TtsService onError: ${errorCode} ${errorMessage}`);
    this.onFailed();
  }
}

@ObservedV2
export class TtsService {
  /** 引擎可用（设备支持且创建成功）。 */
  @Trace available: boolean = false;
  /** 正在朗读的短文 id；空串表示空闲。 */
  @Trace speakingId: string = '';

  private engine: textToSpeech.TextToSpeechEngine | undefined = undefined;
  private creating: boolean = false;
  private seq: number = 0;

  /** 预创建引擎（由阅读区 aboutToAppear 调用），失败只降级，不抛错。 */
  async init(): Promise<void> {
    await this.ensureEngine();
  }

  /** 点同一个短文 = 停止；点另一个 = 切换朗读。 */
  async speak(passageId: string, text: string): Promise<void> {
    if (this.engine !== undefined && this.speakingId === passageId) {
      this.stop();
      return;
    }
    const ready: boolean = await this.ensureEngine();
    if (!ready || this.engine === undefined) {
      return;
    }
    try {
      if (this.engine.isBusy()) {
        this.engine.stop();
      }
      this.seq += 1;
      const requestId: string = `hz${this.seq}`;
      const params: textToSpeech.SpeakParams = { requestId: requestId };
      this.speakingId = passageId;
      this.engine.speak(text, params);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`TtsService.speak failed: ${error.code} ${error.message}`);
      this.speakingId = '';
      this.available = false;
    }
  }

  stop(): void {
    this.speakingId = '';
    if (this.engine === undefined) {
      return;
    }
    try {
      if (this.engine.isBusy()) {
        this.engine.stop();
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.warn(`TtsService.stop failed: ${error.code} ${error.message}`);
    }
  }

  shutdown(): void {
    this.stop();
    if (this.engine === undefined) {
      return;
    }
    try {
      this.engine.shutdown();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.warn(`TtsService.shutdown failed: ${error.code} ${error.message}`);
    }
    this.engine = undefined;
    this.available = false;
  }

  private async ensureEngine(): Promise<boolean> {
    if (this.engine !== undefined) {
      return true;
    }
    if (this.creating) {
      return false;
    }
    this.creating = true;
    try {
      this.seq += 1;
      const params: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 13,
        online: 1
      };
      const engine: textToSpeech.TextToSpeechEngine = await textToSpeech.createEngine(params);
      engine.setListener(new TtsListener((): void => {
        this.speakingId = '';
      }, (): void => {
        this.speakingId = '';
        this.available = false;
      }));
      this.engine = engine;
      this.available = true;
      return true;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.warn(`TtsService.ensureEngine unavailable: ${error.code} ${error.message}`);
      this.available = false;
      return false;
    } finally {
      this.creating = false;
    }
  }
}

export const ttsService: TtsService = new TtsService();
