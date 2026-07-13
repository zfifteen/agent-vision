# Agent Vision — Grok Build host adapter

Public adapter for [Grok Build](https://github.com/xai-org) on macOS.

## Purpose

**Mood is the product.** Agent Vision lets Grok take one explicit local camera frame, ascertain the user’s current disposition, and **fold that signal into reasoning before answering or finishing the task** — without changing facts, permissions, or intent.

| Mode | Role |
| --- | --- |
| `/agent-vision mood` | **Primary** — capture → `read_file` → disposition → incorporate → respond/act (silent) |
| `/agent-vision snapshot` | Supporting — same capture stack; object/scene inspect |
| `/agent-vision roast` | Supporting — same vision path; opt-in comedy |
| Streaming | Disabled (fixed message, no process) |
| Production MCP | No |

Image analysis on Grok uses multimodal `read_file` on the saved JPEG (not `codex exec -i`). Camera only on explicit slash invoke.

## Install

Requires a signed `dist/AgentVision.app` in the repo tree (or release artifacts copied into `dist/`).

```bash
# from repository root
scripts/install-runtime.sh   # ~/.local/share/agent-vision + PATH shim
scripts/install-grok.sh      # ~/.grok/skills/agent-vision
```

- Put `~/.local/bin` on `PATH`.
- Use Grok with **sandbox off** (default).
- Open a **new** Grok session after install.
- Primary use: `/agent-vision mood` (optionally with a work request in the same turn).

Full user instructions: [INSTALL.md](../../INSTALL.md#grok-build).  
QA matrix: [docs/agent-vision-grok-install-uninstall-traceability.md](../../docs/agent-vision-grok-install-uninstall-traceability.md).

## Layout

```text
hosts/grok/
  plugin.json
  skills/agent-vision/SKILL.md   # agent instructions (mood-first)
  README.md
```

## Uninstall

```bash
scripts/uninstall-grok.sh
scripts/uninstall-runtime.sh              # optional
scripts/uninstall-runtime.sh --remove-frames
```

## Tests

```bash
scripts/test-grok-adapter.sh
AGENT_VISION_LIVE=1 scripts/test-capture-file-cli.sh   # optional hardware
```

## Design

[docs/agent-vision-grok-build-compatibility.md](../../docs/agent-vision-grok-build-compatibility.md)  
[docs/agent-vision-mood-technical-note.md](../../docs/agent-vision-mood-technical-note.md)
