# Codex Installation Instructions

These instructions are for a local Codex agent installing Agent Vision from the repository.

1. Clone the repository:

```bash
git clone https://github.com/zfifteen/agent-vision.git /Users/velocityworks/IdeaProjects/agent-vision
```

2. Inspect the plugin metadata:

```bash
cd /Users/velocityworks/IdeaProjects/agent-vision
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
```

3. Run the deterministic local installer:

```bash
scripts/install-local.sh
```

4. Use the MCP tools:

```text
agent_vision_snapshot
agent_vision_start
agent_vision_frame
agent_vision_stop
```

Or use the bundled slash commands:

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
```

Version 1.0 is pull-based:

- `/agent-vision snapshot` waits for one usable JPEG frame, returns it into chat, and stops the camera only if snapshot started it. If the camera returns a black warm-up frame, Agent Vision keeps the camera on, waits 5 seconds between attempts, and tries up to 3 total attempts.
- `/agent-vision streaming` starts a live camera session. The Mac camera indicator should stay on while this session is active.
- `/agent-vision roast` is snapshot plus prose: it waits for one usable JPEG frame, returns it into chat, stops the camera only if roast started it, and writes one opt-in playful roast of 400 characters or fewer from visible non-sensitive details.
- While streaming is active, Codex may call `agent_vision_frame` whenever visual context would help, without asking for each frame.
- When the user asks to stop streaming or stop camera use, call `agent_vision_stop`.
