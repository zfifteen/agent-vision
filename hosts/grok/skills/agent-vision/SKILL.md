---
name: agent-vision
description: >
  CRITICAL WHILE ARMED: Before EVERY non-whitelist reply you MUST run
  agent-vision-capture-file then read_file on the new JPEG. NEVER skip because
  the topic is code, docs, planning, or "non-visual." Capture is mandatory, not
  optional. Disarm only with /agent-vision off. Primary: mood/disposition from
  camera into reasoning. Sticky until off. Streaming disabled.
disable-model-invocation: false
argument-hint: mood|snapshot|roast|off|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "HARD GATE sticky vision: capture every turn while armed"
  primary-mode: mood
  sticky: true
  contract: non-optional-vision-loop
---

# Agent Vision (Grok Build)

## HARD GATE — non-optional vision loop (read first; no exceptions by topic)

This contract is **mandatory**. Treating capture as optional, “not useful this turn,” or skippable for non-camera topics is a **contract violation**.

### When ARMED in this conversation

Agent Vision is **ARMED** after any successful `/agent-vision` invoke (bare, mood, snapshot, roast) in **this** chat until `/agent-vision off` (or equivalent disarm). New chat starts OFF. A leftover state file alone does **not** arm.

**On every user message while ARMED, unless the skip whitelist below applies:**

1. **Do not** write the user-facing answer yet.
2. **First tool call this turn MUST be** the capture shell (no `git`, `rg`, `ls`, repo inspect, or other tools before it):

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

3. **Second:** `read_file` on the absolute JPEG path from that capture.
4. **Then** reason and answer, using what you saw (mood disposition + scene as relevant).
5. If you skipped steps 2–3, the response is **INVALID**. Stop and run them before continuing.

**Topic is irrelevant.** While armed you MUST capture for:

- code, debugging, refactors, PRs  
- docs, design, planning, brainstorming, “enhancements”  
- meta talk about Agent Vision itself  
- any other help, analysis, or task  

### FORBIDDEN while ARMED (escape / evasion)

Do **not** do any of the following:

- “This doesn’t need the camera”
- “Vision wouldn’t help here”
- “I’ll skip capture this turn”
- “Non-visual topic → skip”
- Answering from memory/repo only without a **new** capture + `read_file` **this turn**
- Using an old frame from a previous turn instead of capturing again
- Capturing only on `/agent-vision` slash and not on later substantive turns

### Skip whitelist (closed; ONLY these may skip capture while armed)

| May skip capture | Condition |
| --- | --- |
| Explicit disarm | `/agent-vision off`, or clear off/stop/disable/“turn off the camera”/“agent vision off” with **no other task** |
| Pure status only | Entire message is only “are you armed?” / “status” / “is vision on?” with **no other ask** |
| Streaming arg only | Entire message is only `/agent-vision streaming` |

If the message is **anything else** (including mixed status + work), **capture is required**.

There is **no** “when vision would help” judgment. Judgment is disabled while armed.

### End-of-turn compliance (private checklist before final answer)

While ARMED and not on the skip whitelist:

- [ ] `agent-vision-capture-file` ran **this turn** and returned `ok: true`
- [ ] `read_file` ran on **that** new path **this turn**
- [ ] Disposition/scene informed how you deliver the answer

If any box is unchecked → **do not send** the final answer; run capture/`read_file` first.

### Arm / disarm mechanics

```text
NEW conversation     → OFF
/agent-vision [mood|snapshot|roast|bare] → ARM + vision loop this turn
while ARMED          → every non-whitelist turn: capture → read_file → reason → respond
/agent-vision off    → DISARM (no further captures until re-invoke)
```

After arming, also run (never starts camera):

```bash
agent-vision-sticky on --host grok --mode mood
# or: scripts/agent-vision-sticky.sh on --host grok --mode mood
```

On disarm:

```bash
agent-vision-sticky off --host grok
```

Track ARMED in **this conversation**. File is a helper; conversation arm is required.

Do not use codex exec. Do not call MCP for Agent Vision. Do not invent scene/mood from metadata or memory.

---

## Purpose

**Main product value:** mood/disposition + vision-in-the-loop. See HARD GATE: while armed, vision is how you reason before you help.

| Mode | Role |
| --- | --- |
| **mood** (default bare `/agent-vision`) | Primary. Arm + disposition → reason → respond (silent; no image/JSON dump). |
| **snapshot** | Supporting. Arm + show image + use scene. |
| **roast** | Supporting. Arm + roast + use scene. |
| **off** | Disarm. No capture. |
| **streaming** | Disabled text. Do not arm. |

## Runtime

Prefer:

```bash
agent-vision-capture-file --output "$OUTPUT" --json
```

or `"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file"`.  
If `AGENT_VISION_HOME` is set, use that dist path. Missing helper → tell user to run `scripts/install-runtime.sh`. No screenshots/browser fallback.

Each look is **one-shot process lifecycle** (not an always-on daemon). Sticky = agent policy to capture every non-whitelist turn, not a held-open camera.

## Mood (after HARD GATE capture + read_file)

1. Ascertain presence + interaction disposition from the image.
2. Internal JSON keys: `presence`, `interaction_state`, `confidence`, `observable_basis`, `assistant_adjustments` (gates: below 0.40 no mood behavior; 0.40–0.69 low-risk clarity; 0.70+ state-specific delivery).
3. No medical/psychological/crisis/protected-trait inference.
4. Incorporate into reasoning; change only pacing, verbosity, clarification, evidence density, tone, repair.
5. Do not display JPEG/JSON/mood diagnosis unless user asks to debug mood.
6. User correction overrides until next capture.

Standalone arm with no other request: brief ready ack (no JSON dump).

## Snapshot / roast (after HARD GATE capture + read_file)

- **snapshot:** Markdown image link with absolute path; use scene understanding.
- **roast:** ≤400 chars playful, non-sensitive only; image link + roast text.

## Disarm

On off/stop/disable/turn off camera/agent vision off:

1. Sticky off script if available.
2. Mark conversation disarmed.
3. No capture.
4. Brief confirm off until next `/agent-vision`.

## Streaming (disabled)

Only for pure `/agent-vision streaming`: no arm, no process, exact text:

`Agent Vision streaming is temporarily disabled while the runtime uses an explicit one-shot capture design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`

## Privacy

Install/idle/disarmed: no camera process. Frames under `~/.agent-vision/frames`. No cloud upload. Permission: signed `AgentVision.app`.

## Slash summary

- `/agent-vision` \| `mood` — arm + mood loop  
- `snapshot` \| `roast` — arm + mode  
- `off` — disarm  
- `streaming` — disabled; do not arm  

Unsupported arg → list: `mood`, `snapshot`, `roast`, `off`, `streaming`.
