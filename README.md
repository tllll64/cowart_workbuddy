# Cowart for WorkBuddy

Cowart 是一个面向 **WorkBuddy** 的本地无限画布插件。它基于 tldraw 提供可视化画布，用于构思、标注、生成图片，以及根据标注图迭代图片。画布运行在本地网页服务中，数据默认保存到当前用户项目的 `canvas/` 目录，而不是保存到插件仓库里。

> 本仓库是基于 [zhongerxin/cowart](https://github.com/zhongerxin/cowart) 的 WorkBuddy 适配版本。原版面向 Codex；本版本针对 WorkBuddy 客户端的安装路径、MCP 注册方式、信任流程做了改造。

English README: 暂未翻译。

## 功能

- 在 WorkBuddy 中通过 `preview_url` 打开一个本地 tldraw 无限画布。
- 在当前项目目录中持久化画布页面和图片资源。
- 在画布中创建 AI image holder，让 WorkBuddy 通过 `ImageGen` 生成图片并自动填入选中的 holder。
- 上传或提供 Cowart 标注截图，让 WorkBuddy 根据标注生成干净的新图并放到原图旁边。
- 通过 Cowart MCP 工具读取选择状态、插入图片，并保存到页面本地资源目录。

## 系统要求

- macOS（推荐）/ Linux
- WorkBuddy 客户端（已登录、已挂载默认连接器）
- Node.js 22 及以上
- 一个能跑 `git` 和 `bash` 的终端

## 一键安装（推荐 · WorkBuddy 用户）

把下面这段发给 WorkBuddy：

```text
请帮我安装 Cowart for WorkBuddy 插件，仓库地址：https://github.com/tllll64/cowart_workbuddy.git

步骤：
1. 把仓库 clone 到 ~/plugins/cowart（如果已存在则先备份再 clone）。
2. 运行 ./scripts/install-workbuddy.sh 完成 macOS 扩展属性清理、依赖安装、MCP 注册与连接器启用。
3. 让我知道是否需要重启 WorkBuddy 或开新对话来加载新的 skill 和 MCP 工具。
```

WorkBuddy 会自动完成全部步骤。完成后**新建一个对话**即可使用。

## 手动安装

```bash
mkdir -p ~/plugins
git clone https://github.com/tllll64/cowart_workbuddy.git ~/plugins/cowart
cd ~/plugins/cowart
./scripts/install-workbuddy.sh
```

`install-workbuddy.sh` 会自动完成：

1. `xattr -rc .` 清除 macOS 扩展属性（解决 `EPERM: mkdir node_modules` 问题）。
2. `npm install` 安装依赖。
3. `npm run build` 生成 `dist/`。
4. 在 `~/.workbuddy/mcp.json` 注册 `cowart_mcp` MCP server。
5. 在 `~/.workbuddy/connectors/<account>/connector-states.json` 的 `enabled` 数组里加入 `cowart_mcp`，等价于"在 WorkBuddy 客户端里点信任"。

### 手动验证（可选）

```bash
cat ~/.workbuddy/mcp.json | grep cowart
cat ~/.workbuddy/connectors/*/connector-states.json | grep cowart
```

两条都能看到 `cowart_mcp` 字样即视为安装成功。

### 完成后

**完全退出 WorkBuddy 后重新打开**（Cmd+Q 之后再启动），或在已运行的客户端中 `/new` 开一个新对话，WorkBuddy 会自动拉起 `cowart_mcp` 并把工具注入对话上下文。

## 使用

### 打开画布

在 WorkBuddy 中说：

```text
帮我打开 Cowart 画布。
```

WorkBuddy 会启动本地 vite 服务并通过 `preview_url` 把画布嵌入对话面板。**端口不是固定的**：默认 `43217`，被占用时 vite 会自动迁移到 `43218`、`43219`……以脚本最后输出的 `Local:` URL 为准。

画布数据会保存在当前项目目录下：

```text
canvas/pages/<page-id>/cowart-canvas.json
canvas/pages/<page-id>/assets/
```

> 📷 WorkBuddy 版截图整理中，稍后补上。

### 生成新图

1. 打开 Cowart 画布。
2. 在画布里创建并选中一个 AI image holder（可选；不选也可以生成后插到当前页空白处）。
3. 在 WorkBuddy 中描述要生成的图片，例如：

```text
帮我生成一张"水彩风格的红色苹果"，插到当前画布上。
```

WorkBuddy 会调用内置 `ImageGen` 生成图片，并通过 `insert_cowart_image` 自动插入画布。

> 📷 WorkBuddy 版截图整理中，稍后补上。

### 根据标注图生成新图

1. 在 Cowart 画布中对图片做标注。
2. 截图并把标注截图发给 WorkBuddy。
3. 使用提示：

```text
根据我的 Cowart 标注截图，生成一张去掉标注痕迹的新图，放到原图旁边。
```

WorkBuddy 会读取截图里的标注和箭头，生成干净的修订图，并把结果放在原图旁边。原图和标注**不会**被删除或移动。

> 📷 WorkBuddy 版截图整理中，稍后补上。

## 技能

- `cowart:cowart-open-canvas`：打开 Cowart 本地画布并嵌入 WorkBuddy 浏览器面板。
- `cowart:cowart-image-gen`：把生成图片插入选中的 AI image holder（或当前页）。
- `cowart:cowart-image-edit`：根据用户提供的 Cowart 标注截图生成修订图。

## 本地开发

```bash
npm install
npm run dev      # 启动 vite 画布
npm run build    # 构建 dist
```

或直接启动画布服务并指定用户项目目录：

```bash
./scripts/start-canvas.sh /path/to/user/project
```

启动脚本会**自动调用 `xattr -rc .` 兜底**，避免 macOS 扩展属性导致 `npm install` 失败。

常用环境变量：

- `COWART_PORT`：本地服务的**首选**端口，默认 `43217`。被占用时 vite 会自动迁移。
- `COWART_PROJECT_DIR`：画布数据所属的用户项目目录。
- `COWART_CANVAS_DIR`：画布数据目录，默认是 `$COWART_PROJECT_DIR/canvas`。

## 卸载

```bash
./scripts/uninstall-workbuddy.sh
rm -rf ~/plugins/cowart
```

卸载脚本会把 `cowart_mcp` 从 `~/.workbuddy/mcp.json` 与 `connector-states.json` 移除。

## 故障排查

请参考 [`docs/INSTALL-WORKBUDDY.md`](docs/INSTALL-WORKBUDDY.md) 的"常见问题"部分。

## 开发者

- 原版作者：ZHONG XIN（[https://www.jiqiren.ai](https://www.jiqiren.ai)）
- WorkBuddy 适配：田琳 (Lynn)

## 致谢

Cowart 的画布能力基于 [tldraw/tldraw](https://github.com/tldraw/tldraw) 实现。
