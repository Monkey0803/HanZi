#!/usr/bin/env node
/*
 * logo.mjs — 生成 HanZi 品牌 logo 资源（纯 Node，无外部依赖）。
 *
 * 视觉：米白纸底 + 墨色「字」 + 右下角朱红「汉」印章。
 * 笔画取自 makemeahanzi（Arphic Public License），与 App 字详情页一致。
 *
 * 输出：
 *   docs/logo.svg
 *   docs/logo-preview.png / docs/logo-preview-dark.png
 *   AppScope/resources/base/media/background.png
 *   AppScope/resources/base/media/foreground.png
 *   entry/src/main/resources/base/media/background.png
 *   entry/src/main/resources/base/media/foreground.png
 *   entry/src/main/resources/base/media/startIcon.png
 *   entry/src/main/resources/dark/media/startIcon.png
 *   entry/src/main/resources/base/media/logo_mark.svg
 *   entry/src/main/resources/dark/media/logo_mark.svg
 *
 * 运行：cd tools && node logo.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const SIZE = 1024;
const SUPERSAMPLE = 4;

const SHARD_DIR = path.join(ROOT, 'entry/src/main/resources/rawfile/data/full/strokes');
const CACHE_FILE = path.join(__dirname, 'cache/graphics.txt');

const ZI = '字';
const HAN = '汉';

const SHARDS = {
  [ZI]: 'shard-23.tsv',
  [HAN]: 'shard-09.tsv'
};

/* ---------- 笔画数据 ---------- */

function readShardStrokes(char, file) {
  const full = path.join(SHARD_DIR, file);
  if (!fs.existsSync(full)) {
    return null;
  }
  const lines = fs.readFileSync(full, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    if (!line.startsWith(char + '\t')) {
      continue;
    }
    const cols = line.split('\t');
    const count = Number(cols[1]);
    const strokes = cols.slice(2, 2 + count);
    if (strokes.length === count && count > 0) {
      return strokes;
    }
  }
  return null;
}

function readCacheMap() {
  if (!fs.existsSync(CACHE_FILE)) {
    return null;
  }
  const map = new Map();
  for (const line of fs.readFileSync(CACHE_FILE, 'utf8').split(/\r?\n/)) {
    if (!line.trim()) {
      continue;
    }
    try {
      const obj = JSON.parse(line);
      if (obj.character && Array.isArray(obj.strokes)) {
        map.set(obj.character, obj.strokes);
      }
    } catch (error) {
      // 跳过损坏行
    }
  }
  return map;
}

function getStrokes(char) {
  const shard = readShardStrokes(char, SHARDS[char]);
  if (shard) {
    return shard;
  }
  const cache = readCacheMap();
  if (cache && cache.has(char)) {
    return cache.get(char);
  }
  throw new Error(`No stroke data for ${char}`);
}

/* ---------- SVG path 解析与展平 ---------- */

function flattenQuad(poly, x0, y0, x1, y1, x2, y2) {
  const len = Math.hypot(x1 - x0, y1 - y0) + Math.hypot(x2 - x1, y2 - y1);
  const steps = Math.max(6, Math.min(64, Math.ceil(len / 6)));
  for (let i = 1; i <= steps; i += 1) {
    const t = i / steps;
    const mt = 1 - t;
    poly.push([
      mt * mt * x0 + 2 * mt * t * x1 + t * t * x2,
      mt * mt * y0 + 2 * mt * t * y1 + t * t * y2
    ]);
  }
}

function flattenCubic(poly, x0, y0, x1, y1, x2, y2, x3, y3) {
  const len = Math.hypot(x1 - x0, y1 - y0) + Math.hypot(x2 - x1, y2 - y1) +
    Math.hypot(x3 - x2, y3 - y2);
  const steps = Math.max(8, Math.min(80, Math.ceil(len / 6)));
  for (let i = 1; i <= steps; i += 1) {
    const t = i / steps;
    const mt = 1 - t;
    const a = mt * mt * mt;
    const b = 3 * mt * mt * t;
    const c = 3 * mt * t * t;
    const d = t * t * t;
    poly.push([
      a * x0 + b * x1 + c * x2 + d * x3,
      a * y0 + b * y1 + c * y2 + d * y3
    ]);
  }
}

const COMMAND_RE = /^[MLQCZmlqcz]$/;

