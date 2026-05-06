---
name: camera-control
description: Use when the user invokes /agent-vision, /agent-vision snapshot, /agent-vision streaming, /agent-vision roast, or asks Codex to snapshot, stream, inspect, roast, or stop the local macOS camera through Agent Vision.
---

# Agent Vision

Use the Agent Vision MCP tools when the user explicitly asks for camera context.

## Workflow

For one-shot camera context, call `agent_vision_snapshot`. This starts the camera, waits for a usable JPEG frame, and stops the camera.

For roast mode, call `agent_vision_snapshot`, inspect the returned image, and write one playful roast of 400 characters or fewer. Keep roasts opt-in, light, and based only on visible non-sensitive details such as outfit, posture, expression, lighting, or room chaos. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes.

If `agent_vision_snapshot` or `agent_vision_frame` returns metadata but no image content that Codex can directly inspect, stop and report the tool contract failure. Do not use the local MCP wrapper, a temp file, a screenshot, another camera path, or any decoded artifact as a substitute for the normal tool result.

For streaming mode:

1. Call `agent_vision_start`.
2. Call `agent_vision_frame` whenever current visual context would help.
3. Inspect the returned JPEG image content.
4. Call `agent_vision_stop` when the user asks to stop camera use or the visual task is complete.

## Slash Commands

- `/agent-vision snapshot`: call `agent_vision_snapshot`.
- `/agent-vision streaming`: call `agent_vision_start`.
- `/agent-vision roast`: call `agent_vision_snapshot`, then write one playful roast of 400 characters or fewer.

While streaming mode is active, call `agent_vision_frame` whenever current visual context would help. When the user asks to stop camera use, call `agent_vision_stop`.

Treat requests such as "streaming off", "stop streaming", or "turn off the camera" as requests to call `agent_vision_stop`.

## Guardrails

- Agent Vision is macOS-only.
- The plugin uses the built-in Mac camera only in version 1.0.
- Snapshot and roast mode intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.
- If streaming mode is already active, snapshot and roast mode must not stop the streaming session.
- If `agent_vision_frame` reports no frame yet during streaming mode, wait briefly and retry at most two times. If frame errors persist, tell the user the camera is not producing frames and suggest stopping and restarting streaming mode.
- Streaming mode is pull-based live frame access. When streaming mode is on, Codex may pull frames as needed without asking the user for each individual frame.
- Snapshot mode captures one usable frame and turns the camera off.
- Do not mention internal readiness metadata such as brightness values unless reporting an error.
