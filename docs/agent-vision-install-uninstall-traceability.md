# Agent Vision Install/Uninstall Traceability Matrix

Date: 2026-07-13  
**Scope: Codex package 1.5.0** (+ sticky HARD GATE on main). For Grok Build, see [agent-vision-grok-install-uninstall-traceability.md](./agent-vision-grok-install-uninstall-traceability.md).  
Sticky contract (both hosts): [agent-vision-grok-session-sticky.md](./agent-vision-grok-session-sticky.md).

Agent Vision 1.5.0 is the multi-host package release (Codex + Grok Build). It preserves the 1.0.3 privacy hotfix: no production MCP server, and no camera-capable process on install, enable, idle startup, **disarmed** prompts, streaming, or stop-streaming.

Mainline skills add mood-first **sticky** sessions and a **HARD GATE** (use image content in reasoning while armed). The frozen 1.5.0 tarball may lag main; reinstall from main for sticky helpers.

## Runtime Invariant

Install, plugin enablement, idle Codex startup, **disarmed** prompts, `/agent-vision streaming`, pure status, and stop-streaming requests must not start:

```text
agent-vision-mcp
AgentVision.app
AgentVision.app mcp-fifo
```

Camera-capable code runs only for **armed** non-whitelist turns or explicit `/agent-vision snapshot` / `roast` / `mood` through `dist/agent-vision-capture-file`.

## Traceability Matrix

| Requirement | Agent Vision 1.5.0 Mapping | QA Check |
| --- | --- | --- |
| Plugin manifest is present and valid. | `.codex-plugin/plugin.json` exists, version is `1.5.0`, and it does not advertise `mcpServers`. | Parse manifest in `install.sh` and `scripts/install-local.sh --dry-run`. |
| No production MCP server is registered. | `.mcp.json` contains an empty `mcpServers` map, and the manifest does not reference it. | Inspect staged and cached package; assert no `agent-vision` server entry. |
| No MCP wrapper is installed. | `dist/agent-vision-mcp` is excluded from the release package and installed cache. | `test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-mcp"`. |
| One-shot capture remains available. | `dist/agent-vision-capture-file` launches signed `AgentVision.app capture-file` only for explicit snapshot-style / armed-turn requests. | Run `/agent-vision snapshot`, `/agent-vision roast`, and `/agent-vision mood`; assert no Agent Vision process remains afterward. |
| Sticky + HARD GATE (main) | `skills/camera-control` + sticky/turn-gate helpers | Manual arm multi-turn; `scripts/test-agent-vision-turn-gate.sh` |
| Streaming is disabled safely. | `/agent-vision streaming` and stop-streaming requests return fixed disabled text and launch no process. | Run slash-command matrix; assert no Agent Vision commands or tools fire for streaming cases. |
| Legacy eager-MCP installs are removed. | Installer and uninstaller remove `1.0.3`, `1.0.2`, `1.0.1`, `1.0.0`, legacy `codex-vision`, and direct MCP config sections. | Inspect `~/.codex/config.toml` and local plugin cache after install/uninstall. |
| Normal install has no developer-tool dependency. | Packaged `install.sh` uses system shell, `osascript`, `awk`, and `codex`; it does not build or sign locally. | `bash -n scripts/install-packaged.sh scripts/uninstall-packaged.sh scripts/agent-vision-capture-file.sh`. |

## Install Checks

```bash
curl -L -o agent-vision-1.5.0.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.5.0/agent-vision-1.5.0.tar.gz
tar -xzf agent-vision-1.5.0.tar.gz
cd agent-vision-1.5.0
./install.sh
test -d "$HOME/plugins/agent-vision"
test -d "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0"
test -x "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-capture-file"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-mcp"
! rg -n 'mcp_servers.agent_vision|mcp_servers."agent-vision"' "$HOME/.codex/config.toml"
! pgrep -f 'agent-vision-mcp|AgentVision .*mcp-fifo'
```

## Uninstall Checks

```bash
./uninstall.sh
test ! -e "$HOME/plugins/agent-vision"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.0.3"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.0.2"
! rg -n 'agent-vision|codex-vision|mcp_servers.agent_vision|plugins."agent-vision@local"' "$HOME/.codex/config.toml"
```

## Release Notes

- `1.0.2` is affected by the eager MCP launch bug.
- `1.0.3` removes the production Agent Vision MCP server and disables streaming.
- `1.5.0` unifies Codex + Grok Build under one package version; Codex keeps the no-MCP lifecycle. Grok roast/mood parity and sticky HARD GATE land on main after the initial 1.5.0 snapshot cut.
- A future streaming design must use an explicit user-started runtime with deterministic stop and no plugin-load process.
