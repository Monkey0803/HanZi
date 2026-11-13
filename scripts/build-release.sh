#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVECO_ROOT="${DEVECO_ROOT:-/Applications/DevEco-Studio.app/Contents}"
export PATH="$DEVECO_ROOT/tools/hvigor/bin:$DEVECO_ROOT/tools/ohpm/bin:$PATH"
if [[ ! -d "${DEVECO_SDK_HOME:-}" ]]; then
  export DEVECO_SDK_HOME="$DEVECO_ROOT/sdk"
fi
if [[ ! -d "${JAVA_HOME:-}" ]]; then
  export JAVA_HOME="$DEVECO_ROOT/jbr/Contents/Home"
fi

cd "$ROOT_DIR/tools"
npm ci
npm run data:all

cd "$ROOT_DIR"
ohpm install --all
if command -v devecocli >/dev/null 2>&1; then
  devecocli build --mode release
else
  hvigorw assembleHap --mode module -p product=default -p buildMode=release --no-daemon
fi

HAP_PATH="$(find "$ROOT_DIR/entry/build" -type f -path '*/outputs/default/*-signed.hap' | head -n 1)"
if [[ -z "$HAP_PATH" ]]; then
  echo "未找到 release HAP" >&2
  exit 1
fi

unzip -l "$HAP_PATH" | grep -q 'resources/rawfile/data/full/curriculum/meta.tsv'
unzip -l "$HAP_PATH" | grep -q 'resources/rawfile/data/full/licenses/CHINESE_TEXTBOOK_MIT.txt'
echo "release 数据校验通过：$HAP_PATH"
