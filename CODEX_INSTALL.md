# Codex Installation Instructions

These instructions are for a local Codex agent asked to install Agent Vision from:

```text
https://github.com/zfifteen/agent-vision
```

Install the packaged release. Do not clone the repository and run `scripts/install-local.sh` unless the user explicitly asks for a developer/source install.

1. Download the release archive:

```bash
curl -L -o agent-vision-1.0.1.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.0.1/agent-vision-1.0.1.tar.gz
```

2. Extract the release archive:

```bash
tar -xzf agent-vision-1.0.1.tar.gz
cd agent-vision-1.0.1
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

The installer removes legacy duplicate `mcp_servers.agent_vision` config and relies on the plugin `.mcp.json` entry for `agent_vision_snapshot`, `agent_vision_start`, `agent_vision_frame`, and `agent_vision_stop`. Open a new Codex chat or session after install so the plugin tool registry refreshes.

For QA traceability against the available OpenAI/Codex plugin guidance, see `docs/agent-vision-install-uninstall-traceability.md`.

5. Use the MCP tools:

```text
agent_vision_snapshot
agent_vision_start
agent_vision_frame
agent_vision_stop
```

Or use the bundled slash commands:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
```

Version 1.0.1 is pull-based:

- `/agent-vision snapshot` waits for one usable JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera only if snapshot started it. If the camera returns a black warm-up frame, Agent Vision keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts.
- `/agent-vision streaming` starts a live camera session. The Mac camera indicator should stay on while this session is active.
- `/agent-vision roast` is snapshot plus prose: it materializes one usable JPEG, passes that exact file to `codex exec -i`, displays the saved image, and returns one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.
- While streaming is active, Codex may call `agent_vision_frame` whenever visual context would help, without asking for each frame.
- When the user asks to stop streaming or stop camera use, call `agent_vision_stop`.

To uninstall the local plugin deterministically:

```bash
./uninstall.sh
```
