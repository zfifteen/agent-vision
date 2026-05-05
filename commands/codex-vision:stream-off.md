# /codex-vision:stream-off

Stop the persistent Codex Vision camera session.

## Preflight

Use this command when the user asks to stop camera use or when the visual task is complete.

## Plan

Call one MCP tool:

1. `codex_vision_stop`

This stops the camera and clears the cached frame.

## Commands

Call `codex_vision_stop`.

## Verification

Confirm that the tool returned `isError: false`. If the tool returns an error, report that exact error.

## Response

Tell the user that streaming mode is off and the camera has been released.
