---
description: Snapshot, stream, or roast with the Agent Vision camera.
argument-hint: snapshot|streaming|roast
---

# /agent-vision

Snapshot, stream, or roast with the Agent Vision camera.

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before acting.

This slash command is camera control only. Do not inspect or roast the repository, source files, git state, README, or workspace unless the capture command fails and the exact failure requires local debugging.

For `snapshot` and `roast`, the first shell command must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

## Arguments

- `snapshot`: take one usable image and turn the camera off.
- `streaming`: start streaming mode.
- `roast`: take one usable image, turn the camera off, and write a playful roast.

## Workflow

1. Read the first argument exactly.
2. For `snapshot`, create `$HOME/.codex/agent-vision/frames`, choose an absolute output path inside it, run `"$HOME/.codex/plugins/cache/local/agent-vision/1.0.1/dist/agent-vision-capture-file" --output "$OUTPUT" --json`, verify `ok: true`, then display the saved JPEG with a Markdown image link using the absolute path.
3. For `streaming`, call `agent_vision_start`.
4. For `roast`, materialize a JPEG file with the same command, then run `codex exec --ephemeral -i "$OUTPUT" -- "Write exactly one playful roast of 400 characters or fewer based only on visible non-sensitive details in the attached image. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes."`
5. If the first argument is missing or different, tell the user the supported arguments exactly.
6. While streaming mode is active, use snapshot file mode whenever current visual context would help.
7. When the user asks to stop camera use, call `agent_vision_stop`.
8. If snapshot file mode fails, report the exact command error.

## Verification

Confirm that `agent-vision-capture-file` returned `ok: true` and that the returned `path` exists. If the command returns an error, report that exact error.

Snapshot and roast mode intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.

If streaming mode is already active, snapshot and roast mode must not stop the streaming session.

## Response

For `snapshot`, display the saved JPEG in chat with a Markdown image link. For `roast`, display the saved JPEG and include the roast text returned by the separate `codex exec -i` image-input pass. Do not write a roast from Markdown, metadata, or memory in the current agent. Keep roasts opt-in, light, and based only on visible non-sensitive details such as outfit, posture, expression, lighting, or room chaos. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes. Do not mention internal readiness metadata such as brightness values unless reporting an error. For mode changes, state the resulting camera mode.
