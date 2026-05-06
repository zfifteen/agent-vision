# Agent Vision Native Camera Redesign Specification

Status: Draft for implementation
Date: 2026-05-06

## 1. Problem

Agent Vision v1 assumed this runtime path:

```text
Codex slash command -> MCP tool -> MCP image content -> Codex model vision
```

That assumption is false in the tested Codex path. The MCP result contains base64 JPEG image content, but Codex CLI 0.125.0 does not expose that MCP image content to the model as inspectable vision input. The JSON event stream carries the image bytes; the agent still reports metadata-only visibility.

The revised plugin must use a contract that Codex actually consumes:

```text
Codex slash command -> native Agent Vision command -> JPEG file on disk -> Codex local image input or Markdown image display
```

## 2. Design Decision

Agent Vision v2 removes MCP from the primary runtime contract.

The plugin remains a Codex packaging and instruction layer. Camera control moves to a purpose-built native macOS app plus a native CLI helper. The native app owns camera permission. The CLI helper launches or talks to the app, receives deterministic JSON, and returns absolute file paths for captured JPEGs.

MCP must not be used to deliver model-visible images in v2.

## 3. Product Invariants

- Agent Vision captures images with a signed native macOS app.
- Agent Vision writes captured frames to explicit absolute JPEG paths.
- Codex displays captured frames through Markdown image links.
- Codex interprets captured frames only through a proven local image input path, currently `codex exec -i <image>`.
- The plugin does not claim the model inspected an image unless the image was passed through that proven image input path.
- Failures are explicit JSON errors. No screenshots, MCP image bytes, temporary decoded artifacts, or alternate camera paths are used as substitutes.
- All public commands use deterministic output locations supplied by the caller or command instructions.

## 4. Non-Goals

- No MCP server in the v2 production runtime.
- No browser camera access.
- No cloud camera service.
- No alternate camera selection in v2.
- No silent fallback from native capture to screenshots or existing image files.
- No retry with a different capture mechanism after a native capture error.
- No model interpretation from metadata alone.

## 5. Installed Components

The revised plugin installs these components:

```text
~/.codex/plugins/cache/local/agent-vision/2.0.0/
  .codex-plugin/plugin.json
  commands/agent-vision.md
  skills/camera-control/SKILL.md
  dist/AgentVision.app
  dist/agent-vision

~/.local/bin/agent-vision -> ~/.codex/plugins/cache/local/agent-vision/2.0.0/dist/agent-vision
```

`AgentVision.app` is the signed macOS camera owner. It contains the AVFoundation camera implementation and is launched with Launch Services so macOS camera permission attaches to the app identity.

`dist/agent-vision` is the native CLI helper. It does not capture camera frames directly. It launches or contacts `AgentVision.app`, waits for explicit completion, reads result files, and prints JSON to stdout.

## 6. Native CLI Contract

The public executable is:

```bash
$HOME/.local/bin/agent-vision
```

All commands write one JSON object to stdout and exit nonzero on command-level failure.

### 6.1 Capture

```bash
agent-vision capture --output /absolute/path/frame.jpg --json
```

Behavior:

1. Launch `AgentVision.app` in one-shot capture mode.
2. Start the built-in camera.
3. Wait for one usable JPEG frame.
4. Write the JPEG exactly to `--output`.
5. Stop the camera.
6. Write result JSON to stdout.
7. Exit.

Success JSON:

```json
{
  "ok": true,
  "mode": "capture",
  "path": "/absolute/path/frame.jpg",
  "mimeType": "image/jpeg",
  "width": 1920,
  "height": 1080,
  "bytes": 289570,
  "timestamp": "2026-05-06T15:00:00Z"
}
```

### 6.2 Start Streaming

```bash
agent-vision start --json
```

Behavior:

1. Launch `AgentVision.app` in persistent streaming mode.
2. Start the built-in camera.
3. Create a Unix domain socket in the Agent Vision state directory.
4. Write state metadata to disk.
5. Return after the app confirms the camera session is running.

Success JSON:

```json
{
  "ok": true,
  "mode": "streaming",
  "state": "running",
  "socket": "/Users/velocityworks/.codex/agent-vision/agent-vision.sock",
  "timestamp": "2026-05-06T15:00:00Z"
}
```

