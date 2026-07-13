# Release Notes

## Unreleased — Sticky vision session (Grok + Codex)

Mood-first **sticky** session: arm with `/agent-vision` (default mood), then on each **substantive** turn capture → understand the image → incorporate into reasoning until `/agent-vision off`.

- New chat always starts **OFF** (leftover state file alone does not arm)
- Disarm: `off`, stop, disable, “turn off the camera”
- `scripts/agent-vision-sticky.sh` for session state (never starts camera)
- Grok: `read_file` vision path; Codex: `codex exec -i` for mood/roast
- Still one-shot capture process per look (not always-on daemon); streaming disabled; no production MCP

Upgrade: re-run host install (`scripts/install-grok.sh` and/or Codex plugin reinstall). Open a **new** session.

## 1.5.0 — Grok Build support

Unified multi-host release: **Codex** and **Grok Build** both ship as first-class hosts under package version **1.5.0**.

### Highlights

- **Grok Build (initial):** `/agent-vision snapshot` via shared runtime + Grok skill adapter (roast/mood landed in the Unreleased cut above).
- **Codex:** same one-shot snapshot, roast, and mood paths; plugin cache moves to `.../1.5.0`.
- **Shared invariants preserved:** no production MCP server, no camera process on install/idle/unrelated prompts/streaming/stop-streaming.
- Streaming remains disabled with version-aligned fixed copy until an explicit start/stop runtime lands.

### Version

| Surface | String |
| --- | --- |
| Codex package / `.codex-plugin` / `Info.plist` | **1.5.0** |
| Shared runtime `INSTALL_META` / Grok `plugin.json` | **1.5.0** |
| GitHub release tag | **v1.5.0** |

### Grok Build

- Shared runtime: `scripts/install-runtime.sh` → `~/.local/share/agent-vision` + `~/.local/bin/agent-vision-capture-file` shim.
- Grok skill/plugin: `hosts/grok/`, `scripts/install-grok.sh` / `uninstall-grok.sh`.
- Snapshot JPEG under `~/.agent-vision/frames`; multimodal `read_file` ingest; Markdown image display.
- Streaming disabled (fixed copy, no process); stop-streaming launches no process.
- No production MCP on Grok; `disable-model-invocation: true` on the skill.
- Supported capture environment: Grok **sandbox off** (default).
- Initial Grok cut was snapshot-first; roast and mood follow in the Unreleased section above.
- Release tarball includes `hosts/grok/` and runtime/Grok install scripts under `scripts/`.

### Codex

- Plugin cache path: `~/.codex/plugins/cache/local/agent-vision/1.5.0`.
- Install removes prior package caches including **1.0.3**, **1.0.2**, **1.0.1**, and **1.0.0**.
- Snapshot, roast, mood unchanged in behavior; frames still under `~/.codex/agent-vision/frames`.

### Docs

- Multi-host README / INSTALL / PRIVACY / CODEX_INSTALL updated for **1.5.0**.
- [docs/agent-vision-grok-build-compatibility.md](docs/agent-vision-grok-build-compatibility.md)
- [docs/agent-vision-grok-install-uninstall-traceability.md](docs/agent-vision-grok-install-uninstall-traceability.md)

### Install (packaged)

Codex:

```bash
curl -L -o agent-vision-1.5.0.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.5.0/agent-vision-1.5.0.tar.gz
tar -xzf agent-vision-1.5.0.tar.gz
cd agent-vision-1.5.0
./install.sh
```

Grok (from the same package tree, with signed `dist/`):

```bash
scripts/install-runtime.sh
scripts/install-grok.sh
```

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
