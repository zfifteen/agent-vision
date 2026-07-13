---
name: agent-vision
description: >
  Primary purpose: ascertain the user's current mood/disposition from one
  explicit local Mac camera frame and incorporate that signal into reasoning
  before generating the response or completing the task ( /agent-vision mood ).
  Also supports snapshot and roast on the same capture path. Streaming disabled.
  Use only when the user invokes /agent-vision. Do not auto-start the camera.
disable-model-invocation: true
argument-hint: mood|snapshot|roast|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "Mood-first local camera for Grok: disposition → better delivery"
  primary-mode: mood
---

# Agent Vision (Grok Build)

## Purpose (read this first)

**Agent Vision’s main product value is mood/disposition.**

When the user opts in with `/agent-vision mood`, you:

1. Capture **one** local JPEG of the user (explicit, consented, camera off after).
2. **Ascertain** current presence and interaction disposition from the image pixels.
3. **Incorporate that knowledge into your reasoning** before you write the answer or continue the task.
4. Shape **how** you help (pacing, clarity, density, tone, repair) — **not what facts or permissions** apply.

Everything else in this skill exists to **support** that loop:

| Mode | Role relative to mood |
| --- | --- |
| **`mood`** | **Primary.** Disposition signal → fold into reasoning → then respond / act. |
| **`snapshot`** | Supporting: same capture stack; object/scene inspection; proves file materialization. |
| **`roast`** | Supporting: same vision path under a loud comedy mode; not the product core. |
| **`streaming`** | Disabled. No always-on camera. |

Mood is **opt-in** (`disable-model-invocation: true`). Never start the camera or estimate mood unless the user explicitly invokes `/agent-vision mood` (or another listed mode). A mood read is **ephemeral**: current response or current task phase only — not session history, not a dataset.

### Mood reasoning loop (mandatory for `/agent-vision mood`)

```text
invoke mood
  → capture usable JPEG (camera-first; no repo inspection first)
  → read_file(JPEG)   # real pixels only
  → ascertain presence + interaction_state + confidence
  → IF usable signal: incorporate into how you reason about the user's request
  → THEN generate the response / continue the task with delivery fit applied
  → do not narrate the mood estimate (silent unless user asks to debug)
```

**Incorporate means:** treat the disposition signal as prior context for *how* you help on this turn — for example lead with the fix when blocked, compress when overloaded, raise evidence density when skeptical, slow down when high-stakes. Complete the user’s actual request; mood does not replace the task.

**Do not incorporate means:** inventing medical/psychological labels, changing facts, loosening permissions, inventing user intent, expanding or shrinking task scope, or ignoring a user correction of the mood read.

## Scope

| Argument | Behavior |
| --- | --- |
| `mood` | **Primary.** Capture → `read_file` → ascertain disposition → fold into reasoning → respond/act (silent; no image/JSON display) |
| `snapshot` | Capture → `read_file` → Markdown image (+ optional scene inspection) |
| `roast` | Capture → `read_file` → playful roast ≤400 chars + Markdown image |
| `streaming` | Fixed disabled message; **launch no process** |
| stop / turn off camera | Fixed no-session message; **launch no process** |

Do not use codex exec. Do not call MCP tools for Agent Vision. Do not register or assume an Agent Vision MCP server.

On Grok, multimodal image access is `read_file` on the saved JPEG (not `codex exec -i`). Capture first, then `read_file`, then mood/roast/snapshot analysis from the actual image pixels only.

## Execution discipline

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before acting.

This skill controls the local camera. Do not inspect or roast the repository, source files, git state, README, or workspace unless the capture command fails and the exact failure requires local debugging.

For `mood`, `snapshot`, and `roast`, the first shell command must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

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

## Capture (shared by mood, snapshot, roast)

1. Create the frame directory and choose a new absolute output path:

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

2. Verify the command printed JSON with `ok: true` and that `path` exists.
3. Use `read_file` on the absolute JPEG path so you can see the real image pixels.
4. Do not invent scene content or mood from metadata, paths, or memory if capture or `read_file` fails.

Mood, snapshot, and roast intentionally wait for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.

