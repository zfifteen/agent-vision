---
name: camera-control
description: Use when the user asks Codex to snapshot, stream, inspect, or stop the local macOS camera through Codex Vision.
---

# Codex Vision

Use the Codex Vision MCP tools when the user explicitly asks for camera context.

## Workflow

For one-shot camera context, call `codex_vision_snapshot`. This starts the camera, captures one JPEG frame, and stops the camera.

For roast mode, call `codex_vision_snapshot`, inspect the returned image, and write one playful roast of 400 characters or fewer. Keep roasts opt-in, light, and based only on visible non-sensitive details such as outfit, posture, expression, lighting, or room chaos. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes.

For streaming mode:

1. Call `codex_vision_start`.
2. Call `codex_vision_frame` whenever current visual context would help.
3. Inspect the returned JPEG image content.
4. Call `codex_vision_stop` when the user asks to stop camera use or the visual task is complete.

## Slash Commands

- `/codex-vision snapshot`: call `codex_vision_snapshot`.
- `/codex-vision streaming`: call `codex_vision_start`.
- `/codex-vision roast`: call `codex_vision_snapshot`, then write one playful roast of 400 characters or fewer.

While streaming mode is active, call `codex_vision_frame` whenever current visual context would help. When the user asks to stop camera use, call `codex_vision_stop`.

Treat requests such as "streaming off", "stop streaming", or "turn off the camera" as requests to call `codex_vision_stop`.

## Guardrails

- Codex Vision is macOS-only.
- The plugin uses the built-in Mac camera only in version 1.0.
- If `codex_vision_frame` reports no frame yet during streaming mode, wait briefly and retry at most two times. If frame errors persist, tell the user the camera is not producing frames and suggest stopping and restarting streaming mode.
- Streaming mode is pull-based live frame access. When streaming mode is on, Codex may pull frames as needed without asking the user for each individual frame.
- Snapshot mode captures one frame and turns the camera off.
