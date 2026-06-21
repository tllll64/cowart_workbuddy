# Cowart for WorkBuddy 安装指南

## TL;DR

```bash
git clone https://github.com/tllll64/cowart_workbuddy.git ~/plugins/cowart
cd ~/plugins/cowart
./scripts/install-workbuddy.sh
```

之后**完全退出 WorkBuddy 再重新打开**（Cmd+Q 后再启动），就能用了。

---

## 完整流程

### 1. 准备环境

- macOS（推荐）
- Node.js 22 或更高（命令行运行 `node -v` 检查）
- 已经登录 WorkBuddy 客户端

### 2. Clone 仓库

```bash
mkdir -p ~/plugins
git clone https://github.com/tllll64/cowart_workbuddy.git ~/plugins/cowart
```

仓库**必须放到 `~/plugins/cowart`**，否则脚本里的默认路径不会生效。

### 3. 跑一键脚本

```bash
cd ~/plugins/cowart
./scripts/install-workbuddy.sh
```

脚本会完成下面这些事，按顺序执行：

| 步骤 | 干了什么 | 为什么需要 |
|---|---|---|
| 1 | `xattr -rc .` | macOS 给从浏览器下载/git clone 的文件加 `com.apple.provenance` 属性，会导致 `npm install` / `vite build` 报 `EPERM: mkdir`。清掉就能装。 |
| 2 | `npm install` | 装 vite、react、tldraw 等依赖 |
| 3 | `npm run build` | 生成 `dist/`（生产构建产物） |
| 4 | 把 `cowart_mcp` 写进 `~/.workbuddy/mcp.json` | 注册 MCP server |
| 5 | 把 `cowart_mcp` 加进 `~/.workbuddy/connectors/<account>/connector-states.json` 的 `enabled` 数组 | 等价于"在 WorkBuddy 客户端里点信任" |

### 4. 重启 WorkBuddy

**完全退出**（Cmd+Q）后再打开。WorkBuddy 启动时才会拉起 `cowart_mcp` 并把工具注入对话上下文。

---

## 如何在客户端里手动"信任 MCP"（一般不需要）

如果一键脚本因为权限问题没能改 `connector-states.json`，或者你想在 UI 上确认状态，做这两步：

1. **打开 WorkBuddy 主界面**，看到对话输入框上方一排连接器图标（百度网盘、腾讯文档、GitHub 等等）。
2. **找到 cowart_mcp 这一条**，点击右侧的"信任"按钮，再切换为"打开"。

如果连 cowart_mcp 这一条都不显示，说明 `~/.workbuddy/mcp.json` 没写进去，回去重跑 `./scripts/install-workbuddy.sh`。

---

## 卸载

```bash
cd ~/plugins/cowart
./scripts/uninstall-workbuddy.sh
rm -rf ~/plugins/cowart
```

卸载脚本会从 `~/.workbuddy/mcp.json` 删掉 `cowart_mcp`，并把它从 `connector-states.json` 的 `enabled` 数组移除。

---

## 常见问题

### Q1：跑 `install-workbuddy.sh` 报 `npm: command not found`

```bash
node -v
npm -v
```

如果都不存在，去装一下 [Node.js LTS](https://nodejs.org/)。本插件需要 Node 22 及以上。

---

### Q2：`npm install` 报 `EPERM: operation not permitted, mkdir '.../node_modules'`

这是 macOS `com.apple.provenance` 扩展属性导致的。正常情况下脚本第一步已经清过了。如果还报，手动跑一次：

```bash
xattr -rc ~/plugins/cowart
cd ~/plugins/cowart
npm install
```

---

### Q3：新对话里看不到 `cowart_mcp` 工具

按顺序检查：

```bash
# 1) 配置写进去了吗
grep cowart ~/.workbuddy/mcp.json

# 2) 在 enabled 数组里吗
grep cowart ~/.workbuddy/connectors/*/connector-states.json

# 3) MCP server 自身能跑吗
node /Users/$USER/plugins/cowart/mcp/server.mjs <<< '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

三条都正常的话，**完全退出 WorkBuddy（Cmd+Q）再重新打开**。客户端运行中改 `connector-states.json` 不会自动生效。

---

### Q4：画布打开后端口不是 43217

vite 检测到端口被占用会自动迁移到 43218 → 43219……以脚本启动时打印的 `Local:` URL 为准，不要写死。

如果想强制使用某个端口：

```bash
COWART_PORT=8181 ./scripts/start-canvas.sh /path/to/your/project
```

---

### Q5：画布数据保存在哪？

默认保存在你启动 `start-canvas.sh` 时指定的项目目录下：

```text
<projectDir>/canvas/pages/<page-id>/cowart-canvas.json
<projectDir>/canvas/pages/<page-id>/assets/
```

可以通过环境变量改：

- `COWART_PROJECT_DIR`：项目目录
- `COWART_CANVAS_DIR`：直接指定画布目录，优先级更高
