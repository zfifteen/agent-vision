# /codex-vision

Control Codex Vision camera mode.

## Arguments

- `snapshot`: take one usable image and turn the camera off.
- `streaming`: start streaming mode.
- `roast`: take one usable image, turn the camera off, and write a playful roast.

## Workflow

1. Read the first argument exactly.
2. For `snapshot`, call `codex_vision_snapshot`.
3. For `streaming`, call `codex_vision_start`.
4. For `roast`, call `codex_vision_snapshot`, inspect the returned image, and write one roast of 400 characters or fewer.
5. If the first argument is missing or different, tell the user the supported arguments exactly.
6. While streaming mode is active, call `codex_vision_frame` whenever current visual context would help.
7. When the user asks to stop camera use, call `codex_vision_stop`.
8. If streaming frame pulls keep returning errors after two brief retries, tell the user the camera is not producing frames and suggest stopping and restarting streaming mode.

## Verification

Confirm that the called tool returned `isError: false`. If the tool returns an error, report that exact error.

Snapshot and roast mode intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds, and tries again up to 3 total attempts before returning an error.

If streaming mode is already active, snapshot and roast mode must not stop the streaming session.

## Response

For `snapshot`, display or describe the returned image in chat. For `roast`, display or describe the returned image and include one playful roast of 400 characters or fewer. Keep roasts opt-in, light, and based only on visible non-sensitive details such as outfit, posture, expression, lighting, or room chaos. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes. Do not mention internal readiness metadata such as brightness values unless reporting an error. For mode changes, state the resulting camera mode.

If you need to save an MCP image to disk before displaying it in chat, use a fresh unique filename for each response. Do not reuse a temp image path from an earlier snapshot.
