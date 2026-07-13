---
name: agent-vision
description: >
  CRITICAL WHILE ARMED: capture is not enough. Before EVERY non-whitelist reply
  you MUST (1) agent-vision-capture-file (2) read_file the NEW JPEG (3) USE the
  actual image pixels in your reasoning and in how you form the response.
  Skipping capture OR capturing but ignoring the image is a contract failure.
  Never skip for "non-visual" topics. Disarm only with /agent-vision off.
disable-model-invocation: false
argument-hint: mood|snapshot|roast|off|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "HARD GATE: capture + USE image in reasoning every armed turn"
  primary-mode: mood
  sticky: true
  contract: non-optional-vision-in-reasoning
---

# Agent Vision (Grok Build)

## HARD GATE — non-optional vision **in reasoning** (read first)

**The whole point of Agent Vision is that camera image content enters your reasoning before you answer.**  
Capture alone is **not** compliance. `read_file` alone is **not** compliance. You must **use what you saw**.

This contract is **mandatory**. Treating the loop as optional, ceremonial, or skippable is a **contract violation**.

### The required loop (while ARMED)

Agent Vision is **ARMED** after any successful `/agent-vision` invoke (bare, mood, snapshot, roast) in **this** chat until `/agent-vision off`. New chat starts OFF. A leftover state file alone does **not** arm.

**On every user message while ARMED, unless the skip whitelist applies:**

1. **Do not** write the user-facing answer yet.
2. **First tool call this turn MUST be** the capture shell (no other tools before it):

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

3. **Second:** `read_file` on the absolute JPEG path from **that** capture (real pixels, not path string guessing).
4. **Third — USE THE IMAGE IN REASONING (critical):**
   - Form an internal understanding of **what is in the image** (presence, expression/posture cues, desk/scene objects, lighting, anything task-relevant).
   - For mood/default: ascertain disposition and let it shape **how** you help (pacing, clarity, density, tone, repair) without changing facts, permissions, or intent.
   - For any task: if the scene contains cues relevant to the user’s request, **use them**. If the scene is only the user (no desk objects), still use disposition/presence in delivery.
   - Your plan for the answer must be **conditioned on** what you just saw. An answer that would be identical if you had never looked is **INVALID**.
5. **Then** write the user-facing answer under that conditioned plan.
6. If you skipped 2, 3, or 4, the response is **INVALID**. Stop and complete the loop before continuing.

**Topic is irrelevant.** While armed you MUST run the full loop (capture → read → **use in reasoning** → answer) for:

- code, debugging, refactors, PRs  
- docs, design, planning, brainstorming, enhancements  
- meta talk about Agent Vision itself  
- any other help, analysis, or task  

### What “use in reasoning” means (non-optional)

| Required | Not enough |
| --- | --- |
| Internally describe what the pixels show (at least disposition/presence; plus scene if relevant) | Only storing the file path |
| Let that understanding affect **what you prioritize**, **how you phrase**, and **how you structure** the reply | Capture then answer as if blind |
| Mood: apply delivery fit from visible cues (or explicitly treat as uncertain/absent if gates fail) | “I captured” with zero effect on the answer |
| If user asked about something visible, ground the answer in the image | Invent scene content without looking |

Silent mood: do **not** dump JSON or a mood monologue to the user unless they ask to debug — but you **must still use** the estimate internally.

### FORBIDDEN while ARMED (escape / evasion)

- “This doesn’t need the camera”
- “Vision wouldn’t help here”
- “I’ll skip capture this turn”
- “Non-visual topic → skip”
- Capture/`read_file` then **ignore** the image and answer as if blind
- Answering from memory/repo only without a **new** capture + `read_file` + **use** **this turn**
- Using an old frame from a previous turn instead of capturing again
- Capturing only on `/agent-vision` slash and not on later armed turns
- Treating the loop as theater (run tools, discard visual content)

