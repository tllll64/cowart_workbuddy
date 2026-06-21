#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CALLER_DIR="$PWD"
PORT="${COWART_PORT:-43217}"
PROJECT_DIR="${COWART_PROJECT_DIR:-${1:-$CALLER_DIR}}"
CANVAS_DIR="${COWART_CANVAS_DIR:-$PROJECT_DIR/canvas}"

export COWART_PROJECT_DIR="$PROJECT_DIR"
export COWART_CANVAS_DIR="$CANVAS_DIR"

cd "$ROOT_DIR"

# macOS 兜底：清除 com.apple.provenance 扩展属性，避免 npm install / vite build 报 EPERM
if [ "$(uname)" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  xattr -rc "$ROOT_DIR" 2>/dev/null || true
fi

if [ ! -d node_modules ] || [ ! -x node_modules/.bin/vite ]; then
  npm install
fi

echo "Cowart canvas: http://127.0.0.1:${PORT} (vite 可能因端口占用自动迁移到 43218/43219...，以下方 Local: 实际 URL 为准)"
echo "Cowart canvas data: ${CANVAS_DIR}/pages/<page-id>/cowart-canvas.json"
echo "Cowart page assets: ${CANVAS_DIR}/pages/<page-id>/assets -> http://127.0.0.1:<port>/page-assets/<page-id>/"
exec npm run dev -- --host 127.0.0.1 --port "$PORT"