### 6.3 Latest Streaming Frame

```bash
agent-vision frame --output /absolute/path/frame.jpg --json
```

Behavior:

1. Connect to the active Agent Vision streaming socket.
2. Request the latest usable frame.
3. Write the JPEG exactly to `--output`.
4. Leave streaming mode active.
5. Write result JSON to stdout.

If streaming is not active, this command fails with `stream_not_running`. It must not start streaming implicitly.

### 6.4 Stop Streaming

```bash
agent-vision stop --json
```

Behavior:

1. Connect to the active Agent Vision streaming socket.
2. Ask the app to stop the camera.
3. Clear state metadata.
4. Exit after the app confirms the camera is stopped.

If streaming is not active, this command succeeds with `state: "stopped"` and `changed: false`.

### 6.5 Status

```bash
agent-vision status --json
```

Behavior:

1. Inspect the Agent Vision state file.
2. If a socket is recorded, verify the socket responds.
3. Print current state.

Success JSON:

```json
{
  "ok": true,
  "state": "running",
  "pid": 12345,
  "socket": "/Users/velocityworks/.codex/agent-vision/agent-vision.sock"
}
```

## 7. State And Output Paths

State directory:

```text
$HOME/.codex/agent-vision/
```

Frame directory:

```text
$HOME/.codex/agent-vision/frames/
```

Slash commands create frame paths before invoking the CLI:

```text
$HOME/.codex/agent-vision/frames/YYYYMMDDTHHMMSSZ-snapshot.jpg
$HOME/.codex/agent-vision/frames/YYYYMMDDTHHMMSSZ-roast.jpg
$HOME/.codex/agent-vision/frames/YYYYMMDDTHHMMSSZ-frame.jpg
```

If the requested output file already exists, the CLI fails with `output_exists`. It must not overwrite the file and must not choose a replacement filename.

## 8. Native App Contract

`AgentVision.app` supports two private launch modes used only by `dist/agent-vision`:

```text
capture-once --output PATH --result PATH
serve --state-dir PATH
```

The app writes result JSON to the `--result` file for one-shot capture. The CLI reads that file and prints it to stdout.

Streaming mode uses a Unix domain socket with newline-delimited JSON commands:

```json
{"command":"frame","output":"/absolute/path/frame.jpg"}
{"command":"stop"}
{"command":"status"}
```

This protocol is Agent Vision internal protocol, not MCP.

## 9. Slash Command Contract

