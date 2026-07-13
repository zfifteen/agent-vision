---
description: Sticky mood-first Agent Vision camera — arm, capture, reason; off to disarm.
argument-hint: mood|snapshot|roast|off|streaming
---

# /agent-vision

Sticky local Mac camera vision for Codex. **Primary purpose:** ascertain mood/disposition from camera image(s), understand what is in the image, and incorporate that into reasoning before responding or completing tasks.

## Session sticky model

- **New chat starts OFF.** Leftover state files alone do not arm.
- Bare `/agent-vision` or `mood`: **ARM** + mood vision loop.
- `snapshot` / `roast`: **ARM** + that mode.
- While **ARMED** in this conversation: each **substantive** user turn → capture → understand image → reason with it → respond.
- `off` / stop / disable / “turn off the camera” / “agent vision off”: **DISARM**; no capture.
- `streaming`: disabled message; **do not arm**.

Optional state helper (never starts camera):

```bash
scripts/agent-vision-sticky.sh on --host codex --mode mood
scripts/agent-vision-sticky.sh off --host codex
```

## Execution discipline

Agent Vision is not a repository task. Do not inspect git, README, or the workspace before capture.

For capture turns, the **first shell command** must create `$HOME/.codex/agent-vision/frames` and run:

```bash
"$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

## Arguments

- *(none)* or `mood`: arm + mood (primary).
- `snapshot`: arm + one JPEG + Markdown image link; use scene understanding.
- `roast`: arm + JPEG + `codex exec -i` roast ≤400 chars + image link.
- `off`: disarm sticky; no process.
- `streaming`: fixed disabled text; no process; do not arm.

## Workflow

1. Read the first argument (default **mood** if missing).
2. If `off` or disarm phrase: sticky off, disarm conversation, no capture, confirm off.
3. If `streaming`: no process; reply exactly: `Agent Vision streaming is temporarily disabled in 1.5.0 while the runtime is being moved to an explicit start/stop design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`
4. For `mood` / bare: capture, then `codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" --` with the standard mood JSON prompt (keys: presence, interaction_state, confidence, observable_basis, assistant_adjustments; same gates and safety rules as the camera-control skill). Do not display JPEG/JSON; incorporate into reasoning; then answer/task. Arm sticky.
5. For `snapshot`: capture, display Markdown image link with absolute path, use scene understanding, arm sticky.
6. For `roast`: capture, `codex exec -i` roast prompt, display image link + roast text, arm sticky.
7. While already armed and the user sends a substantive message **without** a new slash: still run the mood vision loop (capture → understand → reason → respond) unless they asked for snapshot/roast specifically.
8. If capture fails, report the exact error.

## Verification

Confirm `agent-vision-capture-file` returned `ok: true` and `path` exists. Usable-frame retries stay inside the helper (up to 3 attempts).

## Privacy

Install, enable, idle, and **disarmed** states must not start `agent-vision-mcp`, `AgentVision.app`, or capture. Sticky means one-shot captures on substantive turns while armed — not an always-on camera process. No production MCP server.
