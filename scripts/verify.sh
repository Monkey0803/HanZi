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

cd "$ROOT_DIR"
ohpm install --all

if command -v devecocli >/dev/null 2>&1; then
  devecocli build
  devecocli check lint
  devecocli check arkts
  devecocli build --modules entry@ohosTest
else
  echo "devecocli 不可用，改用 hvigorw 完成主工程与测试包编译；lint/arkts 独立检查跳过。" >&2
  hvigorw assembleHap --mode module -p product=default --no-daemon
  hvigorw assembleHap --mode module -p product=default -p module=entry@ohosTest --no-daemon
fi

cd "$ROOT_DIR/tools"
npm run data:validate
