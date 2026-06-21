#!/usr/bin/env bash
# Cowart for WorkBuddy 卸载脚本：撤销 install-workbuddy.sh 写入的 WorkBuddy 配置。
# 不会删除 ~/plugins/cowart 仓库本身（请手动 rm -rf）。
set -euo pipefail

WORKBUDDY_HOME="${WORKBUDDY_HOME:-$HOME/.workbuddy}"
MCP_FILE="$WORKBUDDY_HOME/mcp.json"
CONNECTORS_DIR="$WORKBUDDY_HOME/connectors"
SERVER_NAME="cowart_mcp"

GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"
note() { printf "%b\n" "${GREEN}[cowart-uninstall]${RESET} $*"; }
warn() { printf "%b\n" "${YELLOW}[cowart-uninstall]${RESET} $*"; }

if [ -f "$MCP_FILE" ]; then
  note "从 $MCP_FILE 移除 $SERVER_NAME ..."
  node - "$MCP_FILE" "$SERVER_NAME" <<'NODE_EOF'
const fs = require("node:fs");
const [, , mcpFile, name] = process.argv;
const cfg = JSON.parse(fs.readFileSync(mcpFile, "utf8")) || {};
if (cfg.mcpServers && cfg.mcpServers[name]) {
  delete cfg.mcpServers[name];
  fs.writeFileSync(mcpFile, `${JSON.stringify(cfg, null, 2)}\n`, "utf8");
  console.log(`  -> 已移除`);
} else {
  console.log(`  -> 配置里没找到 ${name}，跳过`);
}
NODE_EOF
fi

if [ -d "$CONNECTORS_DIR" ]; then
  while IFS= read -r -d '' state_file; do
    note "  - 处理 $state_file"
    node - "$state_file" "$SERVER_NAME" <<'NODE_EOF'
const fs = require("node:fs");
const [, , stateFile, name] = process.argv;
let state = {};
try { state = JSON.parse(fs.readFileSync(stateFile, "utf8")) || {}; } catch (_) {}
let changed = false;
for (const key of ["enabled", "everConnected"]) {
  if (Array.isArray(state[key]) && state[key].includes(name)) {
    state[key] = state[key].filter((n) => n !== name);
    changed = true;
  }
}
if (changed) {
  fs.writeFileSync(stateFile, `${JSON.stringify(state, null, 2)}\n`, "utf8");
  console.log(`    -> 已移除`);
} else {
  console.log(`    -> 该 account 未启用 ${name}，跳过`);
}
NODE_EOF
  done < <(find "$CONNECTORS_DIR" -maxdepth 2 -name connector-states.json -print0 2>/dev/null)
fi

note "卸载完成。请退出并重启 WorkBuddy 让变更生效。"
warn "如需彻底清理，请手动：rm -rf ~/plugins/cowart"
