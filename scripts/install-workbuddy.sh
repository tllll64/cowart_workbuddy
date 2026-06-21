#!/usr/bin/env bash
# Cowart for WorkBuddy 一键安装脚本
# 完成内容：
#   1. 清除 macOS com.apple.provenance 扩展属性
#   2. npm install
#   3. npm run build
#   4. 把 cowart_mcp 注册到 ~/.workbuddy/mcp.json
#   5. 把 cowart_mcp 加进 ~/.workbuddy/connectors/<account>/connector-states.json 的 enabled 数组
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKBUDDY_HOME="${WORKBUDDY_HOME:-$HOME/.workbuddy}"
MCP_FILE="$WORKBUDDY_HOME/mcp.json"
CONNECTORS_DIR="$WORKBUDDY_HOME/connectors"
SERVER_NAME="cowart_mcp"
SERVER_SCRIPT="$ROOT_DIR/mcp/server.mjs"

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

note() { printf "%b\n" "${GREEN}[cowart-install]${RESET} $*"; }
warn() { printf "%b\n" "${YELLOW}[cowart-install]${RESET} $*"; }
fail() { printf "%b\n" "${RED}[cowart-install]${RESET} $*"; exit 1; }

cd "$ROOT_DIR"

# --- Step 0: 检查环境 ---
command -v node >/dev/null 2>&1 || fail "未找到 node。请先安装 Node.js 22+"
command -v npm  >/dev/null 2>&1 || fail "未找到 npm。请先安装 Node.js 22+"

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 22 ]; then
  warn "当前 Node 版本为 $(node -v)，建议 Node 22 或更高。"
fi

# --- Step 1: macOS 扩展属性兜底 ---
if [ "$(uname)" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  note "清除 macOS com.apple.provenance 扩展属性..."
  xattr -rc "$ROOT_DIR" 2>/dev/null || true
fi

# --- Step 2: npm install ---
if [ ! -d node_modules ] || [ ! -x node_modules/.bin/vite ]; then
  note "安装依赖（首次可能需要几分钟）..."
  npm install
else
  note "依赖已安装，跳过。"
fi

# --- Step 3: npm run build ---
note "构建 dist..."
npm run build

# --- Step 4: 注册 ~/.workbuddy/mcp.json ---
mkdir -p "$WORKBUDDY_HOME"

NODE_BIN="$(command -v node)"

note "向 $MCP_FILE 注册 $SERVER_NAME ..."
node - "$MCP_FILE" "$SERVER_NAME" "$NODE_BIN" "$SERVER_SCRIPT" "$ROOT_DIR" <<'NODE_EOF'
const fs = require("node:fs");
const path = require("node:path");
const [, , mcpFile, name, nodeBin, serverScript, cwd] = process.argv;

let cfg = { mcpServers: {} };
if (fs.existsSync(mcpFile)) {
  try { cfg = JSON.parse(fs.readFileSync(mcpFile, "utf8")) || {}; } catch (_) {}
}
if (!cfg.mcpServers || typeof cfg.mcpServers !== "object") cfg.mcpServers = {};

cfg.mcpServers[name] = {
  command: nodeBin,
  args: [serverScript],
  cwd,
};

fs.mkdirSync(path.dirname(mcpFile), { recursive: true });
fs.writeFileSync(mcpFile, `${JSON.stringify(cfg, null, 2)}\n`, "utf8");
console.log(`  -> 已写入 ${mcpFile}`);
NODE_EOF

# --- Step 5: 启用 connector-states.json ---
if [ -d "$CONNECTORS_DIR" ]; then
  note "把 $SERVER_NAME 加入所有 connector account 的 enabled 列表..."
  while IFS= read -r -d '' state_file; do
    note "  - 处理 $state_file"
    node - "$state_file" "$SERVER_NAME" <<'NODE_EOF'
const fs = require("node:fs");
const [, , stateFile, name] = process.argv;

let state = {};
try { state = JSON.parse(fs.readFileSync(stateFile, "utf8")) || {}; } catch (_) {}
state.enabled = Array.isArray(state.enabled) ? state.enabled : [];
state.everConnected = Array.isArray(state.everConnected) ? state.everConnected : [];
state.userDisabled = Array.isArray(state.userDisabled) ? state.userDisabled : [];

if (!state.enabled.includes(name)) state.enabled.push(name);
if (!state.everConnected.includes(name)) state.everConnected.push(name);
state.userDisabled = state.userDisabled.filter((n) => n !== name);

fs.writeFileSync(stateFile, `${JSON.stringify(state, null, 2)}\n`, "utf8");
console.log(`    -> 已启用`);
NODE_EOF
  done < <(find "$CONNECTORS_DIR" -maxdepth 2 -name connector-states.json -print0 2>/dev/null)
else
  warn "未找到 ${CONNECTORS_DIR} 。请先在 WorkBuddy 客户端登录一次，再重跑本脚本。"
fi

# --- 完成提示 ---
note ""
note "${GREEN}安装完成${RESET}"
note ""
note "${YELLOW}下一步：完全退出 WorkBuddy（Cmd+Q）后重新打开，或开一个新对话。${RESET}"
note "${DIM}WorkBuddy 启动后会自动加载 cowart_mcp，并把 get_cowart_selection / insert_cowart_image 工具注入到对话上下文。${RESET}"
note ""
note "试着对 WorkBuddy 说：${GREEN}帮我打开 Cowart 画布。${RESET}"
