# /codex-vision:frame

Get one current frame from streaming mode.

## Preflight

Use this command when streaming mode is already active. If the camera is not running, report the tool error and suggest `/codex-vision:stream-on` or `/codex-vision:snapshot`.

## Plan

Call one MCP tool:

1. `codex_vision_frame`

This returns the latest JPEG frame from the active camera session.

## Commands

Call `codex_vision_frame`.

## Verification

Confirm that the tool returned image content and metadata. If the tool returns an error, report that exact error.

## Response

Display or describe the returned image in the chat response.
