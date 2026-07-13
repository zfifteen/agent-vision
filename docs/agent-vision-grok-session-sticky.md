# Agent Vision sticky session contract (Grok + Codex)

Date: 2026-07-13  
Status: implemented in host skills + `scripts/agent-vision-sticky.sh`

## Purpose

Agent Vision is **mood-first vision-in-the-loop**: when armed, the agent captures local camera image(s), figures out what is in the image, and incorporates that into reasoning before responding or completing tasks.

## Session model

| Event | Result |
| --- | --- |
| New chat / conversation | **OFF** (always). Leftover `~/.agent-vision/session-state.json` alone does **not** arm. |
| `/agent-vision` or `/agent-vision mood` | **ARM** + mood vision loop |
| `/agent-vision snapshot` \| `roast` | **ARM** + that mode |
| Substantive user turn while ARMED | Capture → understand → reason → respond |
| `/agent-vision off`, stop, disable, “turn off the camera”, “agent vision off” | **DISARM** |
| `/agent-vision streaming` | Disabled message; **do not arm** |

## Process lifecycle

Sticky is **agent policy**, not an always-on camera daemon. Each look uses one-shot `agent-vision-capture-file` (camera on briefly, then off). Install/idle/disarmed must start no Agent Vision process.

## State helper

```bash
scripts/agent-vision-sticky.sh on --host grok|codex --mode mood|snapshot|roast
scripts/agent-vision-sticky.sh off [--host grok|codex]
scripts/agent-vision-sticky.sh status
scripts/agent-vision-sticky.sh is-on
```

State file: `~/.agent-vision/session-state.json` (mode 0600). Never launches the camera.

## Host vision paths

| Host | Image understand path |
| --- | --- |
| Grok | multimodal `read_file` on JPEG |
| Codex | `codex exec -i` for mood/roast; Markdown path for snapshot |

## Tests

```bash
scripts/test-grok-sticky-state.sh
scripts/test-grok-adapter.sh
```
