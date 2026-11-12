/*
 * DataRootResolver.ets — 选择 rawfile 数据根。
 *
 * 优先完整数据（data/full，本地生成、不入库），不存在时回退演示数据（data/seed，随仓库提交）。
 * 解析结果缓存；同时提供按根路径读文本的能力，避免各仓库各自处理 TextDecoder。
 */

import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const FULL_ROOT: string = 'data/full';
const SEED_ROOT: string = 'data/seed';

export class DataRootResolver {
  private root: string = '';
  private mode: string = '';

  /** 解析并缓存数据根；成功返回根路径，失败抛错由 AppBootstrap 兜底。 */
  async resolve(context: common.Context): Promise<string> {
    if (this.root.length > 0) {
      return this.root;
    }
    if (await this.exists(context, `${FULL_ROOT}/curriculum/meta.tsv`)) {
      this.root = FULL_ROOT;
      this.mode = 'full';
      return this.root;
    }
    if (await this.exists(context, `${SEED_ROOT}/curriculum/meta.tsv`)) {
      this.root = SEED_ROOT;
      this.mode = 'seed';
      return this.root;
    }
    throw new Error('未找到课程数据（data/full 与 data/seed 均缺失）');
  }

  /** 当前数据根（未解析时为空串）。 */
  currentRoot(): string {
    return this.root;
  }

  /** 'full' | 'seed'。 */
  currentMode(): string {
    return this.mode;
  }

  /** 读取 rawfile 文本。 */
  async readText(context: common.Context, relativePath: string): Promise<string> {
    const bytes: Uint8Array = await context.resourceManager.getRawFileContent(relativePath);
    const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(bytes);
  }

  /** 读取当前根下的文件。 */
  async readRootText(context: common.Context, relativePath: string): Promise<string> {
    return this.readText(context, `${this.root}/${relativePath}`);
  }

  /** 判断当前根下文件是否存在。 */
  async exists(context: common.Context, relativePath: string): Promise<boolean> {
    try {
      const bytes: Uint8Array = await context.resourceManager.getRawFileContent(relativePath);
      return bytes.length > 0;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      if (error.code !== 9001005) {
        console.warn(`DataRootResolver.exists ${relativePath} failed: ${error.code}`);
      }
      return false;
    }
  }
}

export const dataRootResolver: DataRootResolver = new DataRootResolver();