The plugin exposes one slash command:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
```

### 9.1 Snapshot

Command behavior:

1. Compute an absolute output path under `$HOME/.codex/agent-vision/frames/`.
2. Run `agent-vision status --json`.
3. If streaming is running, run `agent-vision frame --output PATH --json`.
4. If streaming is stopped, run `agent-vision capture --output PATH --json`.
5. Verify `ok: true`, `mimeType: "image/jpeg"`, and that `path` exists.
6. Respond with a Markdown image link:

```markdown
![Agent Vision snapshot](/absolute/path/frame.jpg)
```

The response may include concise metadata. It must not say the model inspected the image unless the command also passed the file through a proven image input path.

### 9.2 Streaming

Command behavior:

1. Run `agent-vision start --json`.
2. Verify `ok: true`.
3. Report that streaming is running.

While streaming is running, future frame requests use:

```bash
agent-vision frame --output PATH --json
```

### 9.3 Roast

Command behavior:

1. Compute an absolute output path under `$HOME/.codex/agent-vision/frames/`.
2. Capture a JPEG using the same state-aware rule as snapshot.
3. Verify the JPEG exists.
4. Invoke the proven local image input path:

```bash
codex exec --ephemeral -i /absolute/path/frame.jpg -- "Write one playful roast of 400 characters or fewer based only on visible non-sensitive details. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes."
```

5. Return the Markdown image link and the nested Codex roast text.

If `codex exec -i` fails or does not confirm image visibility, roast fails explicitly with `image_input_failed`. It must not roast from metadata.

## 10. Error Contract

All CLI failures print JSON to stderr or stdout and exit nonzero:

```json
{
  "ok": false,
  "error": {
    "code": "camera_permission_denied",
    "message": "Camera permission was denied for AgentVision.app."
  }
}
```

Required error codes:

```text
app_launch_failed
camera_unavailable
camera_permission_denied
capture_input_failed
frame_unavailable
frame_not_usable
jpeg_encoding_failed
output_exists
output_write_failed
state_corrupt
stream_not_running
stream_socket_unreachable
image_input_failed
```

## 11. Privacy And Security

- Camera frames are captured only after an explicit slash command or CLI command.
- Frames are written only to the requested absolute output path.
- The CLI refuses relative output paths.
- The CLI refuses paths outside `$HOME/.codex/agent-vision/frames/`.
- No frame is uploaded by Agent Vision.
- Roast mode invokes Codex image input on a local file. That model invocation is outside the camera binary and must be documented as Codex image processing.
- State files contain only PID, socket path, timestamps, and camera session state.

## 12. Installer Changes

The installer must:

1. Build `AgentVision.app`.
2. Build `dist/agent-vision`.
3. Sign `AgentVision.app`.
4. Stage plugin files.
5. Install or update `$HOME/.local/bin/agent-vision`.
6. Remove `.mcp.json` from the plugin package.
7. Remove `mcpServers` from `.codex-plugin/plugin.json`.
8. Remove legacy `mcp_servers.agent_vision` from `$HOME/.codex/config.toml`.
9. Validate `agent-vision capture --output PATH --json` writes a JPEG.
10. Validate `codex exec -i PATH` can inspect a known local image.

## 13. Test Matrix

### Unit Tests

- CLI rejects relative output paths.
- CLI rejects existing output files.
- CLI emits success JSON for capture.
- CLI emits required error codes.
- State parser rejects corrupt state.
- Streaming frame fails with `stream_not_running` when no socket is active.

### Integration Tests

- `agent-vision capture --output PATH --json` writes a nonempty JPEG.
- `agent-vision start --json` starts camera and writes state.
- `agent-vision frame --output PATH --json` writes a nonempty JPEG while streaming.
- `agent-vision stop --json` clears state.
- No `AgentVision.app` process remains after one-shot capture.
- Streaming process remains only after `start`.
- Streaming process exits after `stop`.

### Slash Command Tests

Use real `codex exec --json --ephemeral` prompts:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
```

Assertions:

- Snapshot calls the native CLI, not MCP.
- Snapshot final response contains a Markdown image link to an existing JPEG.
- Streaming calls `agent-vision start`.
- Roast calls the native CLI, then calls `codex exec -i` with the captured JPEG.
- Roast final response contains an image link and roast text.
- No command reports metadata-only image visibility as success.
- No command uses MCP tools.

## 14. Migration Plan

1. Add `dist/agent-vision` native CLI target.
2. Add private `capture-once` and `serve` modes to `AgentVision.app`.
3. Replace MCP server tests with CLI/app protocol tests.
4. Remove `.mcp.json`.
5. Remove `mcpServers` from plugin manifest.
6. Rewrite slash command instructions to call `$HOME/.local/bin/agent-vision`.
7. Rewrite skill instructions to forbid MCP image inspection.
8. Replace `scripts/test-slash-commands.sh` assertions with native CLI assertions.
9. Update README, INSTALL, CODEX_INSTALL, PRIVACY, and traceability docs.
10. Run the full slash matrix before marking production working.

## 15. Acceptance Criteria

Agent Vision v2 is production-ready only when all of these are true:

- `swift test` passes.
- Installer dry-run passes.
- Installer completes on a clean local Codex profile.
- `~/.codex/config.toml` contains no Agent Vision MCP server section.
- The installed plugin manifest contains no `mcpServers` entry.
- `agent-vision capture --output PATH --json` writes a JPEG at `PATH`.
- `/agent-vision snapshot` displays the captured JPEG in chat.
- `/agent-vision streaming` starts a persistent native camera session.
- `/agent-vision roast` uses `codex exec -i PATH` or another proven local image input path and produces a roast grounded in the image.
- Slash-command test output reports all three slash commands as passing.
- No production status is reported as working while any slash command matrix case fails.
