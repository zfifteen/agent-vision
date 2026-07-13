---
description: HARD GATE sticky Agent Vision — capture every non-whitelist turn while armed; off to disarm.
argument-hint: mood|snapshot|roast|off|streaming
---

# /agent-vision

## HARD GATE (non-optional)

While **ARMED** in this conversation (after any `/agent-vision` arm until `/agent-vision off`):

1. Do not answer yet.
2. **First shell command** must be capture to `$HOME/.codex/agent-vision/frames` via `.../1.5.0/dist/agent-vision-capture-file --output "$OUTPUT" --json`.
3. Then understand the image (mood/roast: `codex exec -i`; snapshot: show path).
4. Then answer using what you saw.

**Topic is irrelevant.** Code/docs/planning/brainstorm/meta all require capture while armed.

**FORBIDDEN:** skipping because “non-visual,” “wouldn’t help,” or “optional.”

**Skip whitelist only:** pure off/disarm; pure status-only; pure `/agent-vision streaming`.

New chat starts OFF. Leftover state file alone does not arm.

## Modes

- bare / `mood` — arm + mood loop (primary)
- `snapshot` / `roast` — arm + mode
- `off` — disarm; no capture
- `streaming` — disabled; do not arm

Optional: `scripts/agent-vision-sticky.sh on|off --host codex`.

## Privacy

One-shot capture process per look. Install/idle/disarmed: no Agent Vision process. No production MCP.
