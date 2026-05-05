# Codex Installation Instructions

These instructions are for a local Codex agent installing Codex Vision from the repository.

1. Clone the repository:

```bash
git clone https://github.com/zfifteen/codex-vision.git /Users/velocityworks/IdeaProjects/codex-vision
```

2. Inspect the plugin metadata:

```bash
cd /Users/velocityworks/IdeaProjects/codex-vision
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
```

3. Run the deterministic local installer:

```bash
scripts/install-local.sh
```

4. Use the MCP tools:

```text
codex_vision_snapshot
codex_vision_start
codex_vision_frame
codex_vision_stop
```

Or use the bundled slash commands:

```text
/codex-vision snapshot
/codex-vision streaming
```

Version 1.0 is pull-based:

- `/codex-vision snapshot` returns one JPEG frame into chat and stops the camera.
- `/codex-vision streaming` starts a live camera session. The Mac camera indicator should stay on while this session is active.
- While streaming is active, Codex may call `codex_vision_frame` whenever visual context would help, without asking for each frame.
- When the user asks to stop streaming or stop camera use, call `codex_vision_stop`.

There is no public `/codex-vision frame` or `/codex-vision stop` slash mode in version 1.0. Those are MCP tool actions Codex performs from the installed skill.
