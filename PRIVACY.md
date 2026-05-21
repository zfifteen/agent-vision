# Privacy Policy

Agent Vision is a local macOS camera plugin for Codex.

## Data Handling

Agent Vision captures images from the built-in Mac camera only when the installed slash-command skill runs the local file materializer for an explicit one-shot request.

- Snapshot mode starts the camera, captures one JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera.
- Roast mode uses snapshot file materialization, then passes the saved JPEG to `codex exec -i` for the opt-in roast text.
- Mood mode uses snapshot file materialization, then passes the saved JPEG to `codex exec -i` for strict JSON used only as current-response delivery calibration.
- Streaming mode is temporarily disabled in Agent Vision 1.0.3 and launches no Agent Vision process.

Agent Vision does not implement cloud upload, background recording, audio capture, device selection, telemetry, analytics, remote logging, an installed MCP server, or an idle camera-capable background process.

## Permissions

macOS asks for camera permission for the signed `AgentVision.app` the first time an explicit one-shot capture starts.

Install, plugin enablement, idle Codex startup, unrelated prompts, streaming requests, and stop-streaming requests must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

## Storage

Snapshot, roast, and mood mode intentionally write requested frames to `~/.codex/agent-vision/frames` so Codex can display or inspect the JPEG through a proven local image-input path. The plugin does not upload or remotely log those files.

## Contact

For privacy questions, open an issue at:

https://github.com/zfifteen/agent-vision/issues
