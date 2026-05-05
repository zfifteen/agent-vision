# /codex-vision

Control Codex Vision camera mode.

## Arguments

- `snapshot`: take one image and turn the camera off.
- `stream-on`: start streaming mode.
- `frame`: pull one frame from active streaming mode.
- `stream-off`: stop streaming mode and release the camera.

## Workflow

1. Read the first argument exactly.
2. For `snapshot`, call `codex_vision_snapshot`.
3. For `stream-on`, call `codex_vision_start`.
4. For `frame`, call `codex_vision_frame`.
5. For `stream-off`, call `codex_vision_stop`.
6. If the first argument is missing or different, tell the user the supported arguments exactly.

## Verification

Confirm that the called tool returned `isError: false`. If the tool returns an error, report that exact error.

## Response

For image-producing calls, display or describe the returned image in chat. For mode changes, state the resulting camera mode.
