# /codex-vision

Control Codex Vision camera mode.

## Arguments

- `snapshot`: take one image and turn the camera off.
- `streaming`: start streaming mode.

## Workflow

1. Read the first argument exactly.
2. For `snapshot`, call `codex_vision_snapshot`.
3. For `streaming`, call `codex_vision_start`.
4. If the first argument is missing or different, tell the user the supported arguments exactly.
5. While streaming mode is active, call `codex_vision_frame` whenever current visual context would help.
6. When the user asks to stop camera use, call `codex_vision_stop`.

## Verification

Confirm that the called tool returned `isError: false`. If the tool returns an error, report that exact error.

## Response

For image-producing calls, display or describe the returned image in chat. For mode changes, state the resulting camera mode.
