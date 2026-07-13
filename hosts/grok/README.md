# Agent Vision — Grok Build host adapter

## Purpose

**Mood-first sticky vision.** Arm once; each substantive turn captures a local frame, understands the image, and folds that into reasoning until `/agent-vision off`.

| Mode | Role |
| --- | --- |
| `/agent-vision` or `mood` | **Primary** — arm + disposition → reason → respond (silent) |
| `snapshot` / `roast` | Supporting — arm + mode |
| `off` | Disarm |
| Streaming | Disabled; do not arm |

New chat always starts **OFF**. Vision path: multimodal `read_file`. Process: one-shot capture per look (no always-on daemon).

Contract: [docs/agent-vision-grok-session-sticky.md](../../docs/agent-vision-grok-session-sticky.md).

## Install

```bash
scripts/install-runtime.sh
scripts/install-grok.sh
```

- `~/.local/bin` on `PATH`
- Grok **sandbox off**
- New Grok session after install
- Primary: `/agent-vision` or `/agent-vision mood`

## Layout

```text
hosts/grok/
  plugin.json
  skills/agent-vision/SKILL.md
  README.md
```

Sticky helper (shared): `scripts/agent-vision-sticky.sh`

## Tests

```bash
scripts/test-grok-adapter.sh
scripts/test-grok-sticky-state.sh
```
