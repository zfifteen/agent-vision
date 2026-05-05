# /codex-vision:snapshot

Take one current camera snapshot for the user.

## Preflight

Use Codex Vision only when the user intentionally invokes this command or otherwise asks for camera context.

## Plan

Call one MCP tool:

1. `codex_vision_snapshot`

This starts the camera, captures one JPEG frame, returns the image to Codex, and stops the camera.

## Commands

Call `codex_vision_snapshot`.

## Verification

Confirm that the tool returned image content and metadata. If the tool returns an error, report that exact error.

## Response

Display or describe the returned image in the chat response. Mention that snapshot mode turned the camera off after capture.
