#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT/Editor"
npm ci
npm run build

cd "$ROOT"
XCODEGEN=$(command -v xcodegen || true)
if [ -z "$XCODEGEN" ] && [ -x /opt/homebrew/Cellar/xcodegen/2.45.4/bin/xcodegen ]; then
  XCODEGEN=/opt/homebrew/Cellar/xcodegen/2.45.4/bin/xcodegen
fi
if [ -z "$XCODEGEN" ]; then
  echo "XcodeGen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi
"$XCODEGEN" generate

