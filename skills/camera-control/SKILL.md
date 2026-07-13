---
name: camera-control
description: >
  Sticky local Mac camera vision for Codex via Agent Vision. Primary purpose:
  ascertain mood/disposition from camera image(s), understand what is in the
  image, and incorporate that into reasoning before responding or completing
  tasks. Arm with /agent-vision (default mood). Stay armed until /agent-vision off.
  Also snapshot and roast. Streaming disabled.
---

# Agent Vision (Codex)

## Purpose (read this first)

**Main product value: mood/disposition + vision-in-the-loop reasoning.**

When armed, for each **substantive** user turn:

1. Capture one or more usable JPEGs via `agent-vision-capture-file` (usually one).
2. Understand **what is in the image** (Codex: `codex exec -i` on the file for mood/roast; display path for snapshot).
3. **Incorporate that understanding into reasoning** before the answer or task work.
4. Mood shapes delivery fit only — not facts, permissions, approval, intent, or task scope.

## Session sticky model (mandatory)

```text
NEW conversation / chat  →  OFF  (always; leftover state file alone is NOT enough)

/agent-vision            →  ARM + mood vision loop
/agent-vision mood       →  ARM + mood vision loop
/agent-vision snapshot   →  ARM + snapshot
/agent-vision roast      →  ARM + roast

While ARMED in THIS conversation:
  each substantive user turn → capture → understand image → reason with it → respond

/agent-vision off
  or: stop | disable | "turn off the camera" | "agent vision off"
  →  DISARM
```

### Hard gates

**Never capture** unless:

1. This message explicitly invokes `/agent-vision` (or a mode), or  
2. Sticky is armed **in this conversation** (prior slash arm in this chat) and the turn is substantive.

**New chat starts OFF.** Do not trust a leftover state file alone.

After arming, optionally:

```bash
# if available from a clone:
scripts/agent-vision-sticky.sh on --host codex --mode mood
scripts/agent-vision-sticky.sh off --host codex
```

## Execution discipline

Camera requests are not repository tasks. Do not inspect the repo before capture.

For capture turns, the **first shell command** must be:

```bash
mkdir -p "$HOME/.codex/agent-vision/frames" && OUTPUT="$HOME/.codex/agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or workspace inspection before that command.

## Capture

Materialize one JPEG with the command above. Verify `ok: true` and path exists. Each look is one-shot process lifecycle (camera brief on, then off). Sticky is **not** an always-on camera daemon.

## Mood (primary; bare `/agent-vision`)

1. Capture as above.
2. Run:

```bash
codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" -- "Analyze the attached Agent Vision camera image for current interaction-state calibration only. Return strict JSON and no prose. Use exactly these keys: presence, interaction_state, confidence, observable_basis, assistant_adjustments. presence must be one of present, absent, uncertain. interaction_state must be one of focused_neutral, frustrated_or_blocked, tired_or_overloaded, curious_or_exploratory, skeptical_or_evaluating, high_stakes_or_cautious, absent, uncertain. confidence must be a number from 0 to 1. observable_basis and assistant_adjustments must be arrays of strings. Apply these gates: if the user is absent, occluded, multiple people are visible, image quality is unusable, or confidence is below 0.40, return interaction_state uncertain or absent and use no mood-conditioned behavior; if confidence is from 0.40 through 0.69, include only low-risk clarity adjustments; if confidence is 0.70 or higher, include state-specific response delivery adjustments. Do not infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories. Mood changes only pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior; it must not change facts, permissions, approval behavior, user intent, or task scope."
```

3. Parse JSON. On success: **do not display** image or JSON; incorporate into reasoning; then answer/task.
4. On failure: report the exact failure; do not invent mood from metadata.
5. User correction overrides until the next capture.

## Snapshot

Capture, then display Markdown image link with the absolute path. Use scene understanding in the reply when relevant.

## Roast

Capture, then:

```bash
codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" -- "Write exactly one playful roast of 400 characters or fewer based only on visible non-sensitive details in the attached image. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes."
```

Final response: Markdown image link + roast text. Do not roast from metadata/memory without a successful image pass.

## Disarm (`off`)

On `/agent-vision off`, `stop`, `disable`, “turn off the camera”, “agent vision off”:

1. Sticky off (script if available).
2. Disarm this conversation.
3. No capture.
4. Brief confirmation that Agent Vision is off until the next `/agent-vision` invoke.

## Streaming (disabled)

`/agent-vision streaming` only — do **not** arm; no process; reply exactly:

`Agent Vision streaming is temporarily disabled in 1.5.0 while the runtime is being moved to an explicit start/stop design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`

## Guardrails

- macOS only; built-in camera; version 1.5.0 package path.
- Install / idle / plugin load / disarmed: no `agent-vision-mcp`, no `AgentVision.app`, no capture helper.
- No production MCP server.
- No mood history dataset; frames only under the normal frame path.
- Do not mention internal readiness metadata unless reporting an error.

## Slash summary

- `/agent-vision` | `mood` — arm + mood loop (primary).
- `snapshot` | `roast` — arm + mode.
- `off` — disarm.
- `streaming` — disabled; do not arm.
