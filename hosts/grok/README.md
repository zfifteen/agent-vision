# Agent Vision — Grok Build host adapter (Ship A)

Public experimental adapter for [Grok Build](https://github.com/xai-org) on macOS.

## Scope

| Feature | Ship A |
| --- | --- |
| `/agent-vision snapshot` | Yes — JPEG under `~/.agent-vision/frames` |
| Streaming | Disabled (fixed message, no process) |
| Roast / mood | Not yet (Milestone 2) |
| Production MCP | No |

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
- Run `/agent-vision snapshot`.

Full user instructions: [INSTALL.md](../../INSTALL.md#grok-build-ship-a).  
QA matrix: [docs/agent-vision-grok-install-uninstall-traceability.md](../../docs/agent-vision-grok-install-uninstall-traceability.md).

## Layout

```text
hosts/grok/
  plugin.json
  skills/agent-vision/SKILL.md
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
