# Install Agent Vision

Ask Codex to install Agent Vision from the repository URL:

```text
Install Agent Vision from https://github.com/zfifteen/agent-vision
```

Codex should download the packaged release from that repository, extract it, run the package `install.sh`, and then open a new Codex session so `/agent-vision` is loaded.

Manual package install:

```bash
curl -L -o agent-vision-1.0.3.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.0.3/agent-vision-1.0.3.tar.gz
tar -xzf agent-vision-1.0.3.tar.gz
cd agent-vision-1.0.3
./install.sh
```

The installer stages the signed packaged `AgentVision.app`, stages the plugin under `~/plugins/agent-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `agent-vision@local` in `~/.codex/config.toml`.

Agent Vision 1.0.3 does not register an MCP server. Install, plugin enablement, idle Codex startup, unrelated prompts, `/agent-vision streaming`, and stop-streaming requests must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

If an already-open Codex chat does not show `/agent-vision` after a successful install, open a new Codex chat or session so the slash-command index refreshes.

For QA traceability against the available OpenAI/Codex plugin guidance, see [docs/agent-vision-install-uninstall-traceability.md](docs/agent-vision-install-uninstall-traceability.md).

## Developer Source Install

Source installs are for developers and release producers only. Do not use this path for a normal user install.

```bash
git clone https://github.com/zfifteen/agent-vision.git
cd agent-vision
scripts/install-local.sh
```

The source installer builds and signs `AgentVision.app` locally, so it requires Swift, Xcode command line tools, and a local signing identity.

## First Use

Agent Vision installs one slash command with four public arguments:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
/agent-vision mood
```

`/agent-vision snapshot` starts the camera if needed, waits for a usable JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera. If the camera returns a black warm-up frame, Agent Vision keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts.

`/agent-vision streaming` is temporarily disabled in 1.0.3 while the runtime is being moved to an explicit start/stop design. It launches no Agent Vision process.

`/agent-vision roast` is snapshot plus prose: it materializes one usable JPEG, passes that exact file to `codex exec -i`, displays the saved image, and returns one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.

`/agent-vision mood` is snapshot plus delivery calibration: it materializes one usable JPEG, passes that exact file to `codex exec -i`, and uses strict JSON internally for current-response delivery only.

To stop streaming, ask Codex to stop camera use:

```text
Agent Vision streaming off
```

In 1.0.3, Codex reports that there is no Agent Vision streaming session to stop and launches no Agent Vision process.

macOS will ask for camera permission for `AgentVision.app` the first time the capture session starts. Repeated prompts usually mean the app identity changed and the local installer should be rerun.

## Uninstall

Run the deterministic local uninstaller:

```bash
./uninstall.sh
```

The uninstaller removes `~/plugins/agent-vision`, the local Codex plugin cache, the local marketplace entry, the `agent-vision@local` plugin config entry, legacy `mcp_servers.agent_vision` config, and legacy `codex-vision` rebrand artifacts.
