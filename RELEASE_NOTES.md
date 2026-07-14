# Release Notes

## Unreleased — Sticky HARD GATE + turn-gate (Grok + Codex)

Mood-first **sticky** vision-in-the-loop: arm with `/agent-vision` (default mood), then on each **non-whitelist** turn **capture → understand the image → USE image content in reasoning** until `/agent-vision off`.

### Product

- New chat always starts **OFF** (leftover state file alone does not arm)
- Disarm: `off`, stop, disable, “turn off the camera”, “agent vision off”
- **HARD GATE:** capture without use is invalid; topic is irrelevant; blind-identical answers are invalid
- Disposition playbooks for delivery only (do not change facts/permissions/scope)
- Ambiguity burst: one second one-shot capture if the first frame is unusable
- Still one-shot capture process per look (not always-on daemon); streaming disabled; no production MCP

### Helpers (never start camera)

| Script | Role |
| --- | --- |
| `scripts/agent-vision-sticky.sh` | Session arm/off/status (`~/.agent-vision/session-state.json`) |
| `scripts/agent-vision-turn-gate.sh` | Per-turn `begin` / `record` / single-use `ready` |
| `scripts/agent-vision-purge-frames.sh` | TTL frame cleanup (`--all` / `--grok` / `--codex`) |

Installers stage PATH shims (`agent-vision-sticky`, `agent-vision-turn-gate`, `agent-vision-purge-frames`).

### Host skills

- **Grok:** multimodal `read_file`; `disable-model-invocation: false` so sticky can run with gates; slim skill core + `references/mood-roast-recipes.md`
- **Codex:** `codex exec -i` for mood/roast; same HARD GATE + turn-gate policy in `skills/camera-control`
- Status: `/agent-vision status` → sticky + `last_capture_age_seconds` (no mood JSON)

### Tests

- `scripts/test-grok-adapter.sh` (HARD GATE / sticky / turn-gate contracts)
- `scripts/test-grok-sticky-state.sh`
- `scripts/test-agent-vision-turn-gate.sh` (single-use ready)
- `scripts/test-agent-vision-purge-frames.sh`

### Upgrade

Re-run host install (`scripts/install-grok.sh` and/or Codex plugin reinstall / `scripts/install-local.sh`). Open a **new** session so the skill reloads.

Docs: [docs/agent-vision-grok-session-sticky.md](docs/agent-vision-grok-session-sticky.md).

## 1.5.0 — Grok Build support

Unified multi-host release: **Codex** and **Grok Build** both ship as first-class hosts under package version **1.5.0**.

### Highlights

- **Grok Build (initial package cut):** `/agent-vision snapshot` via shared runtime + Grok skill adapter (roast/mood/sticky HARD GATE landed on main in the Unreleased section above).
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
- No production MCP on Grok.
- Supported capture environment: Grok **sandbox off** (default).
- Initial Grok package cut was snapshot-first; roast, mood, sticky HARD GATE, and `disable-model-invocation: false` follow in the Unreleased section above.
- Release tarball includes `hosts/grok/` and runtime/Grok install scripts under `scripts/`.

### Codex

- Plugin cache path: `~/.codex/plugins/cache/local/agent-vision/1.5.0`.
- Install removes prior package caches including **1.0.3**, **1.0.2**, **1.0.1**, and **1.0.0**.
- Snapshot, roast, mood frame path still under `~/.codex/agent-vision/frames` (sticky policy on main).

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
