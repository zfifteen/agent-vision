# Codex Installation Instructions

**Codex only.** For Grok Build, use [INSTALL.md](INSTALL.md#grok-build) (`scripts/install-runtime.sh` + `scripts/install-grok.sh`). Do not run this Codex package flow when the user asked for Grok.

These instructions are for a local Codex agent asked to install Agent Vision from:

```text
https://github.com/zfifteen/agent-vision
```

Install the packaged release. Do not clone the repository and run `scripts/install-local.sh` unless the user explicitly asks for a developer/source install.

1. Download the release archive:

```bash
curl -L -o agent-vision-1.5.0.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.5.0/agent-vision-1.5.0.tar.gz
```

2. Extract the release archive:

```bash
tar -xzf agent-vision-1.5.0.tar.gz
cd agent-vision-1.5.0
```

3. Inspect the packaged app signature:

```bash
codesign --verify --deep --strict dist/AgentVision.app
```

4. Run the deterministic packaged installer:

```bash
./install.sh
```

If an already-open Codex chat does not show `/agent-vision` after a successful install, open a new Codex chat or session so the slash-command index refreshes.

The installer removes legacy duplicate `mcp_servers.agent_vision` and `mcp_servers."agent-vision"` config. Agent Vision 1.5.0 does not register an MCP server, and the installed package must not contain `dist/agent-vision-mcp`.

For QA traceability against the available OpenAI/Codex plugin guidance, see `docs/agent-vision-install-uninstall-traceability.md`.

Sticky HARD GATE / turn-gate / purge helpers ship on **main** after the 1.5.0 tarball. If the user wants that behavior, install from a current clone with `scripts/install-local.sh` (developer) or re-stage the latest skill + helper scripts. Contract: `docs/agent-vision-grok-session-sticky.md`.

5. Use the bundled slash command:

```text
/agent-vision
/agent-vision mood
/agent-vision snapshot
/agent-vision roast
/agent-vision status
/agent-vision off
/agent-vision streaming
```

Product model (mainline skill; package 1.5.0+ sticky updates):

- **Primary:** bare `/agent-vision` or `/agent-vision mood` **arms** sticky mood-first vision. While armed, each non-whitelist turn must capture → understand the image → **use image content in reasoning** (HARD GATE), then respond. New chat always starts **OFF**.
- `/agent-vision snapshot` waits for one usable JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, stops the camera for that look, and arms sticky.
- `/agent-vision streaming` is temporarily disabled and launches no Agent Vision process (does not arm).
- `/agent-vision roast` is snapshot plus prose: it materializes one usable JPEG, passes that exact file to `codex exec -i`, displays the saved image, returns one opt-in playful roast of 400 characters or fewer from visible non-sensitive details, and arms sticky.
- `/agent-vision mood` materializes one usable JPEG, passes that exact file to `codex exec -i`, and uses strict JSON internally for current-response delivery only (silent).
- `/agent-vision status` reports sticky + last-capture age without opening the camera when the turn is pure status.
- `/agent-vision off` (also stop / turn off the camera) **disarms** sticky. Stop-streaming-only phrases report that there is no Agent Vision streaming session and launch no Agent Vision process.
- Each look still uses a one-shot capture process (not an always-on daemon).

Required idle invariant:

```bash
! pgrep -f 'agent-vision-mcp|AgentVision .*mcp-fifo'
```

To uninstall the local plugin deterministically:

```bash
./uninstall.sh
```
