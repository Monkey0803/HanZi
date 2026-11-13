/*
 * ReviewViewModel.ets — 复习会话状态：队列、翻卡、自评与重排。
 *
 * 只依赖 ProgressStore（已加载的进度）与 CurriculumRepository（拼音/例词）；
 * 不直接访问数据库，也不做 UI 布局。
 */

import { ReviewCard, ReviewRating } from '../model/ProgressModels';
import { ReviewMode } from '../model/RouteParams';
import { ReviewCardMode, ReviewConstants } from '../common/constants/ReviewConstants';
import { CharacterEntry, Lesson, LessonChar, WordEntry } from '../model/CurriculumModels';
import { curriculumRepository } from '../service/CurriculumRepository';
import { progressStore } from '../service/ProgressStore';

@ObservedV2
export class ReviewViewModel {
  @Trace cards: ReviewCard[] = [];
  @Trace index: number = 0;
  @Trace flipped: boolean = false;
  @Trace finished: boolean = false;
  @Trace empty: boolean = false;
  @Trace unavailable: boolean = false;
  @Trace againCount: number = 0;
  @Trace reviewedCount: number = 0;
  /** 卡片正面内容，会话内不切换。 */
  cardMode: string = ReviewCardMode.CHAR;

  /** 开始一轮会话。 */
  start(mode: string, bookId: string, unit: number, limit: number, cardMode: string): void {
    this.reset();
    this.cardMode = cardMode;
    if (!progressStore.ready) {
      this.unavailable = true;
      this.finished = true;
      return;
    }
    const safeLimit: number = Math.max(1, Math.min(limit, ReviewConstants.MAX_LIMIT));
    let candidates: string[] = [];
    if (mode === ReviewMode.MISTAKE) {
      candidates = progressStore.mistakeChars.slice();
    } else if (mode === ReviewMode.UNIT) {
      candidates = this.unitCandidates(bookId, unit);
    } else {
      candidates = this.allCandidates();
    }
    const cards: ReviewCard[] = [];
    for (let i = 0; i < candidates.length && cards.length < safeLimit; i += 1) {
      cards.push(this.buildCard(candidates[i]));
    }
    this.cards = cards;
    this.empty = cards.length === 0;
    this.finished = this.empty;
  }

  current(): ReviewCard | undefined {
    if (this.index < 0 || this.index >= this.cards.length) {
      return undefined;
    }
    return this.cards[this.index];
  }

  flip(): void {
    this.flipped = !this.flipped;
  }

  /** 自评并推进；「再来」的卡只在未重排过时插回 3 张后。 */
  async rate(rating: ReviewRating): Promise<void> {
    const card: ReviewCard | undefined = this.current();
    if (card === undefined) {
      return;
    }
    await progressStore.rateReview(card.char, card.lessonId, rating);
    this.reviewedCount += 1;
    if (rating === ReviewRating.AGAIN) {
      this.againCount += 1;
      if (!card.requeued && this.index + 1 < this.cards.length) {
        const next: ReviewCard[] = this.cards.slice();
        const insertAt: number = Math.min(this.index + ReviewConstants.REQUEUE_SPAN, next.length);
        next.splice(insertAt, 0, new ReviewCard(card.char, card.pinyin, card.word, card.lessonId, true));
        this.cards = next;
      }
    }
    this.index += 1;
    this.flipped = false;
    if (this.index >= this.cards.length) {
      this.finished = true;
    }
  }

  progressText(): string {
    const current: number = Math.min(this.index + 1, this.cards.length);
    return `${current} / ${this.cards.length}`;
  }

  private reset(): void {
    this.cards = [];
    this.index = 0;
    this.flipped = false;
    this.finished = false;
    this.empty = false;
    this.unavailable = false;
    this.againCount = 0;
    this.reviewedCount = 0;
  }

  private allCandidates(): string[] {
    const result: string[] = [];
    const seen: Set<string> = new Set();
    const due: string[] = progressStore.dueChars;
    for (let i = 0; i < due.length; i += 1) {
      if (!seen.has(due[i])) {
        seen.add(due[i]);
        result.push(due[i]);
      }
    }
    const learned: string[] = progressStore.learnedChars;
    for (let i = 0; i < learned.length; i += 1) {
      if (!seen.has(learned[i])) {
        seen.add(learned[i]);
        result.push(learned[i]);
      }
    }
    return result;
  }

  private unitCandidates(bookId: string, unit: number): string[] {
    const learned: string[] = [];
    const unlearned: string[] = [];
    const seen: Set<string> = new Set();
    if (bookId.length === 0) {
      return learned;
    }
    const lessons: Lesson[] = curriculumRepository.lessonsOfBook(bookId);
    for (let i = 0; i < lessons.length; i += 1) {
      if (lessons[i].unit !== unit) {
        continue;
      }
      const chars: LessonChar[] = curriculumRepository.charsOfLesson(lessons[i].id);
      for (let j = 0; j < chars.length; j += 1) {
        const char: string = chars[j].char;
        if (seen.has(char)) {
          continue;
        }
        seen.add(char);
        if (progressStore.isLearned(char)) {
          learned.push(char);
        } else {
          unlearned.push(char);
        }
      }
    }
    return learned.concat(unlearned);
  }

  private buildCard(char: string): ReviewCard {
    const entry: CharacterEntry | undefined = curriculumRepository.character(char);
    let pinyin: string = '';
    if (entry !== undefined && entry.pinyins.length > 0) {
      pinyin = entry.pinyins[0];
    }
    const words: WordEntry[] = curriculumRepository.wordsFor(char);
    const word: string = words.length > 0 ? words[0].word : '';
    return new ReviewCard(char, pinyin, word, progressStore.lessonOf(char));
  }
}

export const reviewViewModel: ReviewViewModel = new ReviewViewModel();
