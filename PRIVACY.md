# Privacy Policy

Agent Vision is a local macOS camera appliance for coding agents. Package **1.5.0**+ supports **Codex** and **Grok Build** with mood-first **sticky** sessions (arm with `/agent-vision`, disarm with `/agent-vision off`). Streaming is disabled on both hosts.

## Data Handling

Agent Vision captures images from the built-in Mac camera only when an installed slash-command skill runs the local file materializer:

- for an **explicit** one-shot mode (`snapshot`, `roast`, `mood` arm), or
- for a **sticky armed** turn that is not on the closed skip whitelist (pure off, pure status, pure streaming).

Each look is a **one-shot process** (camera on briefly, write one JPEG, camera off)—not an always-on recording daemon.

- **Codex** saves under `~/.codex/agent-vision/frames` and displays or analyzes via Markdown / `codex exec -i`.
- **Grok Build** saves under `~/.agent-vision/frames` and uses local multimodal `read_file` after capture.
- **Roast** (both hosts) uses snapshot file materialization, then analyzes the saved JPEG for an opt-in playful roast (Codex: `codex exec -i`; Grok: `read_file`).
- **Mood** (both hosts, default on arm) uses snapshot file materialization, then analyzes the saved JPEG for disposition and delivery calibration (Codex: `codex exec -i`; Grok: `read_file`). Mood does not display the image or JSON by default.
- **Sticky session:** after arm, each substantive (non-whitelist) turn **captures again** until the user turns Agent Vision off. **HARD GATE:** the agent must use image content in reasoning for that turn; capture without use is a contract failure.
- **New chat starts off.** Leftover session-state files alone do not arm. Install and idle startup never open the camera.
- **Turn-gate / sticky helpers** store small JSON under `~/.agent-vision/` (`session-state.json`, `turn-gate.json`). Those helpers never open the camera.
- Streaming mode is temporarily disabled and launches no Agent Vision process on either host.

Agent Vision does not implement cloud upload, background recording, audio capture, device selection, telemetry, analytics, remote logging, an installed MCP server, or an idle camera-capable background process.

## Permissions

macOS asks for camera permission for the signed `AgentVision.app` the first time an explicit capture starts.

Install, plugin enablement, idle Codex or Grok startup, disarmed prompts, streaming requests, and stop-streaming requests must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

## Storage

Codex snapshot, roast, and mood intentionally write requested frames to `~/.codex/agent-vision/frames`. Grok snapshot, roast, and mood write to `~/.agent-vision/frames`. Hosts use those local paths so the assistant can display or inspect the JPEG through a proven local image-input path. The plugin does not upload or remotely log those files.

Optional local retention cleanup: `agent-vision-purge-frames` (TTL-based; never starts the camera). Uninstall may remove frames only when you pass an explicit remove-frames flag.

## Contact

For privacy questions, open an issue at:

https://github.com/zfifteen/agent-vision/issues
