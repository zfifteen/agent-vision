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

4. Restart Codex.

5. Use the MCP tools:

```text
codex_vision_start
codex_vision_frame
codex_vision_stop
```

Version 1.0 is pull-based: Codex receives camera frames only when it calls `codex_vision_frame`.
