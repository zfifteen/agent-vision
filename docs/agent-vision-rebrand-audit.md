# Agent Vision Rebrand Audit

Branch: `codex/agent-vision-rebrand`

Audited from `main` after fetching `origin`.

## Strongest Finding

The rebrand is not a documentation-only change. The old identity is part of public plugin discovery, slash commands, MCP server and tool names, install/cache paths, app bundle metadata, release archive names, and generated release contents.

Existing pre-release installs should be treated as breakable unless compatibility aliases are explicitly requested. The narrow release-ready path is to rename the public surface to Agent Vision without keeping `/codex-vision` or `codex_vision_*` aliases.

## Rename Defaults

| Surface | Current value | Agent Vision value |
| --- | --- | --- |
| Plugin/repo/package slug | `codex-vision` | `agent-vision` |
| Display name | `Codex Vision` | `Agent Vision` |
| Slash command | `/codex-vision` | `/agent-vision` |
| MCP server id | `codex-vision` | `agent-vision` |
| MCP tool prefix | `codex_vision_*` | `agent_vision_*` |
| MCP wrapper script | `codex-vision-mcp` | `agent-vision-mcp` |
| macOS bundle id | `works.velocity.codex-vision` | `works.velocity.agent-vision` |
| App bundle/display name | `CodexVision.app` / `Codex Vision` | `AgentVision.app` / `Agent Vision` |
| GitHub URL | `https://github.com/zfifteen/codex-vision` | `https://github.com/zfifteen/agent-vision` |

## Must Change Before Release

| Group | Old values found | Proposed values | Public | Breaking | Files |
| --- | --- | --- | --- | --- | --- |
| Public docs | `Codex Vision`, `codex-vision`, `/codex-vision`, `codex_vision_*`, old GitHub URLs, `CodexVision.app` | Agent Vision names from defaults | Yes | Yes | `README.md`, `INSTALL.md`, `CODEX_INSTALL.md`, `PRIVACY.md` |
| Plugin discovery metadata | plugin name `codex-vision`, display name `Codex Vision`, descriptions, homepage/repository URLs, default prompts, screenshots | `agent-vision`, `Agent Vision`, new URLs, `/agent-vision ...` prompts | Yes | Yes | `.codex-plugin/plugin.json` |
| MCP server configuration | server id `codex-vision`, command `./dist/codex-vision-mcp` | `agent-vision`, `./dist/agent-vision-mcp` | Yes | Yes | `.mcp.json` |
| Slash command | file and heading `commands/codex-vision.md`, command `/codex-vision`, calls to `codex_vision_*` | `commands/agent-vision.md`, `/agent-vision`, `agent_vision_*` | Yes | Yes | `commands/codex-vision.md` |
| Skill instructions | name and tool references `Codex Vision`, `/codex-vision`, `codex_vision_*` | Agent Vision wording and `agent_vision_*` tool calls | Yes | Yes | `skills/camera-control/SKILL.md` |
| MCP runtime API | serverInfo `codex-vision`, tool names `codex_vision_snapshot/start/frame/stop`, descriptions, errors, frame text | `agent-vision`, `agent_vision_snapshot/start/frame/stop`, Agent Vision text | Yes | Yes | `Sources/CodexVisionCore/MCPServer.swift` |
| macOS app identity | `CodexVision.app`, executable `CodexVision`, bundle id `works.velocity.codex-vision`, bundle name `Codex Vision`, camera permission text | `AgentVision.app`, executable `AgentVision`, bundle id `works.velocity.agent-vision`, Agent Vision permission text | Yes | Yes | `Sources/CodexVision/Info.plist`, `scripts/install-local.sh`, `scripts/package-release.sh` |
| Installer and local marketplace registration | `~/plugins/codex-vision`, `~/.codex/plugins/cache/local/codex-vision/1.0.0`, `codex-vision@local`, admission-check text, install output | `agent-vision` paths and plugin ids, Agent Vision admission text | Yes | Yes | `scripts/install-local.sh` |
| Release packaging | `release/codex-vision-1.0.0`, `codex-vision-1.0.0.tar.gz`, copied old docs/config/scripts/assets | `release/agent-vision-1.0.0`, `agent-vision-1.0.0.tar.gz`, regenerated contents | Yes | Yes | `scripts/package-release.sh`, `release/codex-vision-1.0.0*` |
| CI manifest assertions | assertions for `codex-vision` plugin and MCP server ids | assertions for `agent-vision` | Yes | Yes | `.github/workflows/ci.yml` |
| Brand assets | hero, logo, composer icon likely contain old brand or old visual identity | regenerated Agent Vision assets at same dimensions | Yes | No API break | `assets/readme-hero.png`, `assets/logo.png`, `assets/composer-icon.png` |

## Internal Cleanup To Decide During Rename

| Group | Old values found | Recommended treatment | Public | Breaking | Files |
| --- | --- | --- | --- | --- | --- |
| Swift package/product/module/test names | package `codex-vision`, products and targets `CodexVision`, `CodexVisionCore`, `CodexVisionTests` | Rename executable target to `AgentVision`; rename core/test modules only if the implementation pass accepts the larger file-path change | Partly | Yes for imports/tests | `Package.swift`, `Sources/CodexVision`, `Sources/CodexVisionCore`, `Tests/CodexVisionTests` |
| Swift source directory names | `Sources/CodexVision`, `Sources/CodexVisionCore`, `Tests/CodexVisionTests` | Optional internal cleanup unless package/product rename requires it | No direct public prose | Yes for build config | source and test directories |
| Dispatch queue labels | `codex-vision.capture.session`, `codex-vision.capture.frames` | Rename to `agent-vision.capture.*`; low-risk internal consistency | No | No | `Sources/CodexVisionCore/CameraController.swift` |
| CLI usage/errors | `Usage: CodexVision ...`, FIFO error text | Rename to `AgentVision`; public when launched incorrectly | Yes | No | `Sources/CodexVision/main.swift` |

## Generated Release Output

The `release/codex-vision-1.0.0` directory and `release/codex-vision-1.0.0.tar.gz` contain stale public artifacts. They should not be edited by hand. The release package should be removed or regenerated from the renamed sources after the implementation pass.

The tracked source list does not include the `release/` directory, so stale release contents are local generated output rather than tracked source.

## Verification Commands For Implementation Pass

Run these after the rename implementation:

```sh
git ls-files | xargs rg -n "Codex Vision|codex-vision|CodexVision|codex_vision|/codex-vision"
find release -type f -maxdepth 4 -print | sort | xargs rg -n "Codex Vision|codex-vision|CodexVision|codex_vision|/codex-vision"
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
swift test
scripts/install-local.sh --dry-run
```

Expected result: the first search has no public-facing matches. Any remaining `Codex` matches must refer to the host agent/app generically, not the plugin brand.
