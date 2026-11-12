/*
 * ProgressRepository.ets — 学习进度 / 练习日志 / 统计的 SQL 访问。
 *
 * 只做数据读写，不持有可观察状态；状态由 ProgressStore 维护。
 */

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CharProgress, PracticeLogEntry, PracticeStats } from '../model/ProgressModels';
import { ReviewScheduler } from './ReviewScheduler';
import { appDatabase } from './AppDatabase';

export class ProgressRepository {
  async open(context: common.Context): Promise<void> {
    await appDatabase.open(context);
  }

  async loadAll(): Promise<CharProgress[]> {
    const result: CharProgress[] = [];
    const resultSet: relationalStore.ResultSet = await appDatabase.rdb().querySql(
      'SELECT character, lesson_id, learned, attempts, passes, mistakes, last_practiced, next_review ' +
      'FROM char_progress');
    try {
      while (resultSet.goToNextRow()) {
        const item: CharProgress = new CharProgress();
        item.character = resultSet.getString(0);
        item.lessonId = resultSet.getString(1);
        item.learned = resultSet.getLong(2) === 1;
        item.attempts = resultSet.getLong(3);
        item.passes = resultSet.getLong(4);
        item.mistakes = resultSet.getLong(5);
        item.lastPracticed = resultSet.getLong(6);
        item.nextReview = resultSet.getLong(7);
        if (item.character.length > 0) {
          result.push(item);
        }
      }
    } finally {
      resultSet.close();
    }
    return result;
  }

  async save(progress: CharProgress): Promise<void> {
    const args: Array<relationalStore.ValueType> = [
      progress.character,
      progress.lessonId,
      progress.learned ? 1 : 0,
      progress.attempts,
      progress.passes,
      progress.mistakes,
      progress.lastPracticed,
      progress.nextReview
    ];
    appDatabase.rdb().executeSql(
      'INSERT OR REPLACE INTO char_progress ' +
      '(character, lesson_id, learned, attempts, passes, mistakes, last_practiced, next_review) ' +
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)', args);
  }

  async log(entry: PracticeLogEntry): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'character': entry.character,
      'lesson_id': entry.lessonId,
      'ts': entry.timestamp,
      'mistakes': entry.mistakes,
      'duration_ms': entry.durationMs,
      'rating': entry.rating
    };
    await appDatabase.rdb().insert('practice_log', values);
  }

  async stats(now: number, todayStart: number): Promise<PracticeStats> {
    const stats: PracticeStats = new PracticeStats();
    const store: relationalStore.RdbStore = appDatabase.rdb();

    const learnedSet: relationalStore.ResultSet = await store.querySql(
      'SELECT COUNT(*) FROM char_progress WHERE learned = 1');
    try {
      if (learnedSet.goToFirstRow()) {
        stats.learnedCount = learnedSet.getLong(0);
      }
    } finally {
      learnedSet.close();
    }

    const dueArgs: Array<relationalStore.ValueType> = [now];
    const dueSet: relationalStore.ResultSet = await store.querySql(
      'SELECT COUNT(*) FROM char_progress WHERE learned = 1 AND next_review <= ?', dueArgs);
    try {
      if (dueSet.goToFirstRow()) {
        stats.dueCount = dueSet.getLong(0);
      }
    } finally {
      dueSet.close();
    }

    const mistakeSet: relationalStore.ResultSet = await store.querySql(
      'SELECT COUNT(*) FROM char_progress WHERE mistakes > 0');
    try {
      if (mistakeSet.goToFirstRow()) {
        stats.mistakeCount = mistakeSet.getLong(0);
      }
    } finally {
      mistakeSet.close();
    }

    const todayArgs: Array<relationalStore.ValueType> = [todayStart];
    const todaySet: relationalStore.ResultSet = await store.querySql(
      'SELECT COUNT(*) FROM practice_log WHERE ts >= ?', todayArgs);
    try {
      if (todaySet.goToFirstRow()) {
        stats.todayCount = todaySet.getLong(0);
      }
    } finally {
      todaySet.close();
    }

    const sumSet: relationalStore.ResultSet = await store.querySql(
      'SELECT COALESCE(SUM(attempts), 0), COALESCE(SUM(passes), 0) FROM char_progress');
    let attempts: number = 0;
    let passes: number = 0;
    try {
      if (sumSet.goToFirstRow()) {
        attempts = sumSet.getLong(0);
        passes = sumSet.getLong(1);
      }
    } finally {
      sumSet.close();
    }
    stats.attemptCount = attempts;
    stats.accuracy = attempts > 0 ? Math.round((passes / attempts) * 100) : 0;

    const dateSet: relationalStore.ResultSet = await store.querySql(
      'SELECT DISTINCT date(ts / 1000, \'unixepoch\', \'localtime\') AS d FROM practice_log ' +
      'ORDER BY d DESC LIMIT 400');
    const dates: string[] = [];
    try {
      while (dateSet.goToNextRow()) {
        const text: string = dateSet.getString(0);
        if (text.length > 0) {
          dates.push(text);
        }
      }
    } finally {
      dateSet.close();
    }
    stats.streakDays = ReviewScheduler.streak(dates, now);
    return stats;
  }

  async dueChars(now: number, limit: number): Promise<string[]> {
    const args: Array<relationalStore.ValueType> = [now, limit];
    const resultSet: relationalStore.ResultSet = await appDatabase.rdb().querySql(
      'SELECT character FROM char_progress WHERE learned = 1 AND next_review <= ? ' +
      'ORDER BY next_review ASC, last_practiced DESC LIMIT ?', args);
    return this.readChars(resultSet);
  }

  async learnedChars(limit: number): Promise<string[]> {
    const args: Array<relationalStore.ValueType> = [limit];
    const resultSet: relationalStore.ResultSet = await appDatabase.rdb().querySql(
      'SELECT character FROM char_progress WHERE learned = 1 ' +
      'ORDER BY last_practiced DESC LIMIT ?', args);
    return this.readChars(resultSet);
  }

  async mistakeChars(limit: number): Promise<string[]> {
    const args: Array<relationalStore.ValueType> = [limit];
    const resultSet: relationalStore.ResultSet = await appDatabase.rdb().querySql(
      'SELECT character FROM char_progress WHERE mistakes > 0 ' +
      'ORDER BY last_practiced DESC LIMIT ?', args);
    return this.readChars(resultSet);
  }

  private readChars(resultSet: relationalStore.ResultSet): string[] {
    const chars: string[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const value: string = resultSet.getString(0);
        if (value.length > 0) {
          chars.push(value);
        }
      }
    } finally {
      resultSet.close();
    }
    return chars;
  }
}

export const progressRepository: ProgressRepository = new ProgressRepository();
