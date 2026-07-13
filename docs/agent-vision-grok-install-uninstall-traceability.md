# Agent Vision Grok Build Install/Uninstall Traceability

Date: 2026-07-13  
Scope: **Grok Build** — primary mode **mood** (disposition → reason → respond); supporting snapshot/roast; streaming disabled

Codex package lifecycle remains documented in [agent-vision-install-uninstall-traceability.md](./agent-vision-install-uninstall-traceability.md).

## Runtime invariant

Install, Grok skill/plugin enablement, idle Grok startup, unrelated prompts, `/agent-vision streaming`, and stop-streaming requests must not start:

```text
agent-vision-mcp
AgentVision.app
agent-vision-capture-file   # except during explicit /agent-vision snapshot|roast|mood
mcp-fifo
```

Camera-capable code runs only for explicit `/agent-vision snapshot`, `/agent-vision roast`, or `/agent-vision mood` through the installed capture helper.

## Traceability matrix

| Requirement | Mapping | QA check |
| --- | --- | --- |
| Shared runtime installable | `scripts/install-runtime.sh` → `$AGENT_VISION_HOME` (default `~/.local/share/agent-vision`) | `test -x "$HOME/.local/share/agent-vision/dist/agent-vision-capture-file"` |
| Codesign preserved | Copy without re-sign when possible; `codesign --verify --deep --strict` | Verify after install |
| PATH shim | `~/.local/bin/agent-vision-capture-file` | `command -v agent-vision-capture-file` with `~/.local/bin` on PATH |
| Frame directory | `~/.agent-vision/frames` (dirs mode `0700`) | Exists after install or first one-shot mode |
| Grok skill installed | `~/.grok/skills/agent-vision/SKILL.md` | `scripts/install-grok.sh`; `test -f` skill path |
| Skill contracts | Mood-first purpose, reasoning loop, `disable-model-invocation: true`, camera-first, no Codex cache sole path | `scripts/test-grok-adapter.sh` |
| No MCP | Empty/absent Agent Vision MCP in Grok config; plugin has no `mcpServers` | `test-grok-adapter.sh`; inspect `~/.grok/config.toml` |
| Install starts no camera | Baseline PID check in install scripts | Install scripts fail if new Agent Vision PIDs appear |
| Snapshot works | Helper + `read_file` | Manual `/agent-vision snapshot`; optional `AGENT_VISION_LIVE=1 scripts/test-capture-file-cli.sh` |
| Roast works | Capture + `read_file` + roast text; Markdown image link | Manual `/agent-vision roast` |
| Mood works (primary) | Capture + `read_file` + ascertain disposition + incorporate into reasoning before answer; silent | Manual `/agent-vision mood` (optionally with a work request) |
| Streaming safe | Fixed disabled copy; no process | Manual slash / stop phrases |
| Uninstall adapter | `scripts/uninstall-grok.sh` | Skill/plugin dirs gone; runtime may remain |
| Uninstall runtime | `scripts/uninstall-runtime.sh` | Runtime home and shim removed |
| Sandbox | Supported: sandbox **off** | Documented; restricted profiles unsupported |

## Install checks

```bash
cd /path/to/agent-vision
scripts/install-runtime.sh --dry-run
scripts/install-runtime.sh
codesign --verify --deep --strict "$HOME/.local/share/agent-vision/dist/AgentVision.app"
test -x "$HOME/.local/share/agent-vision/dist/agent-vision-capture-file"
test -x "$HOME/.local/bin/agent-vision-capture-file"
scripts/install-grok.sh --dry-run
scripts/install-grok.sh
test -f "$HOME/.grok/skills/agent-vision/SKILL.md"
scripts/test-grok-adapter.sh
# optional live:
# AGENT_VISION_LIVE=1 scripts/test-capture-file-cli.sh
# Must not leave residual processes after capture:
# pgrep -lf 'agent-vision-capture-file|agent-vision-mcp|AgentVision.app|mcp-fifo' || true
```

## Uninstall checks

```bash
scripts/uninstall-grok.sh
test ! -e "$HOME/.grok/skills/agent-vision"
scripts/uninstall-runtime.sh
test ! -e "$HOME/.local/share/agent-vision"
test ! -e "$HOME/.local/bin/agent-vision-capture-file"
# Optional frames:
# scripts/uninstall-runtime.sh --remove-frames
```

## Dual-host note

Installing Grok does not remove the Codex package (1.5.0). Uninstalling the Grok adapter should not remove a runtime still needed for other uses; use `uninstall-runtime.sh` only when no host needs the shared app.
