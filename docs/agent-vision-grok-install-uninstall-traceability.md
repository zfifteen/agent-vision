# Agent Vision Grok Build Install/Uninstall Traceability

Date: 2026-07-13  
Scope: **Grok Build** — sticky mood-first session (arm → HARD GATE capture each non-whitelist turn → off); supporting snapshot/roast; streaming disabled; turn-gate + purge helpers

Codex package lifecycle remains documented in [agent-vision-install-uninstall-traceability.md](./agent-vision-install-uninstall-traceability.md).  
Sticky contract: [agent-vision-grok-session-sticky.md](./agent-vision-grok-session-sticky.md).

## Runtime invariant

Install, Grok skill/plugin enablement, idle Grok startup, **disarmed** prompts, `/agent-vision streaming`, pure status, and stop-streaming requests must not start:

```text
agent-vision-mcp
AgentVision.app
agent-vision-capture-file   # except during armed non-whitelist turns or explicit snapshot|roast|mood
mcp-fifo
```

Camera-capable code runs only when the skill runs the capture helper for an **armed** turn (or explicit one-shot arm modes). Sticky/turn-gate/purge helpers never start the camera.

## Traceability matrix

| Requirement | Mapping | QA check |
| --- | --- | --- |
| Shared runtime installable | `scripts/install-runtime.sh` → `$AGENT_VISION_HOME` (default `~/.local/share/agent-vision`) | `test -x "$HOME/.local/share/agent-vision/dist/agent-vision-capture-file"` |
| Codesign preserved | Copy without re-sign when possible; `codesign --verify --deep --strict` | Verify after install |
| PATH shim (capture) | `~/.local/bin/agent-vision-capture-file` | `command -v agent-vision-capture-file` with `~/.local/bin` on PATH |
| PATH shims (helpers) | sticky / turn-gate / purge via `install-grok.sh` | `command -v agent-vision-sticky agent-vision-turn-gate agent-vision-purge-frames` |
| Frame directory | `~/.agent-vision/frames` (dirs mode `0700`) | Exists after install or first capture |
| Session state dir | `~/.agent-vision/session-state.json`, `turn-gate.json` | Written only by helpers/skill; no camera |
| Grok skill installed | `~/.grok/skills/agent-vision/SKILL.md` | `scripts/install-grok.sh`; `test -f` skill path |
| Skill contracts | Mood-first purpose, HARD GATE, sticky, turn-gate, `disable-model-invocation: false`, no Codex cache sole path | `scripts/test-grok-adapter.sh` |
| No MCP | Empty/absent Agent Vision MCP in Grok config; plugin has no `mcpServers` | `test-grok-adapter.sh`; inspect `~/.grok/config.toml` |
| Install starts no camera | Baseline PID check in install scripts | Install scripts fail if new Agent Vision PIDs appear |
| Sticky arm/off | sticky helper + skill | Manual `/agent-vision` then `/agent-vision off`; `agent-vision-sticky status` |
| Snapshot works | Helper + `read_file` | Manual `/agent-vision snapshot`; optional `AGENT_VISION_LIVE=1 scripts/test-capture-file-cli.sh` |
| Roast works | Capture + `read_file` + roast text; Markdown image link | Manual `/agent-vision roast` |
| Mood works (primary) | Capture + `read_file` + disposition + incorporate into reasoning; silent | Manual `/agent-vision mood` (optionally with a work request) |
| HARD GATE armed turns | Capture + use pixels + turn-gate ready each non-whitelist turn | Manual multi-turn while armed; `test-agent-vision-turn-gate.sh` |
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
command -v agent-vision-sticky agent-vision-turn-gate agent-vision-purge-frames
scripts/test-grok-adapter.sh
scripts/test-grok-sticky-state.sh
scripts/test-agent-vision-turn-gate.sh
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
