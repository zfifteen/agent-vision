# Privacy Policy

Agent Vision is a local macOS camera plugin for Codex.

## Data Handling

Agent Vision captures images from the built-in Mac camera only when Codex calls one of its MCP tools or when the installed slash-command skill runs the local file materializer.

- Snapshot mode starts the camera, captures one JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera.
- Streaming mode starts a local camera session. Codex may request the latest JPEG frame while that session is active.
- Roast mode uses snapshot file materialization, then passes the saved JPEG to `codex exec -i` for the opt-in roast text.
- Stopping streaming releases the camera and clears the cached frame.

Agent Vision does not implement cloud upload, background recording, audio capture, device selection, telemetry, analytics, or remote logging.

## Permissions

macOS asks for camera permission for the signed `AgentVision.app` the first time the capture session starts.

The Mac camera indicator should be on while streaming mode is active. Snapshot mode should turn the camera on only long enough to capture one frame.

## Storage

Agent Vision keeps only the latest frame in process memory while a streaming session is active. Snapshot and roast mode intentionally write requested frames to `~/.codex/agent-vision/frames` so Codex can display or inspect the JPEG through a proven local image-input path. The plugin does not upload or remotely log those files.

## Contact

For privacy questions, open an issue at:

https://github.com/zfifteen/agent-vision/issues
