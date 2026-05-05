---
name: codex-vision
description: Use when the user asks Codex to start, inspect, or stop the local macOS camera through Codex Vision.
---

# Codex Vision

Use the Codex Vision MCP tools when the user explicitly asks for camera context.

## Workflow

1. Call `codex_vision_start`.
2. Call `codex_vision_frame` when a current view is needed.
3. Inspect the returned JPEG image content.
4. Call `codex_vision_stop` when the user asks to stop camera use or the visual task is complete.

## Guardrails

- Codex Vision is macOS-only.
- The plugin uses the built-in Mac camera only in version 1.0.
- If `codex_vision_frame` reports no frame yet, call it again after the session has had time to produce a frame.
- Do not claim a continuous unsolicited stream. Version 1.0 is pull-based live frame access.
