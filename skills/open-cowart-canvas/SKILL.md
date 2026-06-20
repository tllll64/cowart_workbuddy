---
name: open-cowart-canvas
description: Open the Cowart local web service, a tldraw-powered infinite canvas. Use when the user asks to open, launch, view, or work in the Cowart canvas or wants an infinite canvas inside Codex.
---

# Open Cowart Canvas

## Workflow

1. Start the local Cowart web service with the user's current Codex project directory, and keep the process running:

```bash
/Users/bytedance/plugins/cowart/scripts/start-canvas.sh /path/to/user/codex-project
```

Use the active workspace or project directory from the current Codex session for `/path/to/user/codex-project`. Do not pass the Cowart plugin directory.

2. Open the resulting local URL in the Codex in-app browser when the Browser tool chain is available.

The default URL is `http://127.0.0.1:43217/`. If the service output prints a different `Local:` URL, open that actual URL instead.

Use the Browser plugin's `control-in-app-browser` skill as the source of truth for opening the in-app browser. The correct model-side flow is:

1. Use tool discovery for the Node REPL JavaScript execution tool if it is not already visible. The required callable tool is the `js` execution tool, commonly exposed as `mcp__node_repl__js`; `js_reset` and `js_add_node_module_dir` are not sufficient for browser control.
2. In a fresh Node REPL session, bootstrap the Browser runtime with the Browser plugin's packaged client, using the absolute `browser-client.mjs` path:

```js
const { setupBrowserRuntime } = await import("/Users/bytedance/.codex/plugins/cache/openai-bundled/browser/26.616.41845/scripts/browser-client.mjs");
await setupBrowserRuntime({ globals: globalThis });
globalThis.browser = await agent.browsers.get("iab");
nodeRepl.write(await browser.documentation());
```

3. Select or create a tab, make the browser visible because this skill is meant to open the canvas for the user, and navigate with `tab.goto(url)`:

```js
await (await browser.capabilities.get("visibility")).set(true);
globalThis.tab = (await browser.tabs.selected()) ?? await browser.tabs.new();
if ((await tab.url()) !== url) {
  await tab.goto(url);
}
```

Do not call `tab.goto(url)` if the selected tab is already on the Cowart URL; that reloads the page and can disturb work in progress. If browser control is unavailable, or browser bootstrap fails before navigation with a tool-layer/session-metadata error such as `codex/sandbox-state-meta: missing field sandboxPolicy`, treat the Cowart service start as successful and give the user the local URL instead of retrying browser control.

## Constraints

Do not inspect canvas files, call canvas APIs, run builds, check storage layout, take screenshots, or perform other validation steps unless opening the canvas fails or the user explicitly asks for those checks.