function parsePath(d) {
  const tokens = d.match(/[MLQCZmlqcz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?/g);
  if (!tokens) {
    return [];
  }
  const polygons = [];
  let poly = null;
  let cx = 0;
  let cy = 0;
  let sx = 0;
  let sy = 0;
  let i = 0;
  const num = () => Number(tokens[i++]);

  while (i < tokens.length) {
    const token = tokens[i];
    if (!COMMAND_RE.test(token)) {
      i += 1;
      continue;
    }
    i += 1;
    const upper = token.toUpperCase();
    const relative = token !== upper;

    if (upper === 'M') {
      let x = num();
      let y = num();
      if (relative) {
        x += cx;
        y += cy;
      }
      if (poly) {
        polygons.push(poly);
      }
      poly = [[x, y]];
      cx = x;
      cy = y;
      sx = x;
      sy = y;
      while (i < tokens.length && !COMMAND_RE.test(tokens[i])) {
        let x2 = num();
        let y2 = num();
        if (relative) {
          x2 += cx;
          y2 += cy;
        }
        poly.push([x2, y2]);
        cx = x2;
        cy = y2;
      }
    } else if (upper === 'L') {
      while (i < tokens.length && !COMMAND_RE.test(tokens[i])) {
        let x = num();
        let y = num();
        if (relative) {
          x += cx;
          y += cy;
        }
        poly.push([x, y]);
        cx = x;
        cy = y;
      }
    } else if (upper === 'Q') {
      while (i < tokens.length && !COMMAND_RE.test(tokens[i])) {
        let x1 = num();
        let y1 = num();
        let x = num();
        let y = num();
        if (relative) {
          x1 += cx;
          y1 += cy;
          x += cx;
          y += cy;
        }
        flattenQuad(poly, cx, cy, x1, y1, x, y);
        cx = x;
        cy = y;
      }
    } else if (upper === 'C') {
      while (i < tokens.length && !COMMAND_RE.test(tokens[i])) {
        let x1 = num();
        let y1 = num();
        let x2 = num();
        let y2 = num();
        let x = num();
        let y = num();
        if (relative) {
          x1 += cx;
          y1 += cy;
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        flattenCubic(poly, cx, cy, x1, y1, x2, y2, x, y);
        cx = x;
        cy = y;
      }
    } else if (upper === 'Z') {
      if (poly) {
        poly.push([sx, sy]);
        polygons.push(poly);
        poly = null;
      }
      cx = sx;
      cy = sy;
    }
  }
  if (poly) {
    polygons.push(poly);
  }
  return polygons;
}

/* ---------- 几何变换 ---------- */

const ZI_TRANSFORM = { tx: 94.7, ty: 101.9, scale: 0.801 };
const HAN_TRANSFORM = { tx: 739.8, ty: 740.3, scale: 0.1656 };

function toCanvas(x, y, transform) {
  return [transform.tx + transform.scale * x, transform.ty + transform.scale * (900 - y)];
}

function strokePolygons(strokes, transform) {
  const polygons = [];
  for (const d of strokes) {
    for (const poly of parsePath(d)) {
      polygons.push(poly.map((point) => toCanvas(point[0], point[1], transform)));
    }
  }
  return polygons;
}

/* ---------- 圆角矩形 ---------- */

function roundedRectPolygon(x, y, w, h, r, steps = 20) {
  const points = [];
  const arc = (ccx, ccy, radius, from, to) => {
    for (let i = 0; i <= steps; i += 1) {
      const angle = from + (to - from) * (i / steps);
      points.push([ccx + radius * Math.cos(angle), ccy + radius * Math.sin(angle)]);
    }
  };
  arc(x + r, y + r, r, Math.PI, Math.PI * 1.5);
  arc(x + w - r, y + r, r, Math.PI * 1.5, Math.PI * 2);
  arc(x + w - r, y + h - r, r, 0, Math.PI * 0.5);
  arc(x + r, y + h - r, r, Math.PI * 0.5, Math.PI);
  return points;
}

/* ---------- 扫描线填充 ---------- */

function fillPolygon(polygon, coverage, width, height) {
  const ss = SUPERSAMPLE;
  const bigW = width * ss;
  const bigH = height * ss;
  const edges = [];
  for (let i = 0; i < polygon.length; i += 1) {
    const p0 = polygon[i];
    const p1 = polygon[(i + 1) % polygon.length];
    if (p0[1] === p1[1]) {
      continue;
    }
    edges.push([p0[0], p0[1], p1[0], p1[1]]);
  }
  if (edges.length === 0) {
    return;
  }

  let minY = Infinity;
  let maxY = -Infinity;
  for (const point of polygon) {
    minY = Math.min(minY, point[1]);
    maxY = Math.max(maxY, point[1]);
  }

  const rowStart = Math.max(0, Math.floor(minY * ss));
  const rowEnd = Math.min(bigH - 1, Math.ceil(maxY * ss));
  const crossings = [];

  for (let row = rowStart; row <= rowEnd; row += 1) {
    const sy = (row + 0.5) / ss;
    crossings.length = 0;
    for (const edge of edges) {
      const [x0, y0, x1, y1] = edge;
      if ((y0 <= sy && y1 > sy) || (y1 <= sy && y0 > sy)) {
        crossings.push(x0 + ((sy - y0) * (x1 - x0)) / (y1 - y0));
      }
    }
    if (crossings.length < 2) {
      continue;
    }
    crossings.sort((a, b) => a - b);
    const outRow = Math.floor(row / ss);
    const base = outRow * width;
    for (let k = 0; k + 1 < crossings.length; k += 2) {
      const xa = Math.max(0, Math.ceil(crossings[k] * ss - 0.5));
      const xb = Math.min(bigW - 1, Math.floor(crossings[k + 1] * ss - 0.5));
      for (let x = xa; x <= xb; x += 1) {
        coverage[base + Math.floor(x / ss)] += 1;
      }
    }
  }
}

/* ---------- 合成 ---------- */

function compositeLayer(buffer, coverage, width, height, rgba) {
  const total = width * height;
  const ss2 = SUPERSAMPLE * SUPERSAMPLE;
  const [sr, sg, sb, sa255] = rgba;
  for (let i = 0; i < total; i += 1) {
    const cov = coverage[i];
    if (cov === 0) {
      continue;
    }
    const alpha = Math.min(1, cov / ss2) * (sa255 / 255);
    if (alpha <= 0) {
      continue;
    }
    const idx = i * 4;
    const dstA = buffer[idx + 3] / 255;
    const outA = alpha + dstA * (1 - alpha);
    if (outA <= 0) {
      continue;
    }
    buffer[idx] = Math.round((sr * alpha + buffer[idx] * dstA * (1 - alpha)) / outA);
    buffer[idx + 1] = Math.round((sg * alpha + buffer[idx + 1] * dstA * (1 - alpha)) / outA);
    buffer[idx + 2] = Math.round((sb * alpha + buffer[idx + 2] * dstA * (1 - alpha)) / outA);
    buffer[idx + 3] = Math.round(outA * 255);
  }
}

function compositeOver(dst, src, width, height) {
  const total = width * height;
  for (let i = 0; i < total; i += 1) {
    const idx = i * 4;
    const srcA = src[idx + 3] / 255;
    if (srcA <= 0) {
      continue;
    }
    const dstA = dst[idx + 3] / 255;
    const outA = srcA + dstA * (1 - srcA);
    if (outA <= 0) {
      continue;
    }
    dst[idx] = Math.round((src[idx] * srcA + dst[idx] * dstA * (1 - srcA)) / outA);
    dst[idx + 1] = Math.round((src[idx + 1] * srcA + dst[idx + 1] * dstA * (1 - srcA)) / outA);
    dst[idx + 2] = Math.round((src[idx + 2] * srcA + dst[idx + 2] * dstA * (1 - srcA)) / outA);
    dst[idx + 3] = Math.round(outA * 255);
  }
}

/* ---------- 调色板 ---------- */

const PALETTES = {
  light: {
    ink: '#1F1F1F',
    inkRgba: [31, 31, 31, 255],
    seal: '#B3342A',
    sealRgba: [179, 52, 42, 255],
    white: '#FFFFFF',
    whiteRgba: [255, 255, 255, 255],
    bgTop: '#FBF7EE',
    bgBottom: '#F4EDDF',
    bgTopRgba: [251, 247, 238],
    bgBottomRgba: [244, 237, 223]
  },
  dark: {
    ink: '#F2FFFFFF',
    inkRgba: [255, 255, 255, 242],
    seal: '#E0685A',
    sealRgba: [224, 104, 90, 255],
    white: '#FFFFFF',
    whiteRgba: [255, 255, 255, 255],
    bgTop: '#17181C',
    bgBottom: '#101114',
    bgTopRgba: [23, 24, 28],
    bgBottomRgba: [16, 17, 20]
  }
};

/* ---------- PNG 编码 ---------- */

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n += 1) {
    let c = n;
    for (let k = 0; k < 8; k += 1) {
      c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(buffer) {
  let c = 0xffffffff;
  for (let i = 0; i < buffer.length; i += 1) {
    c = CRC_TABLE[(c ^ buffer[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const typeBuffer = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 0);
  return Buffer.concat([length, typeBuffer, data, crc]);
}

function encodePNG(width, height, rgba) {
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const stride = width * 4 + 1;
  const raw = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y += 1) {
    raw[y * stride] = 0;
    rgba.copy(raw, y * stride + 1, y * width * 4, (y + 1) * width * 4);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([
    signature,
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', idat),
    pngChunk('IEND', Buffer.alloc(0))
  ]);
}

/* ---------- 渲染 ---------- */

const ZI_POLYGONS = strokePolygons(getStrokes(ZI), ZI_TRANSFORM);
const HAN_POLYGONS = strokePolygons(getStrokes(HAN), HAN_TRANSFORM);

function renderMark(palette) {
  const coverageInk = new Uint32Array(SIZE * SIZE);
  const coverageSeal = new Uint32Array(SIZE * SIZE);
  const coverageRing = new Uint32Array(SIZE * SIZE);
  const coverageInner = new Uint32Array(SIZE * SIZE);
  const coverageHan = new Uint32Array(SIZE * SIZE);

  for (const poly of ZI_POLYGONS) {
    fillPolygon(poly, coverageInk, SIZE, SIZE);
  }
  fillPolygon(roundedRectPolygon(740, 740, 180, 180, 20), coverageSeal, SIZE, SIZE);
  fillPolygon(roundedRectPolygon(741.5, 741.5, 177, 177, 18.5), coverageRing, SIZE, SIZE);
  fillPolygon(roundedRectPolygon(744.5, 744.5, 171, 171, 15.5), coverageInner, SIZE, SIZE);
  for (const poly of HAN_POLYGONS) {
    fillPolygon(poly, coverageHan, SIZE, SIZE);
  }

  const buffer = Buffer.alloc(SIZE * SIZE * 4);
  compositeLayer(buffer, coverageInk, SIZE, SIZE, palette.inkRgba);
  compositeLayer(buffer, coverageSeal, SIZE, SIZE, palette.sealRgba);
  compositeLayer(buffer, coverageRing, SIZE, SIZE, palette.whiteRgba);
  compositeLayer(buffer, coverageInner, SIZE, SIZE, palette.sealRgba);
  compositeLayer(buffer, coverageHan, SIZE, SIZE, palette.whiteRgba);
  return buffer;
}

function renderBackground(palette, rounded) {
  const buffer = Buffer.alloc(SIZE * SIZE * 4);
  const coverage = rounded ? new Uint32Array(SIZE * SIZE) : null;
  if (rounded) {
    fillPolygon(roundedRectPolygon(0, 0, SIZE, SIZE, 180), coverage, SIZE, SIZE);
  }

  for (let y = 0; y < SIZE; y += 1) {
    const t = y / (SIZE - 1);
    const r = palette.bgTopRgba[0] + (palette.bgBottomRgba[0] - palette.bgTopRgba[0]) * t;
    const g = palette.bgTopRgba[1] + (palette.bgBottomRgba[1] - palette.bgTopRgba[1]) * t;
    const b = palette.bgTopRgba[2] + (palette.bgBottomRgba[2] - palette.bgTopRgba[2]) * t;
    for (let x = 0; x < SIZE; x += 1) {
      const i = y * SIZE + x;
      const idx = i * 4;
      const alpha = rounded ? Math.min(1, coverage[i] / (SUPERSAMPLE * SUPERSAMPLE)) : 1;
      buffer[idx] = Math.round(r);
      buffer[idx + 1] = Math.round(g);
      buffer[idx + 2] = Math.round(b);
      buffer[idx + 3] = Math.round(alpha * 255);
    }
  }
  return buffer;
}

function renderIcon(palette, roundedBackground) {
  const background = renderBackground(palette, roundedBackground);
  const mark = renderMark(palette);
  compositeOver(background, mark, SIZE, SIZE);
  return background;
}

/* ---------- SVG 输出 ---------- */

function markSvgBody(palette) {
  const zi = ZI_POLYGONS.length > 0 ? getStrokes(ZI).map((d) => `<path d="${d}"/>`).join('') : '';
  const han = getStrokes(HAN).map((d) => `<path d="${d}"/>`).join('');
  return `  <g transform="translate(94.7 101.9) scale(0.801) matrix(1 0 0 -1 0 900)" fill="${palette.ink}" fill-rule="evenodd">${zi}</g>
  <rect x="740" y="740" width="180" height="180" rx="20" fill="${palette.seal}"/>
  <rect x="743" y="743" width="174" height="174" rx="17" fill="none" stroke="${palette.white}" stroke-width="3"/>
  <g transform="translate(739.8 740.3) scale(0.1656) matrix(1 0 0 -1 0 900)" fill="${palette.white}" fill-rule="evenodd">${han}</g>`;
}

function markSvg(palette) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
${markSvgBody(palette)}
</svg>
`;
}

function logoSvg(palette) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${palette.bgTop}"/>
      <stop offset="1" stop-color="${palette.bgBottom}"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="180" fill="url(#paper)"/>
${markSvgBody(palette)}
</svg>
`;
}

/* ---------- 写文件 ---------- */

function ensureDir(file) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
}

function writeFile(file, data) {
  ensureDir(file);
  fs.writeFileSync(file, data);
}

function alphaStats(buffer) {
  let opaque = 0;
  let transparent = 0;
  for (let i = 3; i < buffer.length; i += 4) {
    if (buffer[i] === 255) {
      opaque += 1;
    } else if (buffer[i] === 0) {
      transparent += 1;
    }
  }
  return { opaque, transparent, total: buffer.length / 4 };
}

function main() {
  const light = PALETTES.light;
  const dark = PALETTES.dark;

  const lightBackground = renderBackground(light, false);
  const lightForeground = renderMark(light);
  const darkForeground = renderMark(dark);
  const lightPreview = renderIcon(light, true);
  const darkPreview = renderIcon(dark, true);
  const lightStart = renderMark(light);
  const darkStart = renderMark(dark);

  const outputs = [
    { file: path.join(ROOT, 'docs/logo.svg'), data: logoSvg(light), text: true },
    { file: path.join(ROOT, 'docs/logo-preview.png'), data: encodePNG(SIZE, SIZE, lightPreview) },
    { file: path.join(ROOT, 'docs/logo-preview-dark.png'), data: encodePNG(SIZE, SIZE, darkPreview) },
    { file: path.join(ROOT, 'AppScope/resources/base/media/background.png'), data: encodePNG(SIZE, SIZE, lightBackground) },
    { file: path.join(ROOT, 'AppScope/resources/base/media/foreground.png'), data: encodePNG(SIZE, SIZE, lightForeground) },
    { file: path.join(ROOT, 'entry/src/main/resources/base/media/background.png'), data: encodePNG(SIZE, SIZE, lightBackground) },
    { file: path.join(ROOT, 'entry/src/main/resources/base/media/foreground.png'), data: encodePNG(SIZE, SIZE, lightForeground) },
    { file: path.join(ROOT, 'entry/src/main/resources/base/media/startIcon.png'), data: encodePNG(SIZE, SIZE, lightStart) },
    { file: path.join(ROOT, 'entry/src/main/resources/dark/media/startIcon.png'), data: encodePNG(SIZE, SIZE, darkStart) },
    { file: path.join(ROOT, 'entry/src/main/resources/base/media/logo_mark.svg'), data: markSvg(light), text: true },
    { file: path.join(ROOT, 'entry/src/main/resources/dark/media/logo_mark.svg'), data: markSvg(dark), text: true }
  ];

  for (const item of outputs) {
    writeFile(item.file, item.data);
  }

  const bgStats = alphaStats(lightBackground);
  const fgStats = alphaStats(lightForeground);
  const startStats = alphaStats(lightStart);

  console.log('HanZi logo assets generated:');
  for (const item of outputs) {
    const size = item.text ? `${Buffer.byteLength(item.data)} bytes` : `${SIZE}x${SIZE}`;
    console.log(`  ${path.relative(ROOT, item.file)} (${size})`);
  }
  console.log('');
  console.log(`background.png alpha: opaque=${bgStats.opaque} transparent=${bgStats.transparent} total=${bgStats.total}`);
  console.log(`foreground.png alpha: opaque=${fgStats.opaque} transparent=${fgStats.transparent} total=${fgStats.total}`);
  console.log(`startIcon.png alpha: opaque=${startStats.opaque} transparent=${startStats.transparent} total=${startStats.total}`);
  if (bgStats.transparent !== 0) {
    throw new Error('background.png should be fully opaque');
  }
  if (fgStats.opaque === 0 || fgStats.transparent === 0) {
    throw new Error('foreground.png should contain both opaque and transparent pixels');
  }
}

main();
