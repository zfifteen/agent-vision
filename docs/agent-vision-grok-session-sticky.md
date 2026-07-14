# Agent Vision sticky session contract (Grok + Codex)

Date: 2026-07-13  
Status: implemented in host skills + `scripts/agent-vision-sticky.sh` + turn-gate + purge  
Last revised: 2026-07-13 (HARD GATE, single-use ready, playbooks, status/purge)

## Purpose

Agent Vision is **mood-first vision-in-the-loop**: when armed, the agent captures local camera image(s), figures out what is in the image, and **incorporates that into reasoning** before responding or completing tasks.

## HARD GATE (non-optional)

While ARMED, the full loop is **mandatory** on every user turn except a **closed skip whitelist** (pure off, pure status-only, pure streaming):

```text
capture → understand image (pixels) → USE image content in reasoning → turn-gate ready → respond
```

**Capture without use is a failure.** An answer identical to a blind answer is **INVALID**. **Topic is irrelevant.** Skill text: `HARD GATE`, `USE THE IMAGE IN REASONING`, `FORBIDDEN`, end-of-turn checklist including reasoning use.

## Session model

| Event | Result |
| --- | --- |
| New chat / conversation | **OFF** (always). Leftover `~/.agent-vision/session-state.json` alone does **not** arm. |
| `/agent-vision` or `/agent-vision mood` | **ARM** + mood vision loop |
| `/agent-vision snapshot` \| `roast` | **ARM** + that mode |
| Any non-whitelist user turn while ARMED | Capture → understand → reason → respond (**required**) |
| `/agent-vision off`, stop, disable, “turn off the camera”, “agent vision off” | **DISARM** |
| `/agent-vision status` (pure) | sticky + last_capture_age; **no** capture |
| `/agent-vision streaming` | Disabled message; **do not arm** |

## Process lifecycle

Sticky is **agent policy**, not an always-on camera daemon. Each look uses one-shot `agent-vision-capture-file` (camera on briefly, then off). Install/idle/disarmed must start no Agent Vision process.

## State + gate + purge helpers

```bash
scripts/agent-vision-sticky.sh on --host grok|codex --mode mood|snapshot|roast
scripts/agent-vision-sticky.sh off [--host grok|codex]
scripts/agent-vision-sticky.sh status   # sticky + last_capture_age_seconds
scripts/agent-vision-sticky.sh is-on

scripts/agent-vision-turn-gate.sh begin
scripts/agent-vision-turn-gate.sh record --path /path/to.jpg
scripts/agent-vision-turn-gate.sh ready [--max-age SEC]   # fail-closed; single-use per turn
scripts/agent-vision-turn-gate.sh status|clear

scripts/agent-vision-purge-frames.sh --ttl-days 7 --all|--grok|--codex [--dry-run]
```

| File | Role |
| --- | --- |
| `~/.agent-vision/session-state.json` | sticky arm/mode/host |
| `~/.agent-vision/turn-gate.json` | per-turn record + consume |

Helpers never launch the camera. PATH shims: `agent-vision-sticky`, `agent-vision-turn-gate`, `agent-vision-purge-frames` (after host install).

### Turn-gate rules

- `begin` opens a turn and invalidates prior ready.
- `record --path PATH` records a successful capture for the current turn (path must exist).
- `ready` exits 0 only if the **current** turn has an **unconsumed** successful record, the file still exists, and age ≤ max-age (default 600s). On success it **consumes** the record so a later turn cannot reuse it without a new record.
- Fail-closed otherwise (exit 1). If `ready` fails, do not send the final answer while armed.

**Ambiguity burst:** one second one-shot capture if first frame unusable (documented in skill + references).

## Host vision paths

| Host | Image understand path |
| --- | --- |
| Grok | multimodal `read_file` on JPEG; skill `disable-model-invocation: false` |
| Codex | `codex exec -i` for mood/roast; Markdown path for snapshot |

## Disposition playbooks

Delivery-only shaping from inferred `interaction_state` (see skill tables). Never change facts, permissions, intent, or task scope. User correction wins until next capture.

## Tests

```bash
scripts/test-grok-sticky-state.sh
scripts/test-grok-adapter.sh
scripts/test-agent-vision-turn-gate.sh
scripts/test-agent-vision-purge-frames.sh
```
