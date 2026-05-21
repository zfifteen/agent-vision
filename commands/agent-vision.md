---
description: Snapshot, roast, or estimate mood with the Agent Vision camera.
argument-hint: snapshot|streaming|roast|mood
---

# /agent-vision

Snapshot, roast, or estimate mood with the Agent Vision camera.

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before acting.

This slash command is camera control only. Do not inspect or roast the repository, source files, git state, README, or workspace unless the capture command fails and the exact failure requires local debugging.

For `snapshot`, `roast`, and `mood`, the first shell command must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

## Arguments

- `snapshot`: take one usable image and turn the camera off.
- `streaming`: report that streaming is temporarily disabled in Agent Vision 1.0.3.
- `roast`: take one usable image, turn the camera off, and write a playful roast.
- `mood`: take one usable image, turn the camera off, and estimate current interaction state for response delivery calibration only.

## Workflow

1. Read the first argument exactly.
2. For `snapshot`, create `$HOME/.codex/agent-vision/frames`, choose an absolute output path inside it, run `"$HOME/.codex/plugins/cache/local/agent-vision/1.0.3/dist/agent-vision-capture-file" --output "$OUTPUT" --json`, verify `ok: true`, then display the saved JPEG with a Markdown image link using the absolute path.
3. For `streaming`, do not call any tool and do not launch any Agent Vision process. Reply exactly: `Agent Vision streaming is temporarily disabled in 1.0.3 while the runtime is being moved to an explicit start/stop design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`
4. For `roast`, materialize a JPEG file with the same command, then run `codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" -- "Write exactly one playful roast of 400 characters or fewer based only on visible non-sensitive details in the attached image. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes."`, then display the saved JPEG and the roast text returned by that image-input pass. The final response must include a Markdown image link using the captured absolute JPEG path, followed by the roast text.
5. For `mood`, materialize a JPEG file with the same command, then run `codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" -- "Analyze the attached Agent Vision camera image for current interaction-state calibration only. Return strict JSON and no prose. Use exactly these keys: presence, interaction_state, confidence, observable_basis, assistant_adjustments. presence must be one of present, absent, uncertain. interaction_state must be one of focused_neutral, frustrated_or_blocked, tired_or_overloaded, curious_or_exploratory, skeptical_or_evaluating, high_stakes_or_cautious, absent, uncertain. confidence must be a number from 0 to 1. observable_basis and assistant_adjustments must be arrays of strings. Apply these gates: if the user is absent, occluded, multiple people are visible, image quality is unusable, or confidence is below 0.40, return interaction_state uncertain or absent and use no mood-conditioned behavior; if confidence is from 0.40 through 0.69, include only low-risk clarity adjustments; if confidence is 0.70 or higher, include state-specific response delivery adjustments. Do not infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories. Mood changes only pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior; it must not change facts, permissions, approval behavior, user intent, or task scope."`
6. After `mood`, parse the strict JSON. If parsing fails, report the exact image-analysis failure. If parsing succeeds, do not display the saved JPEG, do not display the JSON, and do not summarize the visual analysis. Apply the permitted response adjustments only to the current response or current task phase. User correction overrides the visual estimate.
7. If the first argument is missing or different, tell the user the supported arguments exactly.
8. Do not assume streaming mode is active in Agent Vision 1.0.3.
9. When the user asks to stop camera use or stop streaming, do not call any tool and do not launch any Agent Vision process. Reply exactly: `Agent Vision streaming is disabled in 1.0.3, so there is no Agent Vision streaming session to stop.`
10. If snapshot file mode fails, report the exact command error.

## Verification

Confirm that `agent-vision-capture-file` returned `ok: true` and that the returned `path` exists. If the command returns an error, report that exact error.

Snapshot, roast, and mood mode intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.

Agent Vision 1.0.3 has no streaming session and no eager MCP server. Installing, enabling, or idling in Codex must not start `agent-vision-mcp`, `AgentVision.app`, or any Agent Vision camera-capable helper process.

## Response

For `snapshot`, display the saved JPEG in chat with a Markdown image link. For `roast`, the final response must include the saved JPEG as a Markdown image link using the absolute captured path and must include the roast text returned by the separate `codex exec -i` image-input pass. Do not write a roast from Markdown, metadata, or memory in the current agent. For `mood`, do not display the saved JPEG, do not display the strict JSON, and do not explain the analysis or confidence band in the final answer. Use the strict JSON as ephemeral delivery calibration for the current response or current task phase only. Mood must not create mood history, a training dataset, background recording, separate image archive, or any new raw-image persistence beyond the saved JPEG frame path used by snapshot and roast. Keep roasts opt-in, light, and based only on visible non-sensitive details such as outfit, posture, expression, lighting, or room chaos. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes. Do not mention internal readiness metadata such as brightness values unless reporting an error. For mode changes, state the resulting camera mode.
