---
name: agent-vision
description: >
  Explicit local Mac camera snapshot for Grok Build via Agent Vision.
  Use only when the user invokes /agent-vision with snapshot or streaming arguments.
  Do not auto-start the camera. Ship A: snapshot and disabled streaming only.
disable-model-invocation: true
argument-hint: snapshot|streaming
compatibility: >
  macOS; Grok sandbox off; requires Agent Vision runtime
  (install scripts/install-runtime.sh — AgentVision.app under AGENT_VISION_HOME).
metadata:
  short-description: "Local Mac camera snapshot for Grok Build"
  ship: "A"
---

# Agent Vision (Grok Build — Ship A)

Use Agent Vision only when the user explicitly invokes `/agent-vision` for local Mac camera context.

## Ship A scope

| Argument | Behavior |
| --- | --- |
| `snapshot` | One-shot capture → JPEG under `~/.agent-vision/frames` → `read_file` → Markdown image |
| `streaming` | Fixed disabled message; **launch no process** |
| stop / turn off camera | Fixed no-session message; **launch no process** |
| `roast` / `mood` | **Not in Ship A.** Tell the user roast and mood are Milestone 2 on Grok; offer snapshot instead. |

Do not use codex exec. Do not call MCP tools for Agent Vision. Do not register or assume an Agent Vision MCP server.

## Execution discipline

Agent Vision camera requests are not repository tasks. Do not orient on the workspace, inspect files, check git state, read README or AGENTS files, or summarize the project before acting.

This skill controls the local camera. Do not inspect or roast the repository, source files, git state, README, or workspace unless the capture command fails and the exact failure requires local debugging.

For `snapshot`, the first shell command must create the frame directory and run `agent-vision-capture-file`. Do not run `git status`, `rg`, `find`, `ls`, `sed`, `cat`, or any repository/workspace inspection command before the capture command.

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

## Snapshot workflow

1. Create the frame directory and choose a new absolute output path:

```bash
mkdir -p -m 700 "$HOME/.agent-vision/frames" && OUTPUT="$HOME/.agent-vision/frames/agent-vision-$(date +%Y%m%d-%H%M%S).jpg" && agent-vision-capture-file --output "$OUTPUT" --json
```

2. Verify the command printed JSON with `ok: true` and that `path` exists.
3. Use `read_file` on the absolute JPEG path so you can see the real image pixels.
4. Reply with a Markdown image link using the absolute path, plus any user-requested inspection of the scene.
5. Do not mention internal readiness metadata such as brightness values unless reporting an error.

If capture fails (`ok: false`, missing helper, permission denied, or timeout), report the exact error text. Do not invent scene content from metadata, paths, or memory.

Snapshot mode intentionally waits for a usable frame. If the camera returns black warm-up frames, the tool keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts before returning an error.

## Streaming (disabled)

For `/agent-vision streaming` or any request to start streaming:

1. Do not call a tool.
2. Do not launch `AgentVision.app`, `agent-vision-mcp`, or `agent-vision-capture-file`.
3. Reply exactly: `Agent Vision streaming is temporarily disabled while the runtime uses an explicit one-shot capture design. Snapshot still uses one-shot capture and exits after the requested frame.`

For stop-streaming requests (“streaming off”, “stop streaming”, “turn off the camera”) when no capture is in progress:

1. Do not call a tool.
2. Do not launch any Agent Vision process.
3. Reply exactly: `Agent Vision streaming is disabled, so there is no Agent Vision streaming session to stop.`

## Privacy and lifecycle

- Install, plugin enablement, idle Grok startup, unrelated prompts, streaming, and stop-streaming must not start any Agent Vision camera-capable process.
- Capture runs only for explicit `/agent-vision snapshot`.
- Frames stay local under `~/.agent-vision/frames`. No cloud upload.
- Camera permission belongs to signed `AgentVision.app`.

## Slash command summary

- `/agent-vision snapshot` — one usable JPEG, camera off, show image via Markdown after `read_file`.
- `/agent-vision streaming` — disabled message; no process.
- Roast and mood — not available in Ship A on Grok (Milestone 2).
