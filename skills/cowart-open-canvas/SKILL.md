---
name: cowart-open-canvas
description: Open the Cowart local web service, a tldraw-powered infinite canvas. Use when the user asks to open, launch, view, or work in the Cowart canvas or wants an infinite canvas inside WorkBuddy.
---

# Cowart Open Canvas

This skill runs inside WorkBuddy. It starts the local Cowart canvas server and previews it in the WorkBuddy in-app browser panel via the `preview_url` tool.

## Workflow

1. Start the local Cowart web service with the user's current WorkBuddy project directory, and keep the process running:

```bash
~/plugins/cowart/scripts/start-canvas.sh /path/to/user/project
```

Use the active workspace or project directory from the current WorkBuddy session for `/path/to/user/project`. Do not pass the Cowart repository directory.

2. **Read the actual port from the server output.** The script prints a `Local: http://127.0.0.1:<port>/` line. The port is **not always 43217** — vite migrates to the next free port (43218, 43219, ...) when the preferred one is busy. Never hardcode the URL in subsequent steps.

3. Preview the canvas in WorkBuddy's built-in browser:

   Call the `preview_url` tool with the URL printed by the canvas server. WorkBuddy will embed the canvas into the side panel of the current conversation.

4. **If the Cowart MCP tools are not visible in the current conversation**, the `cowart_mcp` connector is not yet trusted. Tell the user, in the user's language:

   > 我看不到 Cowart MCP 工具。请在 WorkBuddy 主界面对话输入框上方的连接器栏里找到 `cowart_mcp`，点击右侧的"信任"按钮，再切换为"打开"。然后 **完全退出 WorkBuddy（Cmd+Q）并重新打开**，回到这里开一个新对话即可。

   If the user installed via `scripts/install-workbuddy.sh`, the connector should already be trusted automatically — in that case, ask the user to do a full WorkBuddy restart (`Cmd+Q` then relaunch) before opening a fresh conversation.

## Constraints

- Do not call any other Cowart tool until the canvas server is confirmed running.
- Do not hand-write canvas JSON; the `cowart_mcp` MCP server's `insert_cowart_image` and `get_cowart_selection` tools are the only supported way to modify the canvas from the conversation.
- Do not hardcode `http://127.0.0.1:43217/` anywhere. Always use the port printed by the running server.
