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
| Plugin has required manifest at `.codex-plugin/plugin.json`. | Bundled `plugin-creator/SKILL.md`: keep `.codex-plugin/plugin.json` present. | `.codex-plugin/plugin.json` exists in repo, staged plugin, and cache. | Packaged `install.sh` copies `.codex-plugin` to `~/plugins/agent-vision` and cache. | Packaged `uninstall.sh` removes staged plugin and cache. | Packaged `install.sh` parses the JSON manifests with the system JavaScript runtime; verify installed/cached copies exist after install and do not exist after uninstall. | Mapped | Manifest remains source of plugin identity. |
| Plugin name is normalized and matches folder/plugin identity. | Bundled `plugin-creator/SKILL.md`: generated folder and plugin.json name are the same; name is lower-case hyphen-case. | Plugin name is `agent-vision`; staged path is `~/plugins/agent-vision`. | Installer validates `plugin.json` name equals `agent-vision`. | Uninstaller removes current and legacy `codex-vision` identities. | Run installer dry-run and inspect `~/.agents/plugins/marketplace.json`. | Mapped | Legacy cleanup is included because this plugin was renamed. |
| Manifest includes metadata and interface fields for user presentation. | Bundled `plugin-json-spec.md`: field guide for `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, and `interface`. | `.codex-plugin/plugin.json` defines all required presentation metadata, icons, logo, screenshots, prompts, URLs, and capabilities. | Installer copies manifest and assets to plugin home/cache. | Uninstaller removes plugin home/cache containing manifest/assets. | Parse manifest JSON and verify referenced assets exist. | Mapped | `defaultPrompt` has three entries, matching spec guidance. |
| Plugin paths are relative to plugin root. | Bundled `plugin-json-spec.md`: path values should be relative and begin with `./`; screenshots under `./assets/`. | `skills`, `mcpServers`, icon, logo, and screenshot paths are relative. | Installer copies all referenced directories/files into plugin home/cache. | Uninstaller removes staged copies. | Parse manifest and verify `./skills/`, `./.mcp.json`, and assets exist in repo and cache. | Mapped | Relative `.mcp.json` is also preserved for package portability. |
| Plugin may provide skills. | Bundled `plugin-json-spec.md`: `skills` field points to skill directories/files. | `skills/camera-control/SKILL.md` defines camera workflow and guardrails. | Packaged installer copies `skills` to plugin home/cache. | Packaged uninstaller removes plugin home/cache and plugin config. | Open a new Codex session after install and inspect the generated Agent Vision skill entry. | Mapped | Skill is the human workflow contract. |
| Plugin may provide MCP servers. | Bundled `plugin-json-spec.md`: `mcpServers` field points to MCP config path. Public OpenAI docs identify MCP as a supported tool surface. | `.mcp.json` defines `agent-vision` server with `./dist/agent-vision-mcp`. | Installer copies `.mcp.json`, stages wrapper, and removes legacy duplicate `mcp_servers.agent_vision` config. | Uninstaller removes legacy MCP sections. | Installed MCP `tools/list` must return five Agent Vision tools. | Mapped | Plugin MCP discovery is the single active registration path. |
| Home-local marketplace uses `~/.agents/plugins/marketplace.json` and `./plugins/<plugin-name>`. | Bundled `plugin-creator/SKILL.md` and `plugin-json-spec.md`: home-local marketplace convention. | Installer writes `~/.agents/plugins/marketplace.json` entry with `source.path = ./plugins/agent-vision`. | Installer creates or updates local marketplace with `agent-vision`. | Uninstaller removes only `agent-vision` and legacy `codex-vision` entries. | Parse marketplace JSON before/after install/uninstall; unrelated entries must remain. | Mapped | Installer intentionally uses `INSTALLED_BY_DEFAULT` for this local plugin. |
| Marketplace entry includes installation policy, authentication policy, and category. | Bundled `plugin-creator/SKILL.md`: every entry includes `policy.installation`, `policy.authentication`, and `category`. | Installer writes all three fields. | Uninstaller removes only matching plugin entries. | Inspect `~/.agents/plugins/marketplace.json` after install. | Mapped | `authentication = ON_INSTALL` matches the bundled default. |
| Codex plugin config enables local plugin. | Bundled local workflow plus observed Codex config behavior. | Installer writes `[plugins."agent-vision@local"] enabled = true`. | Uninstaller removes current and legacy plugin sections. | Inspect `~/.codex/config.toml` after install/uninstall. | Mapped | This is bundled/local behavior, not a public OpenAI web spec. |
| Codex MCP config avoids duplicate Agent Vision tool registration. | Public OpenAI docs establish MCP as a tool capability; local Codex config also supports `[mcp_servers.*]`. | Installer removes legacy `[mcp_servers.agent_vision]` sections instead of writing them. | Uninstaller removes current and legacy MCP sections. | Inspect `~/.codex/config.toml`; open a new Codex session to load plugin-provided `agent_vision_*` tools. | Mapped | A new Codex session is required for tool registry reload. |
| Slash command has metadata and contracts for all public modes. | Bundled plugin examples use `commands/`; local command convention uses YAML frontmatter. | `commands/agent-vision.md` has `description`, `argument-hint`, and instructions for `/agent-vision snapshot`, `/agent-vision streaming`, `/agent-vision roast`, and `/agent-vision mood`. | Developer packaging validates command frontmatter and required snippets before release. | Uninstaller removes command copies with plugin home/cache. | Static check for required snippets; command copies present after install. | Mapped | Roast maps to snapshot plus prose; mood maps to a private assistant-only frame plus delivery calibration. |
| MCP server exposes expected tools. | Public OpenAI docs establish MCP/tool context; Agent Vision `.mcp.json` and server tests specify concrete names. | `AgentVisionCore.MCPServer` exposes five tools. | Developer packaging builds the wrapper and Swift tests verify the server tools. | Uninstall removes wrapper and MCP config. | Probe `tools/list` for `agent_vision_snapshot`, `agent_vision_mood`, `agent_vision_start`, `agent_vision_frame`, `agent_vision_stop`. | Mapped | This is the core runtime install invariant. |
| macOS camera permission attaches to stable app identity. | macOS platform behavior; Agent Vision privacy/install docs. | Signed `AgentVision.app` uses bundle id `works.velocity.agent-vision` and `NSCameraUsageDescription`. | Packaged installer verifies the shipped app signature without signing locally. | Uninstaller removes staged/cached app bundle. | `plutil -lint`; `codesign --verify --deep --strict`; inspect `Info.plist`. | Mapped | Public OpenAI docs do not define macOS camera permission behavior. |
| Codex installs from the repo URL through the package. | User-facing install contract. | `CODEX_INSTALL.md`, `README.md`, and `INSTALL.md` tell Codex to use the repository releases package, not the source installer. | Codex downloads `agent-vision-1.0.2.tar.gz`, extracts it, and runs package `install.sh`. | Packaged `uninstall.sh` removes the package install. | Review docs for the repo URL prompt and absence of `scripts/install-local.sh` from user install instructions. | Mapped | A repo URL is the entrypoint; the release archive is the artifact Codex installs. |
| Normal install has no developer-tool dependency. | User-facing install contract. | Release archive includes signed `dist/AgentVision.app`, `dist/agent-vision-mcp`, `dist/agent-vision-capture-file`, `install.sh`, and `uninstall.sh`. | `install.sh` requires macOS, Codex CLI, and system `osascript`; it does not call `swift`, `xcodebuild`, `python3`, `security find-identity`, or `codesign --sign`. | `uninstall.sh` uses system shell, `osascript`, and `awk`; it does not call developer tools. | `bash -n scripts/install-packaged.sh scripts/uninstall-packaged.sh`; inspect scripts for forbidden commands. | Mapped | Developer tools remain confined to source install and release packaging. |
| Uninstall is deterministic and preserves unrelated state. | QA requirement from this audit. | Packaged `uninstall.sh` removes Agent Vision files/config only. | Not applicable. | Uninstaller removes plugin home/cache, marketplace entry, and config sections. | Install, snapshot config, uninstall, compare unrelated marketplace/config entries. | Mapped | Packaged uninstall is the normal-user lifecycle path. |
| Legacy rebrand artifacts are cleaned. | Agent Vision rebrand history and installer cleanup. | Current and legacy `codex-vision` paths/sections are listed in install and uninstall cleanup. | Installer removes old rebrand cache/temp/plugin paths. | Uninstaller removes old rebrand cache/temp/plugin paths and config sections. | Verify no `codex-vision` plugin/cache/temp/config sections remain. | Mapped | Prevents collisions between old and current plugin identities. |
| User-facing install evidence is documented. | User QA requirement for confidence evidence. | README, INSTALL, CODEX_INSTALL, and this matrix document expected behavior. | Installer output lists installed paths and usage. | Uninstall script output states removal. | Review docs and run lifecycle checklist. | Mapped | Matrix should be updated when install behavior changes. |

## Lifecycle QA Checklist

### Documentation/source checks

```bash
test -f /Users/velocityworks/.codex/skills/.system/plugin-creator/SKILL.md
test -f /Users/velocityworks/.codex/skills/.system/plugin-creator/references/plugin-json-spec.md
bash -n scripts/install-packaged.sh scripts/uninstall-packaged.sh scripts/agent-vision-capture-file.sh
```

Confirm public documentation status:

- Public OpenAI docs establish Codex, tools, MCP, and Apps SDK context.
- Public OpenAI docs do not currently provide a complete Codex local-plugin install/uninstall lifecycle specification.
- Bundled local Codex plugin docs provide the concrete plugin/marketplace manifest requirements used by this audit.

### Install checks

```bash
curl -L -o agent-vision-1.0.2.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.0.2/agent-vision-1.0.2.tar.gz
tar -xzf agent-vision-1.0.2.tar.gz
cd agent-vision-1.0.2
./install.sh
test -d "$HOME/plugins/agent-vision"
test -d "$HOME/.codex/plugins/cache/local/agent-vision/1.0.2"
test -f "$HOME/.agents/plugins/marketplace.json"
rg -n 'agent-vision|plugins\."agent-vision@local"' "$HOME/.codex/config.toml"
! rg -n 'mcp_servers.agent_vision' "$HOME/.codex/config.toml"
codesign --verify --deep --strict "$HOME/.codex/plugins/cache/local/agent-vision/1.0.2/dist/AgentVision.app"
```

Verify installed MCP tools with JSON-RPC `tools/list` against:

```text
$HOME/.codex/plugins/cache/local/agent-vision/1.0.2/dist/agent-vision-mcp
```

Expected tools:

```text
agent_vision_snapshot
agent_vision_mood
agent_vision_start
agent_vision_frame
agent_vision_stop
```

### Uninstall checks

```bash
./uninstall.sh
test ! -e "$HOME/plugins/agent-vision"
test ! -e "$HOME/.codex/plugins/cache/local/agent-vision/1.0.2"
test -f "$HOME/.agents/plugins/marketplace.json"
! rg -n 'agent-vision|codex-vision|mcp_servers.agent_vision|plugins\."agent-vision@local"' "$HOME/.codex/config.toml"
```

The marketplace may still contain unrelated plugins. The Codex config may still contain unrelated projects, model settings, app connectors, and MCP servers.

### Round-trip checks

```bash
./uninstall.sh
./install.sh
./uninstall.sh
```

Then validate from the public repo URL:

```bash
curl -L -o agent-vision-1.0.2.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.0.2/agent-vision-1.0.2.tar.gz
tar -xzf agent-vision-1.0.2.tar.gz
cd agent-vision-1.0.2
./install.sh
```

## User-Facing Confidence Summary

Agent Vision follows the bundled Codex plugin manifest and local marketplace specifications available in this Codex environment. The public OpenAI developer site confirms Codex, MCP, tools, and Apps SDK context, but does not currently publish a complete local Codex plugin lifecycle specification. Agent Vision therefore treats the bundled OpenAI `plugin-creator` spec as the controlling local plugin reference and documents the gap plainly.

The normal Codex install path starts with the repository URL, downloads the packaged release archive, and runs the package installer. The install path checks manifest structure, packaged artifacts, app signature, marketplace registration, and plugin config registration. The uninstall path is deterministic and removes Agent Vision files, marketplace entries, plugin config, MCP config, and legacy rebrand artifacts while preserving unrelated Codex state.
