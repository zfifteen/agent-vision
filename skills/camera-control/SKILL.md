---
name: camera-control
description: >
  CRITICAL WHILE ARMED: capture is not enough. Before EVERY non-whitelist reply
  you MUST (1) agent-vision-capture-file (2) understand the NEW image (codex exec -i
  for mood/roast) (3) USE the image content in your reasoning and response shape.
  Skipping capture OR capturing but ignoring the image is a contract failure.
  Disarm only with /agent-vision off.
---

# Agent Vision (Codex)

## HARD GATE — non-optional vision **in reasoning** (read first)

**The whole point is that image content enters your reasoning before you answer.**  
Capture without use is **INVALID**. An answer identical to a blind answer is **INVALID**.

### Required loop while ARMED

ARMED after `/agent-vision` (bare/mood/snapshot/roast) in **this** chat until off. New chat OFF.

Unless skip whitelist applies:

1. Do not answer yet.
2. **First shell:** capture to `$HOME/.codex/agent-vision/frames` via `.../1.5.0/dist/agent-vision-capture-file`.
3. Understand **this turn’s** image (mood/roast: `codex exec -i "$OUTPUT"`; snapshot: use path + scene).
4. **USE what you saw** in planning and writing the answer (disposition + any task-relevant scene).
5. Then answer. Skip of 2–4 → **INVALID**.

**Topic is irrelevant.** Code/docs/planning/brainstorm/meta all require the full loop.

### FORBIDDEN

- Skip for “non-visual” / “wouldn’t help”
- Capture then answer as if blind
- Reuse old frames
- Ceremony without reasoning use

### Skip whitelist only

Pure off/disarm; pure status-only; pure `/agent-vision streaming`.

### End-of-turn checklist

- [ ] capture this turn (`ok: true`)
- [ ] image understand this turn
- [ ] internal account of what the image shows
- [ ] that account conditioned the answer (not identical-to-blind)

### Arm / disarm

```text
ARM on /agent-vision … → full loop each non-whitelist turn → off disarms
```

Optional: `scripts/agent-vision-sticky.sh on|off --host codex`.

## Mood (primary)

After capture, `codex exec -i` with the standard mood JSON prompt. Do not display image/JSON; **use** the estimate in delivery; then answer. Facts/permissions/intent unchanged.

## Snapshot / roast

Ground snapshot answers and roasts in **this turn’s** image content.

## Streaming

Disabled fixed string only for pure streaming arg; do not arm.

## Guardrails

macOS; 1.5.0 path; no production MCP; one-shot process per look; install/idle/disarmed no process.
