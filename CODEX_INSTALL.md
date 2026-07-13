# Codex Installation Instructions

**Codex only.** For Grok Build, use [INSTALL.md](INSTALL.md#grok-build-ship-a) (`scripts/install-runtime.sh` + `scripts/install-grok.sh`). Do not run this Codex package flow when the user asked for Grok.

These instructions are for a local Codex agent asked to install Agent Vision from:

```text
https://github.com/zfifteen/agent-vision
```

Install the packaged release. Do not clone the repository and run `scripts/install-local.sh` unless the user explicitly asks for a developer/source install.

1. Download the release archive:

```bash
curl -L -o agent-vision-1.0.3.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.0.3/agent-vision-1.0.3.tar.gz
```

2. Extract the release archive:

```bash
tar -xzf agent-vision-1.0.3.tar.gz
cd agent-vision-1.0.3
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

The installer removes legacy duplicate `mcp_servers.agent_vision` and `mcp_servers."agent-vision"` config. Agent Vision 1.0.3 does not register an MCP server, and the installed package must not contain `dist/agent-vision-mcp`.

For QA traceability against the available OpenAI/Codex plugin guidance, see `docs/agent-vision-install-uninstall-traceability.md`.

5. Use the bundled slash command:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
/agent-vision mood
```

Version 1.0.3 is explicit and one-shot:

- `/agent-vision snapshot` waits for one usable JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera.
- `/agent-vision streaming` is temporarily disabled and launches no Agent Vision process.
- `/agent-vision roast` is snapshot plus prose: it materializes one usable JPEG, passes that exact file to `codex exec -i`, displays the saved image, and returns one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.
- `/agent-vision mood` materializes one usable JPEG, passes that exact file to `codex exec -i`, and uses strict JSON internally for current-response delivery only.
- Stop-streaming requests report that there is no Agent Vision streaming session to stop and launch no Agent Vision process.

Required idle invariant:

```bash
! pgrep -f 'agent-vision-mcp|AgentVision .*mcp-fifo'
```

To uninstall the local plugin deterministically:

```bash
./uninstall.sh
```