If capture fails (`ok: false`, missing helper, permission denied, or timeout), report the exact error text and stop.

## Mood workflow (primary)

After capture + `read_file`:

1. **Ascertain** the user’s current interaction disposition from the image for **this turn only**.
2. Form strict JSON (internally) with exactly these keys:
   - `presence`: one of `present`, `absent`, `uncertain`
   - `interaction_state`: one of `focused_neutral`, `frustrated_or_blocked`, `tired_or_overloaded`, `curious_or_exploratory`, `skeptical_or_evaluating`, `high_stakes_or_cautious`, `absent`, `uncertain`
   - `confidence`: number from 0 to 1
   - `observable_basis`: array of strings (visible cues only)
   - `assistant_adjustments`: array of strings (delivery fit only)
3. Apply these gates:
   - If the user is absent, occluded, multiple people are visible, image quality is unusable, or confidence is below 0.40 → `interaction_state` `uncertain` or `absent` and **no** mood-conditioned behavior (answer the request normally).
   - If confidence is from 0.40 through 0.69 → only low-risk clarity adjustments.
   - If confidence is 0.70 or higher → state-specific delivery adjustments are allowed.
4. Do **not** infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories.
5. **Incorporate into reasoning before the user-facing answer:** use a usable mood signal as prior context for how you plan and phrase the response or task work. Mood may change pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior. It must **not** change facts, permissions, approval behavior, user intent, or task scope.
6. **Then** produce the response or continue the task with those delivery choices applied.
7. **Do not display** the saved JPEG, the JSON, the confidence band, or a visual-analysis summary in the normal final answer. The value is better help, not a mood report.
8. Apply only to the current response or current task phase. User correction overrides the visual estimate for the rest of that phase.
9. If `read_file` or analysis fails, report that exact failure instead of estimating mood from metadata or memory.
10. Mood must not create mood history, a training dataset, background recording, a separate image archive, or any new raw-image persistence beyond the saved JPEG frame path.

If the user invoked mood **together with** a work request (same turn or immediate follow-up), complete that work under the mood-conditioned delivery rules above. If mood is standalone with no other request, give a brief, natural acknowledgement that you have a current read and are ready — still without dumping JSON or diagnosing the user — unless they asked to debug.

Debug exception: if the user **explicitly** asks to debug mood mode, you may show the image path and the strict JSON.

## Snapshot workflow (supporting)

After capture + `read_file`:

1. Reply with a Markdown image link using the absolute path, plus any user-requested inspection of the scene.
2. Do not mention internal readiness metadata such as brightness values unless reporting an error.

## Roast workflow (supporting)

After capture + `read_file`:

1. Write exactly one playful roast of **400 characters or fewer** based **only** on visible non-sensitive details in the image (outfit, posture, expression, lighting, room chaos).
2. Do **not** infer or attack protected traits, body size, age, disability, or other sensitive attributes.
3. Do **not** write a roast from Markdown, metadata, filename, or memory without a successful `read_file` of the JPEG.
4. Final response **must** include:
   - a Markdown image link using the absolute captured JPEG path
   - the roast text
5. Keep roasts opt-in, light, and funny — not a municipal cruelty department.

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
- Capture runs only for explicit `/agent-vision mood`, `/agent-vision snapshot`, or `/agent-vision roast`.
- Frames stay local under `~/.agent-vision/frames`. No cloud upload.
- Camera permission belongs to signed `AgentVision.app`.
- No background mood detection: no camera without an explicit slash invocation.

## Slash command summary

- `/agent-vision mood` — **primary:** ascertain disposition, incorporate into reasoning, then respond/act (silent).
- `/agent-vision snapshot` — supporting: one JPEG, show image after `read_file`.
- `/agent-vision roast` — supporting: image + playful roast.
- `/agent-vision streaming` — disabled message; no process.
- stop streaming / turn off camera — no-session message; no process.

If the first argument is missing or unsupported, tell the user the supported arguments exactly: `mood`, `snapshot`, `roast`, `streaming`. Prefer pointing people at **`mood`** when they ask what Agent Vision is for.
