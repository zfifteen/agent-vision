# Release Notes

## 1.0.3

Emergency production hotfix for the Agent Vision runtime lifecycle.

- Removes the installed Agent Vision MCP server registration.
- Excludes `dist/agent-vision-mcp` from the packaged runtime.
- Preserves explicit one-shot capture through `dist/agent-vision-capture-file`.
- Disables streaming until it has an explicit start/stop runtime independent of Codex plugin-load MCP lifecycle.
- Requires install, plugin enablement, idle Codex startup, unrelated prompts, streaming requests, and stop-streaming requests to create no Agent Vision process.
- Removes installed `1.0.2` cache during install/uninstall.

## 1.0.2

Affected release.

Version 1.0.2 registered Agent Vision as a plugin MCP server. Codex could eagerly start that server and launch `AgentVision.app mcp-fifo` without an explicit `/agent-vision` request.
