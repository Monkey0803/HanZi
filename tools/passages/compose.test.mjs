import assert from 'node:assert/strict';
import test from 'node:test';
import { composeWordPractice, MAX_PRACTICE_WORDS } from './compose.mjs';

test('keeps stable order, removes duplicates, and caps output at six words', () => {
  const text = composeWordPractice(['天地', '人民', '天地', '上下', '中国', '大小', '多少', '后来']);
  assert.equal(MAX_PRACTICE_WORDS, 6);
  assert.equal(text, '天地、人民、上下、中国、大小、多少。');
});

test('returns empty when fewer than two valid words remain', () => {
  assert.equal(composeWordPractice([]), '');
  assert.equal(composeWordPractice(['天地']), '');
  assert.equal(composeWordPractice(['天', '天地天地人', '天地']), '');
});

test('never adds repeated or reversed fallback sentences', () => {
  const text = composeWordPractice(['音乐', '数学']);
  assert.equal(text, '音乐、数学。');
  assert.equal(text.includes('乐音'), false);
  assert.equal(text.indexOf('音乐'), text.lastIndexOf('音乐'));
});
