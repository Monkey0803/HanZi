# Data license and data policy

## What ships in this repository

Only `entry/src/main/resources/rawfile/data/seed/` is committed. It is a
minimal demonstration dataset (a handful of characters) used for building,
CI, and UI development.

`entry/src/main/resources/rawfile/data/full/` is intentionally ignored by git.
It is generated locally from third-party sources and must not be redistributed.

## Third-party data

### Make Me a Hanzi graphics

- Source: skishore/makemeahanzi `graphics.txt`
- License: Arphic Public License
- License text: `data/licenses/ARPHICPL.txt`
- You may redistribute and/or modify this data under the terms of the Arphic
  Public License. Keep the notice and license text with any redistribution.

### Make Me a Hanzi dictionary

- Source: skishore/makemeahanzi `dictionary.txt`
- Upstream sources: Unihan and CJKlib
- License texts: `data/licenses/COPYING.txt`, `data/licenses/LGPL.txt`
- Keep the notices and license texts with any redistribution.

### Hanzi Writer

- Source: chanind/hanzi-writer
- License: MIT
- License text: `data/licenses/LICENSE-hanzi-writer.txt`
- This project does not bundle Hanzi Writer's JavaScript. It implements a
  compatible native Canvas renderer and quiz matcher.

### Common character catalog (GB2312 level-1)

- The optional `full` dataset also indexes the 3755 level-1 Hanzi of the
  GB2312 character set, so the catalog can browse characters outside the
  textbook list.
- The character list is generated from the GB2312 code ranges (facts of the
  standard, no third-party text or image file is copied).
- Stroke outlines and medians for these characters still come from
  makemeahanzi / Arphic; the Arphic notice above applies unchanged.
- Use `npm run data:strokes -- --no-common` to build a curriculum-only dataset.

## Character catalog browsing

- The app may show textbook characters and common characters side by side.
- Catalog membership (`curriculum` / `common`) is derived at build time in
  `tools/build-hanzi-data.mjs`; the app only reads the generated TSV.

## Curriculum data

The curriculum data is derived from the public dataset
[athenayan123-web/dictation-robot](https://github.com/athenayan123-web/dictation-robot)
(`server/data/chinese_textbook.json`), which organizes 人教版 / 部编版 primary
school Chinese word lists by book, unit and lesson.

- License: MIT (see `data/licenses/CHINESE_TEXTBOOK_MIT.txt`).
- The public repository ships only the minimal `data/seed/` dataset.
- `tools/fetch-textbook.mjs` downloads the source dataset; `tools/build-curriculum.mjs`
  and `tools/build-hanzi-data.mjs` generate the `full` dataset locally.
- If you redistribute generated `full` data, keep the MIT attribution above.
- Pinyin, radicals and decomposition are derived from makemeahanzi, which has
  its own Arphic / LGPL terms (see below).

## Application code

The application code is licensed under MIT; see `LICENSE`.
