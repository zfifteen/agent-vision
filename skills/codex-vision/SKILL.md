---
name: codex-vision
description: Use when the user asks Codex to snapshot, stream, inspect, or stop the local macOS camera through Codex Vision.
---

# Codex Vision

Use the Codex Vision MCP tools when the user explicitly asks for camera context.

## Workflow

For one-shot camera context, call `codex_vision_snapshot`. This starts the camera, captures one JPEG frame, and stops the camera.

For streaming mode:

1. Call `codex_vision_start`.
2. Call `codex_vision_frame` whenever current visual context would help.
3. Inspect the returned JPEG image content.
4. Call `codex_vision_stop` when the user asks to stop camera use or the visual task is complete.

## Slash Commands

- `/codex-vision:snapshot`: call `codex_vision_snapshot`.
- `/codex-vision:stream-on`: call `codex_vision_start`.
- `/codex-vision:frame`: call `codex_vision_frame`.
- `/codex-vision:stream-off`: call `codex_vision_stop`.

## Guardrails

- Codex Vision is macOS-only.
- The plugin uses the built-in Mac camera only in version 1.0.
- If `codex_vision_frame` reports no frame yet during streaming mode, call it again after the session has had time to produce a frame.
- Streaming mode is pull-based live frame access. When streaming mode is on, Codex may pull frames as needed without asking the user for each individual frame.
- Snapshot mode captures one frame and turns the camera off.