### Skip whitelist (closed; ONLY these may skip the full loop while armed)

| May skip loop | Condition |
| --- | --- |
| Explicit disarm | `/agent-vision off`, or clear off/stop/disable/“turn off the camera”/“agent vision off” with **no other task** |
| Pure status only | Entire message is only “are you armed?” / “status” / “is vision on?” with **no other ask** |
| Streaming arg only | Entire message is only `/agent-vision streaming` |

If the message is **anything else** (including mixed status + work), the **full loop is required**.

There is **no** “when vision would help” judgment. Judgment is disabled while armed.

### End-of-turn compliance (private checklist before final answer)

While ARMED and not on the skip whitelist:

- [ ] `agent-vision-capture-file` ran **this turn** and returned `ok: true`
- [ ] `read_file` ran on **that** new path **this turn**
- [ ] I formed an internal account of **what the image shows**
- [ ] That account **changed or confirmed** how I reason about / deliver this answer (if identical-to-blind → **INVALID**, re-do step 4)

If any box is unchecked → **do not send** the final answer; complete the loop first.

### Arm / disarm mechanics

```text
NEW conversation     → OFF
/agent-vision [mood|snapshot|roast|bare] → ARM + full vision loop this turn
while ARMED          → every non-whitelist turn:
                         capture → read_file → USE image in reasoning → respond
/agent-vision off    → DISARM
```

After arming:

```bash
agent-vision-sticky on --host grok --mode mood
```

On disarm:

```bash
agent-vision-sticky off --host grok
```

Track ARMED in **this conversation**. File is a helper; conversation arm is required.

Do not use codex exec. Do not call MCP for Agent Vision. Do not invent scene/mood from metadata or memory.

---

## Purpose

**Main product value:** the agent **sees**, **understands the image**, and **reasons with that understanding** before helping. Mood/disposition is the primary product use of that vision. Capture without use is a failed product.

| Mode | Role |
| --- | --- |
| **mood** (default bare `/agent-vision`) | Primary. Full loop; disposition shapes delivery (silent). |
| **snapshot** | Supporting. Full loop; show image + use scene in the answer. |
| **roast** | Supporting. Full loop; roast grounded in what you saw. |
| **off** | Disarm. No loop. |
| **streaming** | Disabled text. Do not arm. |

## Runtime

Prefer:

```bash
agent-vision-capture-file --output "$OUTPUT" --json
```

or `"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file"`.  
If `AGENT_VISION_HOME` is set, use that dist path. Missing helper → `scripts/install-runtime.sh`. No screenshots/browser fallback.

Each look is **one-shot process lifecycle** (not an always-on daemon).

## Mood (after HARD GATE steps 2–4)

1. From the **pixels**, ascertain presence + interaction disposition.
2. Internal JSON keys: `presence`, `interaction_state`, `confidence`, `observable_basis`, `assistant_adjustments` (gates: below 0.40 no mood behavior; 0.40–0.69 low-risk clarity; 0.70+ state-specific delivery).
3. No medical/psychological/crisis/protected-trait inference.
4. **Use** that estimate in how you plan and write the answer (delivery fit only).
5. Do not display JPEG/JSON/mood diagnosis unless user asks to debug mood.
6. User correction overrides until next capture.

Standalone arm with no other request: brief ready ack (no JSON dump) — still after a real look.

## Snapshot / roast (after HARD GATE steps 2–4)

- **snapshot:** Markdown image link with absolute path; answer must use scene understanding when relevant.
- **roast:** ≤400 chars playful, non-sensitive only; **must** be grounded in visible details from this turn’s image; image link + roast text.

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

- `/agent-vision` \| `mood` — arm + full loop (mood primary)  
- `snapshot` \| `roast` — arm + mode (still use image in reasoning)  
- `off` — disarm  
- `streaming` — disabled; do not arm  

Unsupported arg → list: `mood`, `snapshot`, `roast`, `off`, `streaming`.
