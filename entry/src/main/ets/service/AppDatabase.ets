/*
 * AppDatabase.ets — 学习进度 RDB（relationalStore）的打开与建表。
 *
 * 只负责连接与 schema；具体读写放在 ProgressRepository。
 * 打开失败不在这里吞掉，由 ProgressStore / AppBootstrap 决定降级策略。
 */

import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'hanzi_progress.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_CHAR_PROGRESS: string = `
CREATE TABLE IF NOT EXISTS char_progress (
  character TEXT PRIMARY KEY,
  lesson_id TEXT NOT NULL DEFAULT '',
  learned INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  passes INTEGER NOT NULL DEFAULT 0,
  mistakes INTEGER NOT NULL DEFAULT 0,
  last_practiced INTEGER NOT NULL DEFAULT 0,
  next_review INTEGER NOT NULL DEFAULT 0
)`;

const SQL_CREATE_PRACTICE_LOG: string = `
CREATE TABLE IF NOT EXISTS practice_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  character TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  ts INTEGER NOT NULL,
  mistakes INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL,
  rating INTEGER NOT NULL DEFAULT 0
)`;

const SQL_CREATE_DUE_INDEX: string =
  'CREATE INDEX IF NOT EXISTS idx_char_due ON char_progress(next_review)';

const SQL_CREATE_LOG_INDEX: string =
  'CREATE INDEX IF NOT EXISTS idx_practice_ts ON practice_log(ts)';

export class AppDatabase {
  private store: relationalStore.RdbStore | undefined = undefined;

  /** 打开数据库并建表；重复调用直接返回。 */
  async open(context: common.Context): Promise<void> {
    if (this.store !== undefined) {
      return;
    }
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await store.executeSql(SQL_CREATE_CHAR_PROGRESS);
    await store.executeSql(SQL_CREATE_PRACTICE_LOG);
    await store.executeSql(SQL_CREATE_DUE_INDEX);
    await store.executeSql(SQL_CREATE_LOG_INDEX);
    this.store = store;
  }

  /** 已打开的 RdbStore；未打开时抛错，避免静默丢数据。 */
  rdb(): relationalStore.RdbStore {
    const store: relationalStore.RdbStore | undefined = this.store;
    if (store === undefined) {
      throw new Error('进度数据库尚未打开');
    }
    return store;
  }
}

export const appDatabase: AppDatabase = new AppDatabase();
