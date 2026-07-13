---
name: agent-vision
description: >
  Explicit local Mac camera control for Grok Build via Agent Vision.
  Use only when the user invokes /agent-vision with snapshot, streaming, roast, or mood arguments.
  Do not auto-start the camera. Snapshot, roast, and mood are one-shot; streaming is disabled.
disable-model-invocation: true
argument-hint: snapshot|streaming|roast|mood
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "Local Mac camera snapshot, roast, and mood for Grok Build"
---

# Agent Vision (Grok Build)

Use Agent Vision only when the user explicitly invokes `/agent-vision` for local Mac camera context.

## Scope

| Argument | Behavior |
| --- | --- |
| `snapshot` | One-shot capture → JPEG under `~/.agent-vision/frames` → `read_file` → Markdown image |
| `roast` | Same capture + `read_file`, then one playful roast (≤400 chars) from the image |
| `mood` | Same capture + `read_file`, then silent delivery calibration from the image (no image/JSON display) |
| `streaming` | Fixed disabled message; **launch no process** |
| stop / turn off camera | Fixed no-session message; **launch no process** |

Do not use codex exec. Do not call MCP tools for Agent Vision. Do not register or assume an Agent Vision MCP server.

On Grok, multimodal image access is `read_file` on the saved JPEG (not `codex exec -i`). Capture first, then `read_file`, then roast or mood analysis from the actual image pixels only.

## Execution discipline

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before acting.

This skill controls the local camera. Do not inspect or roast the repository, source files, git state, README, or workspace unless the capture command fails and the exact failure requires local debugging.

For `snapshot`, `roast`, and `mood`, the first shell command must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

## Runtime requirements

- Supported: Grok **sandbox off** (default). Restricted sandbox profiles are unsupported; if capture cannot write frames or launch the app, report that explicitly and stop.
- Runtime must be installed separately:

```bash
# from the agent-vision repo, once:
scripts/install-runtime.sh
```

- Helper resolution (pick **one** template; prefer shim on PATH):

```bash
agent-vision-capture-file --output "$OUTPUT" --json
```

or absolute default:

```bash
"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

If `AGENT_VISION_HOME` is set, use `"$AGENT_VISION_HOME/dist/agent-vision-capture-file"` instead of the default home path.

If the helper is missing, report that the Agent Vision runtime is not installed and that the user should run `scripts/install-runtime.sh`. Do not fall back to screenshots, existing photos, or browser capture.

## Capture (shared by snapshot, roast, mood)

1. Create the frame directory and choose a new absolute output path:

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

2. Verify the command printed JSON with `ok: true` and that `path` exists.
3. Use `read_file` on the absolute JPEG path so you can see the real image pixels.
4. Do not invent scene content from metadata, paths, or memory if capture or `read_file` fails.

Snapshot, roast, and mood intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.

If capture fails (`ok: false`, missing helper, permission denied, or timeout), report the exact error text and stop.

## Snapshot workflow

After capture + `read_file`:

1. Reply with a Markdown image link using the absolute path, plus any user-requested inspection of the scene.
2. Do not mention internal readiness metadata such as brightness values unless reporting an error.

## Roast workflow

After capture + `read_file`:

1. Write exactly one playful roast of **400 characters or fewer** based **only** on visible non-sensitive details in the image (outfit, posture, expression, lighting, room chaos).
2. Do **not** infer or attack protected traits, body size, age, disability, or other sensitive attributes.
3. Do **not** write a roast from Markdown, metadata, filename, or memory without a successful `read_file` of the JPEG.
4. Final response **must** include:
   - a Markdown image link using the absolute captured JPEG path
   - the roast text
5. Keep roasts opt-in, light, and funny — not a municipal cruelty department.

## Mood workflow

After capture + `read_file`:

1. Analyze the camera image for **current interaction-state calibration only**.
2. Form strict JSON (internally) with exactly these keys:
   - `presence`: one of `present`, `absent`, `uncertain`
   - `interaction_state`: one of `focused_neutral`, `frustrated_or_blocked`, `tired_or_overloaded`, `curious_or_exploratory`, `skeptical_or_evaluating`, `high_stakes_or_cautious`, `absent`, `uncertain`
   - `confidence`: number from 0 to 1
   - `observable_basis`: array of strings
   - `assistant_adjustments`: array of strings
3. Apply these gates:
   - If the user is absent, occluded, multiple people are visible, image quality is unusable, or confidence is below 0.40 → `interaction_state` `uncertain` or `absent` and **no** mood-conditioned behavior.
   - If confidence is from 0.40 through 0.69 → only low-risk clarity adjustments.
   - If confidence is 0.70 or higher → state-specific response delivery adjustments are allowed.
4. Do **not** infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories.
5. Mood changes only pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior. It must **not** change facts, permissions, approval behavior, user intent, or task scope.
6. **Do not display** the saved JPEG, the JSON, the confidence band, or a visual-analysis summary in the normal final answer.
7. Apply permitted adjustments only to the current response or current task phase. User correction overrides the visual estimate.
8. If `read_file` or analysis fails, report that exact failure instead of estimating mood from metadata or memory.
9. Mood must not create mood history, a training dataset, background recording, a separate image archive, or any new raw-image persistence beyond the saved JPEG frame path.

Debug exception: if the user **explicitly** asks to debug mood mode, you may show the image path and the strict JSON.

## Streaming (disabled)

For `/agent-vision streaming` or any request to start streaming:

1. Do not call a tool.
2. Do not launch `AgentVision.app`, `agent-vision-mcp`, or `agent-vision-capture-file`.
3. Reply exactly: `Agent Vision streaming is temporarily disabled while the runtime uses an explicit one-shot capture design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`

For stop-streaming requests (“streaming off”, “stop streaming”, “turn off the camera”) when no capture is in progress:

1. Do not call a tool.
2. Do not launch any Agent Vision process.
3. Reply exactly: `Agent Vision streaming is disabled, so there is no Agent Vision streaming session to stop.`

## Privacy and lifecycle

- Install, plugin enablement, idle Grok startup, unrelated prompts, streaming, and stop-streaming must not start any Agent Vision camera-capable process.
- Capture runs only for explicit `/agent-vision snapshot`, `/agent-vision roast`, or `/agent-vision mood`.
- Frames stay local under `~/.agent-vision/frames`. No cloud upload.
- Camera permission belongs to signed `AgentVision.app`.

## Slash command summary

- `/agent-vision snapshot` — one usable JPEG, camera off, show image via Markdown after `read_file`.
- `/agent-vision roast` — capture + `read_file` + playful roast; show image + roast text.
- `/agent-vision mood` — capture + `read_file` + silent delivery calibration; no image/JSON display.
- `/agent-vision streaming` — disabled message; no process.
- stop streaming / turn off camera — no-session message; no process.

If the first argument is missing or unsupported, tell the user the supported arguments exactly: `snapshot`, `streaming`, `roast`, `mood`.
