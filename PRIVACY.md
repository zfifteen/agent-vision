# Privacy Policy

Agent Vision is a local macOS camera appliance for coding agents. Package **1.5.0** supports **Codex** (snapshot, roast, mood) and **Grok Build** public Ship A (snapshot only).

## Data Handling

Agent Vision captures images from the built-in Mac camera only when an installed slash-command skill runs the local file materializer for an explicit one-shot request.

- **Codex** snapshot mode starts the camera, captures one JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera.
- **Grok Build (Ship A)** snapshot mode saves under `~/.agent-vision/frames` and uses local multimodal image read after capture; roast and mood are not in the Grok Ship A cut.
- Codex roast mode uses snapshot file materialization, then passes the saved JPEG to `codex exec -i` for the opt-in roast text.
- Codex mood mode uses snapshot file materialization, then passes the saved JPEG to `codex exec -i` for strict JSON used only as current-response delivery calibration.
- Streaming mode is temporarily disabled and launches no Agent Vision process on either host.

Agent Vision does not implement cloud upload, background recording, audio capture, device selection, telemetry, analytics, remote logging, an installed MCP server, or an idle camera-capable background process.

## Permissions

macOS asks for camera permission for the signed `AgentVision.app` the first time an explicit one-shot capture starts.

Install, plugin enablement, idle Codex or Grok startup, unrelated prompts, streaming requests, and stop-streaming requests must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

## Storage

Codex snapshot, roast, and mood mode intentionally write requested frames to `~/.codex/agent-vision/frames`. Grok Ship A snapshot writes to `~/.agent-vision/frames`. Hosts use those local paths so the assistant can display or inspect the JPEG through a proven local image-input path. The plugin does not upload or remotely log those files.

## Contact

For privacy questions, open an issue at:

https://github.com/zfifteen/agent-vision/issues
