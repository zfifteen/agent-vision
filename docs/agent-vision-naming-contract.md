# Agent Vision Naming Contract

This document is the canonical naming source for Agent Vision (including the Codex rebrand and multi-host surfaces).

## Canonical Values

| Surface | Value |
| --- | --- |
| Plugin, repository, and package slug | `agent-vision` |
| Display name | `Agent Vision` |
| Slash command | `/agent-vision` |
| macOS bundle id | `works.velocity.agent-vision` |
| App bundle name | `AgentVision.app` |
| App executable name | `AgentVision` |
| App display name | `Agent Vision` |
| Capture helper | `agent-vision-capture-file` |
| GitHub URL | `https://github.com/zfifteen/agent-vision` |

## Host-specific surfaces

| Surface | Value |
| --- | --- |
| Codex skill directory name | `camera-control` (slash still `/agent-vision` via command) |
| Grok skill `name` (slash command) | `agent-vision` |
| Grok host tree | `hosts/grok/` |
| Grok plugin manifest | `hosts/grok/plugin.json` |
| Runtime home (default) | `$HOME/.local/share/agent-vision` |
| Runtime env override | `AGENT_VISION_HOME` |
| PATH shim | `$HOME/.local/bin/agent-vision-capture-file` |
| Codex frame directory | `$HOME/.codex/agent-vision/frames` |
| Grok frame directory (Ship A) | `$HOME/.agent-vision/frames` |
| Codex plugin cache (1.5.0) | `~/.codex/plugins/cache/local/agent-vision/1.5.0` |

## MCP (non-production on public hosts)

| Surface | Value | Production policy |
| --- | --- | --- |
| MCP server id | `agent-vision` | **Not registered** on Codex 1.5.0 or Grok Ship A |
| MCP tool prefix | `agent_vision_*` | Source/tests only |
| MCP wrapper script | `agent-vision-mcp` | Excluded from packaged user runtime |

## Compatibility

Pre-release compatibility aliases are not required unless a later issue explicitly changes that decision.

Do not keep legacy slash-command, MCP tool, slug, Swift/app, or display-name aliases on public release-facing surfaces.

Do not ship a parallel user-invocable Grok skill named `camera-control`.

## Application

Use these values for plugin manifests, skill frontmatter, installer paths, local cache paths, marketplace entries, app bundle metadata, release packaging, public documentation, tests, and validation assertions.
