# Agent Vision Install/Uninstall Traceability Matrix

Date: 2026-05-06

## Documentation Discovery

Public OpenAI documentation was checked first because this document is intended to give users evidence that Agent Vision follows the available OpenAI/Codex guidance.

Public sources found:

- [OpenAI Developers](https://developers.openai.com/) identifies Codex as OpenAI's coding agent and Apps SDK as an MCP-based way to extend ChatGPT apps.
- [Codex use cases](https://developers.openai.com/codex/use-cases) documents Codex workflows, including local workflow integration, QA, and creating CLI tools Codex can use.
- [OpenAI Resources](https://developers.openai.com/resources) lists Apps SDK examples and MCP-oriented app resources.

Public source gap:

- No public OpenAI page was found that fully specifies Codex local plugin install/uninstall mechanics, local marketplace JSON, `.codex-plugin/plugin.json`, or Codex desktop local plugin cache layout.

Bundled Codex specifications found:

- `/Users/velocityworks/.codex/skills/.system/plugin-creator/SKILL.md`
- `/Users/velocityworks/.codex/skills/.system/plugin-creator/references/plugin-json-spec.md`

This matrix treats public OpenAI documentation as product/context evidence and the bundled `plugin-creator` documents as the concrete local Codex plugin specification.

## Traceability Matrix

| Requirement | Source | Agent Vision Mapping | Install Evidence | Uninstall Evidence | QA Check | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Plugin has required manifest at `.codex-plugin/plugin.json`. | Bundled `plugin-creator/SKILL.md`: keep `.codex-plugin/plugin.json` present. | `.codex-plugin/plugin.json` exists in repo, staged plugin, and cache. | `scripts/install-local.sh` copies `.codex-plugin` to `~/plugins/agent-vision` and cache. | `scripts/uninstall-local.sh` removes staged plugin and cache. | `python3 -m json.tool .codex-plugin/plugin.json`; verify installed/cached copies exist after install and do not exist after uninstall. | Mapped | Manifest remains source of plugin identity. |
| Plugin name is normalized and matches folder/plugin identity. | Bundled `plugin-creator/SKILL.md`: generated folder and plugin.json name are the same; name is lower-case hyphen-case. | Plugin name is `agent-vision`; staged path is `~/plugins/agent-vision`. | Installer validates `plugin.json` name equals `agent-vision`. | Uninstaller removes current and legacy `codex-vision` identities. | Run installer dry-run and inspect `~/.agents/plugins/marketplace.json`. | Mapped | Legacy cleanup is included because this plugin was renamed. |
| Manifest includes metadata and interface fields for user presentation. | Bundled `plugin-json-spec.md`: field guide for `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, and `interface`. | `.codex-plugin/plugin.json` defines all required presentation metadata, icons, logo, screenshots, prompts, URLs, and capabilities. | Installer copies manifest and assets to plugin home/cache. | Uninstaller removes plugin home/cache containing manifest/assets. | Parse manifest JSON and verify referenced assets exist. | Mapped | `defaultPrompt` has three entries, matching spec guidance. |
| Plugin paths are relative to plugin root. | Bundled `plugin-json-spec.md`: path values should be relative and begin with `./`; screenshots under `./assets/`. | `skills`, `mcpServers`, icon, logo, and screenshot paths are relative. | Installer copies all referenced directories/files into plugin home/cache. | Uninstaller removes staged copies. | Parse manifest and verify `./skills/`, `./.mcp.json`, and assets exist in repo and cache. | Mapped | Relative `.mcp.json` is also preserved for package portability. |
| Plugin may provide skills. | Bundled `plugin-json-spec.md`: `skills` field points to skill directories/files. | `skills/camera-control/SKILL.md` defines camera workflow and guardrails. | Installer copies `skills` to plugin home/cache; Codex prompt admission includes `agent-vision:camera-control`. | Uninstaller removes plugin home/cache and plugin config. | `codex debug prompt-input "agent vision install check"` contains one Agent Vision plugin entry; inspect skill path. | Mapped | Skill is the human workflow contract. |
| Plugin may provide MCP servers. | Bundled `plugin-json-spec.md`: `mcpServers` field points to MCP config path. Public OpenAI docs identify MCP as a supported tool surface. | `.mcp.json` defines `agent-vision` server with `./dist/agent-vision-mcp`. | Installer copies `.mcp.json`, stages wrapper, and registers top-level `mcp_servers.agent_vision`. | Uninstaller removes `mcp_servers.agent_vision` and legacy MCP sections. | Installed MCP `tools/list` must return four Agent Vision tools. | Mapped | Top-level config is added because local plugin MCP discovery alone did not expose tools in current sessions. |
| Home-local marketplace uses `~/.agents/plugins/marketplace.json` and `./plugins/<plugin-name>`. | Bundled `plugin-creator/SKILL.md` and `plugin-json-spec.md`: home-local marketplace convention. | Installer writes `~/.agents/plugins/marketplace.json` entry with `source.path = ./plugins/agent-vision`. | Installer creates or updates local marketplace with `agent-vision`. | Uninstaller removes only `agent-vision` and legacy `codex-vision` entries. | Parse marketplace JSON before/after install/uninstall; unrelated entries must remain. | Mapped | Installer intentionally uses `INSTALLED_BY_DEFAULT` for this local plugin. |
| Marketplace entry includes installation policy, authentication policy, and category. | Bundled `plugin-creator/SKILL.md`: every entry includes `policy.installation`, `policy.authentication`, and `category`. | Installer writes all three fields. | Uninstaller removes only matching plugin entries. | Inspect `~/.agents/plugins/marketplace.json` after install. | Mapped | `authentication = ON_INSTALL` matches the bundled default. |
| Codex plugin config enables local plugin. | Bundled local workflow plus observed Codex config behavior. | Installer writes `[plugins."agent-vision@local"] enabled = true`. | Uninstaller removes current and legacy plugin sections. | Inspect `~/.codex/config.toml` after install/uninstall. | Mapped | This is bundled/local behavior, not a public OpenAI web spec. |
| Codex MCP config enables normal tool registry loading. | Public OpenAI docs establish MCP as a tool capability; local Codex config uses `[mcp_servers.*]`. | Installer writes `[mcp_servers.agent_vision]` with absolute command and cwd. | Uninstaller removes current and legacy MCP sections. | Inspect `~/.codex/config.toml`; open a new Codex session to load `agent_vision_*` tools. | Mapped | A new Codex session is required for tool registry reload. |
| Slash command has metadata and contracts for all public modes. | Bundled plugin examples use `commands/`; local command convention uses YAML frontmatter. | `commands/agent-vision.md` has `description`, `argument-hint`, and instructions for `/agent-vision snapshot`, `/agent-vision streaming`, and `/agent-vision roast`. | Installer validates command frontmatter and required snippets before build/install. | Uninstaller removes command copies with plugin home/cache. | Static check for required snippets; command copies present after install. | Mapped | Roast intentionally maps to snapshot plus prose, not a separate MCP tool. |
| MCP server exposes expected tools. | Public OpenAI docs establish MCP/tool context; Agent Vision `.mcp.json` and server tests specify concrete names. | `AgentVisionCore.MCPServer` exposes four tools. | Installer runs JSON-RPC `initialize` and `tools/list` against cached wrapper. | Uninstall removes wrapper and MCP config. | Probe `tools/list` for `agent_vision_snapshot`, `agent_vision_start`, `agent_vision_frame`, `agent_vision_stop`. | Mapped | This is the core runtime install invariant. |
| macOS camera permission attaches to stable app identity. | macOS platform behavior; Agent Vision privacy/install docs. | Signed `AgentVision.app` uses bundle id `works.velocity.agent-vision` and `NSCameraUsageDescription`. | Installer builds app bundle, writes `Info.plist`, and signs with Apple Development identity. | Uninstaller removes staged/cached app bundle. | `plutil -lint`; `codesign --verify --deep --strict`; inspect `Info.plist`. | Mapped | Public OpenAI docs do not define macOS camera permission behavior. |
| Install fails explicitly when required local prerequisites are missing. | QA best practice and existing installer contract. | Installer checks macOS, Swift, Python, Codex CLI, and signing identity. | Not applicable. | Run `scripts/install-local.sh --dry-run`; review explicit failure messages. | Mapped | Dry-run does not require Codex CLI or signing identity. |
| Uninstall is deterministic and preserves unrelated state. | QA requirement from this audit. | `scripts/uninstall-local.sh` removes Agent Vision files/config only. | Not applicable. | Uninstaller removes plugin home/cache, marketplace entry, and config sections. | Install, snapshot config, uninstall, compare unrelated marketplace/config entries. | Mapped | This script turns previous prose-only uninstall into executable QA. |
| Legacy rebrand artifacts are cleaned. | Agent Vision rebrand history and installer cleanup. | Current and legacy `codex-vision` paths/sections are listed in install and uninstall cleanup. | Installer removes old rebrand cache/temp/plugin paths. | Uninstaller removes old rebrand cache/temp/plugin paths and config sections. | Verify no `codex-vision` plugin/cache/temp/config sections remain. | Mapped | Prevents collisions between old and current plugin identities. |
| User-facing install evidence is documented. | User QA requirement for confidence evidence. | README, INSTALL, CODEX_INSTALL, and this matrix document expected behavior. | Installer output lists installed paths and usage. | Uninstall script output states removal. | Review docs and run lifecycle checklist. | Mapped | Matrix should be updated when install behavior changes. |

## Lifecycle QA Checklist

### Documentation/source checks

```bash
test -f /Users/velocityworks/.codex/skills/.system/plugin-creator/SKILL.md
test -f /Users/velocityworks/.codex/skills/.system/plugin-creator/references/plugin-json-spec.md
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
```

Confirm public documentation status:

- Public OpenAI docs establish Codex, tools, MCP, and Apps SDK context.
- Public OpenAI docs do not currently provide a complete Codex local-plugin install/uninstall lifecycle specification.
- Bundled local Codex plugin docs provide the concrete plugin/marketplace manifest requirements used by this audit.

### Install checks

```bash
scripts/install-local.sh --dry-run
scripts/install-local.sh
test -d "$HOME/plugins/agent-vision"
test -d "$HOME/.codex/plugins/cache/local/agent-vision/1.0.0"
python3 -m json.tool "$HOME/.agents/plugins/marketplace.json" >/dev/null
rg -n 'agent-vision|mcp_servers.agent_vision|plugins\."agent-vision@local"' "$HOME/.codex/config.toml"
codesign --verify --deep --strict "$HOME/.codex/plugins/cache/local/agent-vision/1.0.0/dist/AgentVision.app"
```

Verify installed MCP tools with JSON-RPC `tools/list` against:

```text
$HOME/.codex/plugins/cache/local/agent-vision/1.0.0/dist/agent-vision-mcp
```

Expected tools:

```text
agent_vision_snapshot
agent_vision_start
agent_vision_frame
agent_vision_stop
```

### Uninstall checks

```bash
scripts/uninstall-local.sh
test ! -e "$HOME/plugins/agent-vision"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.0.0"
python3 -m json.tool "$HOME/.agents/plugins/marketplace.json" >/dev/null
! rg -n 'agent-vision|codex-vision|mcp_servers.agent_vision|plugins\."agent-vision@local"' "$HOME/.codex/config.toml"
```

The marketplace may still contain unrelated plugins. The Codex config may still contain unrelated projects, model settings, app connectors, and MCP servers.

### Round-trip checks

```bash
scripts/uninstall-local.sh
scripts/install-local.sh
scripts/uninstall-local.sh
```

Then validate from the public repo URL:

```bash
tmp="$(mktemp -d /tmp/agent-vision-url-test.XXXXXX)"
git clone --depth 1 https://github.com/zfifteen/agent-vision.git "$tmp/agent-vision"
cd "$tmp/agent-vision"
scripts/install-local.sh --dry-run
scripts/install-local.sh
```

## User-Facing Confidence Summary

Agent Vision follows the bundled Codex plugin manifest and local marketplace specifications available in this Codex environment. The public OpenAI developer site confirms Codex, MCP, tools, and Apps SDK context, but does not currently publish a complete local Codex plugin lifecycle specification. Agent Vision therefore treats the bundled OpenAI `plugin-creator` spec as the controlling local plugin reference and documents the gap plainly.

The install path is deterministic and checks manifest structure, slash-command contracts, build success, app signing, MCP tool discovery, marketplace registration, plugin config registration, and Codex admission. The uninstall path is deterministic and removes Agent Vision files, marketplace entries, plugin config, MCP config, and legacy rebrand artifacts while preserving unrelated Codex state.
