---
name: camera-control
description: >
  CRITICAL WHILE ARMED: Before EVERY non-whitelist reply you MUST run
  agent-vision-capture-file then image understanding (codex exec -i for mood/roast).
  NEVER skip because the topic is code, docs, planning, or "non-visual." Capture is
  mandatory, not optional. Disarm only with /agent-vision off. Sticky until off.
---

# Agent Vision (Codex)

## HARD GATE — non-optional vision loop (read first; no exceptions by topic)

This contract is **mandatory**. Treating capture as optional or skippable for non-camera topics is a **contract violation**.

### When ARMED in this conversation

ARMED after any successful `/agent-vision` (bare, mood, snapshot, roast) in **this** chat until `/agent-vision off`. New chat starts OFF. State file alone does not arm.

**On every user message while ARMED, unless the skip whitelist applies:**

1. Do **not** write the user-facing answer yet.
2. **First shell command this turn MUST be** capture (no repo inspection first):

```bash
mkdir -p "$HOME/.codex/agent-vision/frames" && OUTPUT="$HOME/.codex/agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && "$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

3. **Then** understand the image (mood/roast: `codex exec -i "$OUTPUT"`; snapshot: display path + scene understanding).
4. **Then** reason and answer using what you saw.
5. Skip of steps 2–3 → response **INVALID**; run them before continuing.

**Topic is irrelevant.** Code, docs, planning, brainstorming, meta, debugging — all require capture while armed.

### FORBIDDEN while ARMED

- “Doesn’t need the camera” / “vision wouldn’t help” / “skip this turn”
- “Non-visual topic” as a reason to skip  
- Answer from memory/repo only without a **new** capture **this turn**  
- Reusing an old frame instead of capturing again  

### Skip whitelist (closed; ONLY these)

| May skip | Condition |
| --- | --- |
| Disarm | off / stop / disable / turn off camera / agent vision off with **no other task** |
| Pure status | Entire message only asks armed/status/on |
| Streaming only | Entire message only `/agent-vision streaming` |

No “when vision would help” judgment.

### End-of-turn checklist (before final answer while ARMED)

- [ ] capture ran this turn (`ok: true`)
- [ ] image understand step ran this turn
- [ ] delivery informed by what was seen  

### Arm / disarm

```text
NEW conversation → OFF
/agent-vision … → ARM + vision loop
while ARMED → capture every non-whitelist turn
/agent-vision off → DISARM
```

Optional: `scripts/agent-vision-sticky.sh on|off --host codex`.

## Mood (primary; bare `/agent-vision`)

After capture:

```bash
codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT" -- "Analyze the attached Agent Vision camera image for current interaction-state calibration only. Return strict JSON and no prose. Use exactly these keys: presence, interaction_state, confidence, observable_basis, assistant_adjustments. presence must be one of present, absent, uncertain. interaction_state must be one of focused_neutral, frustrated_or_blocked, tired_or_overloaded, curious_or_exploratory, skeptical_or_evaluating, high_stakes_or_cautious, absent, uncertain. confidence must be a number from 0 to 1. observable_basis and assistant_adjustments must be arrays of strings. Apply these gates: if the user is absent, occluded, multiple people are visible, image quality is unusable, or confidence is below 0.40, return interaction_state uncertain or absent and use no mood-conditioned behavior; if confidence is from 0.40 through 0.69, include only low-risk clarity adjustments; if confidence is 0.70 or higher, include state-specific response delivery adjustments. Do not infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories. Mood changes only pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior; it must not change facts, permissions, approval behavior, user intent, or task scope."
```

Do not display image/JSON; incorporate into reasoning; then answer. User correction wins until next capture.

## Snapshot / roast

- Snapshot: Markdown image link; use scene.
- Roast: `codex exec -i` with ≤400 char non-sensitive roast; image link + text.

## Streaming

Disabled fixed string for `/agent-vision streaming` only; do not arm.

## Guardrails

macOS; 1.5.0 cache path; no production MCP; install/idle/disarmed no process; one-shot capture per look.
