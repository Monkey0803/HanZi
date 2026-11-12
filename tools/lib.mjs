import { createReadStream } from 'node:fs';
import { mkdir, writeFile, readFile, access } from 'node:fs/promises';
import { createInterface } from 'node:readline';
import path from 'node:path';

export const SHARD_COUNT = 32;

export function escapeTsv(value) {
  return String(value ?? '').replace(/[\t\r\n]+/g, ' ').trim();
}

export function tsvRow(values) {
  return values.map(escapeTsv).join('\t');
}

export async function ensureDir(dir) {
  await mkdir(dir, { recursive: true });
}

export async function exists(file) {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

export async function readText(file) {
  return readFile(file, 'utf8');
}

export async function writeText(file, text) {
  await ensureDir(path.dirname(file));
  await writeFile(file, text, 'utf8');
}

export function shardOf(character) {
  const code = character.codePointAt(0) ?? 0;
  return code % SHARD_COUNT;
}

export function shardName(index) {
  return `shard-${String(index).padStart(2, '0')}.tsv`;
}

export function encodeMedians(medians) {
  return medians
    .map((points) => points.map(([x, y]) => `${x},${y}`).join(';'))
    .join('|');
}

export async function readJsonLines(file, onLine) {
  const stream = createReadStream(file, { encoding: 'utf8' });
  const reader = createInterface({ input: stream, crlfDelay: Infinity });
  for await (const line of reader) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    let parsed;
    try {
      parsed = JSON.parse(trimmed);
    } catch {
      continue;
    }
    await onLine(parsed);
  }
}

export async function loadGraphics(file, keep) {
  const map = new Map();
  await readJsonLines(file, (item) => {
    if (!item || typeof item.character !== 'string') return;
    if (keep && !keep.has(item.character)) return;
    if (!Array.isArray(item.strokes) || !Array.isArray(item.medians)) return;
    if (item.strokes.length === 0 || item.strokes.length !== item.medians.length) return;
    map.set(item.character, {
      character: item.character,
      strokes: item.strokes,
      medians: item.medians
    });
  });
  return map;
}

export async function loadDictionary(file, keep) {
  const map = new Map();
  await readJsonLines(file, (item) => {
    if (!item || typeof item.character !== 'string') return;
    if (keep && !keep.has(item.character)) return;
    map.set(item.character, {
      character: item.character,
      pinyin: Array.isArray(item.pinyin)
        ? item.pinyin.filter((value) => typeof value === 'string' && value.length > 0)
        : [],
      radical: typeof item.radical === 'string' ? item.radical : '',
      decomposition: typeof item.decomposition === 'string' ? item.decomposition : ''
    });
  });
  return map;
}

export async function writeStrokeShards(outDir, graphicsMap) {
  const shards = new Map();
  for (let i = 0; i < SHARD_COUNT; i += 1) shards.set(i, []);
  for (const data of graphicsMap.values()) {
    shards.get(shardOf(data.character)).push(data);
  }
  await ensureDir(outDir);
  for (const [index, rows] of shards) {
    rows.sort((a, b) => a.character.localeCompare(b.character, 'zh-Hans-CN'));
    const lines = rows.map((item) => {
      const paths = item.strokes.map(escapeTsv).join('\t');
      return `${escapeTsv(item.character)}\t${item.strokes.length}\t${paths}\t${encodeMedians(item.medians)}`;
    });
    await writeText(path.join(outDir, shardName(index)), lines.join('\n') + (lines.length ? '\n' : ''));
  }
}

export function parseTsvLines(text) {
  return text
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0 && !line.startsWith('#'))
    .map((line) => line.split('\t').map((field) => field.trim()))
    .filter((fields) => {
      const first = fields[0];
      return (
        first.length > 0 &&
        first !== 'id' &&
        first !== 'lessonId' &&
        first !== 'char'
      );
    });
}

export async function readTsv(file) {
  return parseTsvLines(await readText(file));
}

export function nowIso() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * GB2312 一级汉字（3755 字）：区位 0xB0–0xD7 / 0xA1–0xFE。
 *
 * 只是字符集标准里的事实性字表，不含任何项目的文本或图片数据；
 * Node 需要带 full-icu 才能解码 gbk，失败时返回空数组由调用方降级。
 */
export function gb2312Level1() {
  let decoder;
  try {
    decoder = new TextDecoder('gbk');
  } catch {
    return [];
  }
  const chars = [];
  for (let lead = 0xb0; lead <= 0xd7; lead += 1) {
    for (let trail = 0xa1; trail <= 0xfe; trail += 1) {
      let text;
      try {
        text = decoder.decode(new Uint8Array([lead, trail]));
      } catch {
        continue;
      }
      if (!text || text.length !== 1) continue;
      const code = text.codePointAt(0);
      if (code >= 0x3400 && code <= 0x9fff) chars.push(text);
    }
  }
  return chars;
}

/** 读取手工提供的常用字表（任意空白分隔），返回去重后的汉字数组。 */
export async function readCharsetFile(file) {
  const text = await readText(file);
  const unique = new Set();
  for (const ch of text.replace(/\s+/g, '')) {
    const code = ch.codePointAt(0) ?? 0;
    if (code >= 0x3400 && code <= 0x9fff) unique.add(ch);
  }
  return [...unique];
}
