#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

# macOS 兜底：清除 com.apple.provenance 扩展属性，避免 npm install 报 EPERM
if [ "$(uname)" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  xattr -rc "$ROOT_DIR" 2>/dev/null || true
fi

if [ ! -d node_modules ] || [ ! -d node_modules/fractional-indexing ]; then
  npm install
fi

exec node ./mcp/server.mjs
