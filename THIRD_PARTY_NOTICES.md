# Third-party notices

This project uses the following third-party code, data and references.

## Hanzi Writer

- Project: chanind/hanzi-writer
- License: MIT
- Usage: the native ArkTS stroke animation and quiz matching in this project are
  a from-scratch implementation inspired by Hanzi Writer's public behaviour. No
  JavaScript source is bundled at runtime.
- License text: `entry/src/main/resources/rawfile/data/licenses/LICENSE-hanzi-writer.txt`

## Make Me a Hanzi

- Project: skishore/makemeahanzi
- Data used: `graphics.txt` (stroke outlines and medians) and `dictionary.txt`
  (radical and decomposition metadata).
- `graphics.txt` is derived from Arphic fonts and is distributed under the
  Arphic Public License. License text:
  `entry/src/main/resources/rawfile/data/licenses/ARPHICPL.txt`.
- `dictionary.txt` is derived from Unihan and CJKlib; see the repository's
  `COPYING` and `LGPL` files. License text:
  `entry/src/main/resources/rawfile/data/licenses/COPYING.txt` and
  `entry/src/main/resources/rawfile/data/licenses/LGPL.txt`.

## Curriculum data

- Source: athenayan123-web/dictation-robot, `server/data/chinese_textbook.json`
  (人教版 / 部编版小学语文 12 册，按册 → 单元 → 课 → 生字/词语组织).
- License: MIT. License text: `data/licenses/CHINESE_TEXTBOOK_MIT.txt`.
- The public repository ships only the minimal `data/seed/` dataset; the full
  dataset is generated locally by the scripts in `tools/`. See `DATA_LICENSE.md`.

## HarmonyOS / HDS

- HarmonyOS UI Design Kit and ScaffoldApp template are used under their
  respective project terms. The application code in this repository is MIT.
