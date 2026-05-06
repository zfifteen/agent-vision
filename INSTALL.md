# Install Agent Vision

Agent Vision requires macOS, Swift, and Xcode command line tools.

```bash
git clone https://github.com/zfifteen/agent-vision.git
cd agent-vision
scripts/install-local.sh
```

The installer builds `AgentVision.app`, stages the plugin under `~/plugins/agent-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `agent-vision@local` in `~/.codex/config.toml`.

If an already-open Codex chat does not show `/agent-vision` after a successful install, open a new Codex chat or session so the slash-command index refreshes.

The installer also registers `mcp_servers.agent_vision` in `~/.codex/config.toml`. Open a new Codex chat or session after install so the normal tool registry can load `agent_vision_snapshot`, `agent_vision_start`, `agent_vision_frame`, and `agent_vision_stop`.

## First Use

Agent Vision installs one slash command with three public arguments:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
```

`/agent-vision snapshot` starts the camera if needed, waits for a usable JPEG frame, returns it into the chat, and stops the camera only if snapshot started it. If the camera returns a black warm-up frame, Agent Vision keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts.

`/agent-vision streaming` starts streaming mode. While streaming is active, the Mac camera indicator should stay on and Codex can call `agent_vision_frame` when visual context would help.

`/agent-vision roast` is snapshot plus prose: it starts the camera if needed, waits for a usable JPEG frame, returns it into the chat, stops the camera only if roast started it, and asks Codex to write one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.

To stop streaming, ask Codex to stop camera use:

```text
Agent Vision streaming off
```

You can also say `stop streaming` or `turn off the camera`. Codex maps those requests to `agent_vision_stop`.

macOS will ask for camera permission for `AgentVision.app` the first time the capture session starts. Repeated prompts usually mean the app identity changed and the local installer should be rerun.

## Uninstall

Remove the staged plugin directory:

```bash
rm -rf ~/plugins/agent-vision
```

Then remove the `agent-vision` entry from `~/.agents/plugins/marketplace.json`, plus the `agent-vision@local` plugin entry and `mcp_servers.agent_vision` entry from `~/.codex/config.toml`.
