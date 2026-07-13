---
name: agent-vision
description: >
  Sticky local Mac camera vision for Grok Build. Primary purpose: ascertain the
  user's mood/disposition from camera image(s), understand what is in the image,
  and incorporate that into reasoning before responding or completing tasks.
  Arm with /agent-vision (default mood). Stay armed for the conversation until
  /agent-vision off. Also snapshot and roast. Streaming disabled.
disable-model-invocation: false
argument-hint: mood|snapshot|roast|off|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "Sticky mood-first Mac camera vision for Grok"
  primary-mode: mood
  sticky: true
---

# Agent Vision (Grok Build)

## Purpose (read this first)

**Agent Vision’s main product value is mood/disposition + vision-in-the-loop reasoning.**

When armed, for each **substantive** user turn you must:

1. Capture **one or more** usable local JPEGs from the Mac camera (usually one; retry if unusable).
2. **`read_file`** the JPEG(s) and figure out **what is in the image**.
3. **Incorporate that understanding into your reasoning** before you write the answer or continue the task.
4. For mood (default): ascertain disposition and shape delivery fit — not facts, permissions, or intent.

| Mode | Role |
| --- | --- |
| **`mood`** (default) | **Primary.** Arm sticky → vision loop → disposition → reason → respond (silent; no image/JSON dump). |
| **`snapshot`** | Supporting. Arm sticky → vision loop → show image + use scene understanding. |
| **`roast`** | Supporting. Arm sticky → vision loop → playful roast + use what you saw. |
| **`off`** | **Disarm sticky.** No capture. |
| **`streaming`** | Disabled message. Do **not** arm. |

## Session sticky model (mandatory)

```text
NEW conversation / chat  →  OFF  (always; leftover state file alone is NOT enough)

/agent-vision            →  ARM + mood vision loop
/agent-vision mood       →  ARM + mood vision loop
/agent-vision snapshot   →  ARM + snapshot vision loop
/agent-vision roast      →  ARM + roast vision loop

While ARMED in THIS conversation:
  each substantive user turn → capture → understand image → reason with it → respond

/agent-vision off
  or: stop | disable | "turn off the camera" | "agent vision off"
  →  DISARM  (no further captures until re-invoke)
```

### Hard gates (`disable-model-invocation: false`)

You may load this skill without a slash **only** to honor sticky policy. **Never capture** unless **one** of:

1. The user **explicitly invoked** `/agent-vision` (or a mode) **in this message**, or  
2. Sticky is **armed in this conversation** (you previously armed after a slash in **this** chat) **and** the turn is substantive.

**New chat starts OFF.** Do not arm from a leftover `~/.agent-vision/session-state.json` alone. Require an explicit `/agent-vision` invoke in the current conversation to arm.

**Substantive turn:** user wants help, a task, analysis, code, or a real answer.  
**Non-substantive (may skip capture while armed):** pure status (“are you still on?”), pure off/disarm, or pure help about modes.

### Sticky state file (helper, not camera)

After arming in this conversation, run (prefer repo or PATH copy of the script):

```bash
# From agent-vision repo if available:
scripts/agent-vision-sticky.sh on --host grok --mode mood
# After disarm:
scripts/agent-vision-sticky.sh off --host grok
# Optional:
scripts/agent-vision-sticky.sh status
```

If the script is missing, still track armed/off **in conversation** and follow the same rules. The file must never launch the camera.

Do not use codex exec. Do not call MCP tools for Agent Vision. Do not register or assume an Agent Vision MCP server.

## Execution discipline

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before the capture command.

For capture turns, the **first shell command** must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

## Runtime requirements

- Supported: Grok **sandbox off** (default).
- Prefer helper on PATH:

```bash
agent-vision-capture-file --output "$OUTPUT" --json
```

or:

```bash
"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

If `AGENT_VISION_HOME` is set, use `"$AGENT_VISION_HOME/dist/agent-vision-capture-file"`.

If the helper is missing, report that the user should run `scripts/install-runtime.sh`. Do not fall back to screenshots, existing photos, or browser capture.

## Capture (shared vision loop)

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

1. Verify JSON `ok: true` and `path` exists.
2. `read_file` the absolute JPEG path (real pixels only).
3. If unusable/black, the helper already retries; if still failing, report the exact error. You may capture a second frame once if the first is unusable.
4. Never invent scene content or mood from metadata, paths, or memory.

Each look is **one-shot process lifecycle**: capture helper starts camera briefly and exits. Sticky does **not** mean an always-on camera daemon.

## Mood workflow (primary; default on bare `/agent-vision`)

After capture + `read_file`:

1. Ascertain presence + interaction disposition from the image.
2. Internally form JSON keys: `presence`, `interaction_state`, `confidence`, `observable_basis`, `assistant_adjustments` (same enums/gates as before: below 0.40 no mood behavior; 0.40–0.69 low-risk clarity; 0.70 or higher state-specific delivery).
3. Do **not** infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories.
4. **Incorporate into reasoning before the user-facing answer**, then respond/act.
5. Mood may change pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior only.
6. **Do not display** the JPEG, JSON, or a mood diagnosis unless the user asks to debug mood.
7. User correction overrides the visual estimate for the rest of the armed conversation until a new capture updates it.
8. No mood history dataset, no background recording beyond saved frame files.

If mood is standalone with no other request: brief natural ack that you have a current read and are ready (no JSON dump).

## Snapshot workflow (supporting)

After capture + `read_file`: show Markdown image link using the absolute path; use scene understanding in the answer if relevant.

## Roast workflow (supporting)

After capture + `read_file`: one playful roast ≤400 characters from visible non-sensitive details only; include Markdown image link + roast text. No protected-trait attacks.

## Disarm (`off`)

When the user says `/agent-vision off`, `off`, `stop`, `disable`, “turn off the camera”, “agent vision off”, or equivalent **while Agent Vision is in use**:

1. Run sticky off (script if available).
2. Mark this conversation **disarmed**.
3. **Do not** capture.
4. Reply briefly that Agent Vision is off for this session until they invoke `/agent-vision` again.

## Streaming (disabled)

For `/agent-vision streaming` only:

1. Do not arm sticky from streaming.
2. Do not launch any Agent Vision process.
3. Reply exactly: `Agent Vision streaming is temporarily disabled while the runtime uses an explicit one-shot capture design. Snapshot, roast, and mood still use one-shot capture and exit after the requested frame.`

(Disarm phrases above are **not** the streaming-disabled copy when the user is turning Agent Vision off.)

## Privacy and lifecycle

- Install, plugin enable, idle Grok startup: **no** camera process.
- Capture only when armed in this conversation (or this message is an explicit invoke).
- Frames under `~/.agent-vision/frames`. No cloud upload.
- Camera permission: signed `AgentVision.app`.
- Sticky = agent policy to capture on substantive turns; not an always-on camera process.

## Slash summary

- `/agent-vision` or `/agent-vision mood` — arm + mood vision loop (primary).
- `/agent-vision snapshot` | `roast` — arm + that mode.
- `/agent-vision off` — disarm.
- `/agent-vision streaming` — disabled; do not arm.

If the argument is unsupported, list: `mood`, `snapshot`, `roast`, `off`, `streaming`. Prefer **`mood`** when explaining what Agent Vision is for.
