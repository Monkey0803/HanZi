/*
 * RouteParams.ets — 强类型路由参数。
 *
 * 通过 pushPathByName(name, param) 传递；页面入口只在边界处取参，
 * 后续业务方法一律用这里的类，不再扩散 as 断言。
 */

/** 进入某册。 */
export class BookRouteParam {
  bookId: string = '';

  constructor(bookId: string = '') {
    this.bookId = bookId;
  }
}

/** 进入某课。 */
export class LessonRouteParam {
  lessonId: string = '';
  /** 从哪一页进入，用于返回栈语义（'book' | 'search' | 'review'）。 */
  from: string = 'book';

  constructor(lessonId: string = '', from: string = 'book') {
    this.lessonId = lessonId;
    this.from = from;
  }
}

/** 进入某字详情。 */
export class CharRouteParam {
  char: string = '';
  lessonId: string = '';
  /** 打开后是否直接开始描红。 */
  startQuiz: boolean = false;

  constructor(char: string = '', lessonId: string = '', startQuiz: boolean = false) {
    this.char = char;
    this.lessonId = lessonId;
    this.startQuiz = startQuiz;
  }
}

/** 进入全屏练字。 */
export class PracticeRouteParam {
  char: string = '';
  lessonId: string = '';

  constructor(char: string = '', lessonId: string = '') {
    this.char = char;
    this.lessonId = lessonId;
  }
}

/** 进入字表 / 查字。 */
export class CatalogRouteParam {
  query: string = '';

  constructor(query: string = '') {
    this.query = query;
  }
}

/** 复习模式。 */
export enum ReviewMode {
  ALL = 'all',
  UNIT = 'unit',
  MISTAKE = 'mistake'
}

/** 进入复习会话。 */
export class ReviewRouteParam {
  mode: string = ReviewMode.ALL;
  bookId: string = '';
  unit: number = 0;
  limit: number = 20;

  constructor(mode: string = ReviewMode.ALL, bookId: string = '', unit: number = 0, limit: number = 20) {
    this.mode = mode;
    this.bookId = bookId;
    this.unit = unit;
    this.limit = limit;
  }
}
