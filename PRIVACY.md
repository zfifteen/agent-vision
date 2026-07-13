# Privacy Policy

Agent Vision is a local macOS camera appliance for coding agents. Package **1.5.0**+ supports **Codex** and **Grok Build** with mood-first **sticky** sessions (arm with `/agent-vision`, disarm with `/agent-vision off`). Streaming is disabled on both hosts.

## Data Handling

Agent Vision captures images from the built-in Mac camera only when an installed slash-command skill runs the local file materializer for an explicit one-shot request.

- **Codex** snapshot mode starts the camera, captures one JPEG frame, saves it under `~/.codex/agent-vision/frames`, displays it with an absolute Markdown image link, and stops the camera.
- **Grok Build** snapshot mode saves under `~/.agent-vision/frames` and uses local multimodal `read_file` after capture.
- **Roast** (both hosts) uses snapshot file materialization, then analyzes the saved JPEG for an opt-in playful roast (Codex: `codex exec -i`; Grok: `read_file`).
- **Mood** (both hosts, default on arm) uses snapshot file materialization, then analyzes the saved JPEG for disposition and delivery calibration (Codex: `codex exec -i`; Grok: `read_file`). Mood does not display the image or JSON by default.
- **Sticky session:** after arm, each substantive turn may capture again until the user turns Agent Vision off. Each look is still a one-shot process (camera on briefly, then off)—not an always-on daemon.
- **New chat starts off.** Install and idle startup never open the camera.
- Streaming mode is temporarily disabled and launches no Agent Vision process on either host.

Agent Vision does not implement cloud upload, background recording, audio capture, device selection, telemetry, analytics, remote logging, an installed MCP server, or an idle camera-capable background process.

## Permissions

macOS asks for camera permission for the signed `AgentVision.app` the first time an explicit one-shot capture starts.

Install, plugin enablement, idle Codex or Grok startup, unrelated prompts, streaming requests, and stop-streaming requests must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

## Storage

Codex snapshot, roast, and mood intentionally write requested frames to `~/.codex/agent-vision/frames`. Grok snapshot, roast, and mood write to `~/.agent-vision/frames`. Hosts use those local paths so the assistant can display or inspect the JPEG through a proven local image-input path. The plugin does not upload or remotely log those files.

## Contact

For privacy questions, open an issue at:

https://github.com/zfifteen/agent-vision/issues
