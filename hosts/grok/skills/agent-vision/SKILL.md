---
name: agent-vision
description: >
  CRITICAL WHILE ARMED: (1) capture (2) read_file NEW JPEG (3) USE pixels in
  reasoning (4) turn-gate record + ready. Capture theater or blind answers are
  INVALID. Topic irrelevant. Disarm only with /agent-vision off. Status/purge helpers available.
disable-model-invocation: false
argument-hint: mood|snapshot|roast|off|status|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (scripts/install-runtime.sh).
metadata:
  short-description: "HARD GATE sticky vision: capture, use image, turn-gate"
  primary-mode: mood
  sticky: true
  contract: non-optional-vision-in-reasoning
---

# Agent Vision (Grok Build)

Long recipes: [references/mood-roast-recipes.md](references/mood-roast-recipes.md).

## HARD GATE — non-optional vision in reasoning

**The point is using image content in reasoning before you answer.** Capture without use is INVALID. Blind-identical answers are INVALID.

### When ARMED

ARMED after `/agent-vision` (bare/mood/snapshot/roast) in **this** chat until off. New chat OFF. State file alone does not arm.

**Every non-whitelist user message while ARMED:**

1. Do **not** answer yet.
2. **First tool:** capture shell (no repo tools first):

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

3. **Ambiguity burst:** if capture fails or frame unusable after `read_file`, run **one** second capture+`read_file` (still one-shot; no daemon). Details in references.
4. **`read_file`** the new JPEG path (pixels, not path guessing).
5. **USE THE IMAGE IN REASONING:** internal account of presence/disposition/scene; condition delivery and any scene-grounded facts. Answer must not be identical to a blind answer.
6. **Turn-gate (mechanical, per-turn):**

```bash
agent-vision-turn-gate begin
# after successful capture + read_file:
agent-vision-turn-gate record --path "$OUTPUT"
agent-vision-turn-gate ready
```

`ready` is **single-use**: after a successful ready, the next turn must `begin` + capture + `record` again. Reusing an old capture within max-age without a new record is fail-closed. If `ready` fails, do not send the final answer.

7. Then answer. Skip of 2–6 → **INVALID**.

**Topic is irrelevant** (code, docs, planning, brainstorm, meta — all require the loop).

### FORBIDDEN

- Skip for “non-visual” / “wouldn’t help”
- Capture then ignore pixels
- Reuse old frames
- Ceremony without reasoning use
- Answering without turn-gate `ready` success while armed

### Skip whitelist (closed)

| May skip full loop | Condition |
| --- | --- |
| Disarm | off/stop/disable/turn off camera — **no other task** |
| Pure status | entire message only status/armed/on |
| Pure streaming | entire message only `/agent-vision streaming` |
| Pure status command | `/agent-vision status` only |

### End-of-turn checklist

- [ ] capture this turn (`ok: true`)
- [ ] `read_file` this turn’s path
- [ ] used image in reasoning
- [ ] `turn-gate record` + `ready` succeeded

### Arm / disarm / status

```bash
agent-vision-sticky on --host grok --mode mood
agent-vision-sticky off --host grok
agent-vision-sticky status   # sticky + last_capture_age_seconds; no mood JSON
agent-vision-purge-frames --ttl-days 7 --all   # optional frame retention
```

Optional: `/agent-vision off --purge-frames` → disarm then purge.

Do not use codex exec. No MCP. No invent from metadata.

## Disposition playbooks (delivery only)

Apply when mood confidence and gates allow. Never change facts, permissions, intent, or task scope.

| `interaction_state` | Do | Don’t |
| --- | --- | --- |
| `focused_neutral` | Clear structure, normal density, direct answers | Over-apologize or over-hedge |
| `frustrated_or_blocked` | Lead with the fix / next action; short path; own prior misses | Long preambles, extra options first |
| `tired_or_overloaded` | Shortest correct path; one recommendation; clear stop | Walls of options, deep digressions |
| `curious_or_exploratory` | Slightly more context and alternatives; invite next step | Premature lock-in without options |
| `skeptical_or_evaluating` | Evidence first; show reasoning; cite paths/commands | Hand-wavy claims |
| `high_stakes_or_cautious` | Explicit assumptions; confirm before irreversible steps | Silent risky actions |
| `absent` / `uncertain` | Answer from user words only; no mood shaping | Invent presence or emotion |

User correction of state wins until next capture.

## Modes

| Mode | Behavior |
| --- | --- |
| bare / `mood` | Arm + full loop; silent disposition use |
| `snapshot` | Arm + full loop; Markdown image + scene use |
| `roast` | Arm + full loop; roast grounded in image (see references) |
| `status` | sticky status JSON/summary; no capture if pure status |
| `off` | Disarm; optional purge |
| `streaming` | Disabled fixed text; do not arm |

## Runtime

`agent-vision-capture-file` on PATH or `$HOME/.local/share/agent-vision/dist/...`. Missing → install-runtime.sh. One-shot process per look.
