# Release Notes

## Unreleased — Grok Build Ship A (public)

Adds an experimental **Grok Build** host adapter alongside the stable Codex 1.0.3 package. Codex behavior is unchanged.

### Version strings (Ship A)

| Surface | String | Meaning |
| --- | --- | --- |
| Codex package / `.codex-plugin` / `Info.plist` | **1.0.3** | Stable Codex-packaged release (unchanged) |
| Shared runtime `INSTALL_META` / Grok `plugin.json` | **1.0.4-ship-a** | Grok Ship A adapter + runtime install track |
| Full multi-host product claim | **not used** | Reserved for future `1.1.0` (Ship B) |

### Grok Build (Ship A)

- Shared runtime installer: `scripts/install-runtime.sh` → `~/.local/share/agent-vision` + `~/.local/bin/agent-vision-capture-file` shim.
- Grok skill/plugin: `hosts/grok/`, `scripts/install-grok.sh` / `uninstall-grok.sh`.
- `/agent-vision snapshot` on Grok: one-shot JPEG under `~/.agent-vision/frames`, multimodal `read_file` ingest, Markdown image display.
- Streaming disabled with version-agnostic fixed copy; stop-streaming launches no process.
- No production MCP registration on Grok; `disable-model-invocation: true` on the skill.
- Supported capture environment: Grok **sandbox off** (default).
- Static tests: `scripts/test-grok-adapter.sh`; CLI errors: `scripts/test-capture-file-cli.sh`.
- Roast and mood on Grok are **not** included (Milestone 2).

### Codex

- Remains on the **1.0.3** package path (snapshot, roast, mood; no production MCP).
- Frame path and plugin cache paths frozen for this cut.

### Docs

- Multi-host README / INSTALL / PRIVACY.
- [docs/agent-vision-grok-build-compatibility.md](docs/agent-vision-grok-build-compatibility.md)
- [docs/agent-vision-grok-install-uninstall-traceability.md](docs/agent-vision-grok-install-uninstall-traceability.md)

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
