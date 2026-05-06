# Agent Vision Issue Resolution Plan

Source issues: #3 through #13 in `zfifteen/codex-vision`, plus non-blocking issue #2.

## Dependency Rule

Resolve issues in blocker order. Do not start an issue until every listed dependency has been implemented and verified at the local acceptance level for that issue.

The rebrand has one invariant: all public release-facing names must consume the same Agent Vision contract. No pre-release compatibility aliases are required unless a later issue explicitly changes that decision.

## Phase 1: Naming Contract

1. Issue #3: Lock canonical Agent Vision naming contract
   - Blocks: #4, #5, #6, #7, #8, #9, #10, #11, #12, #13
   - Output: a tracked document recording the canonical values:
     - slug: `agent-vision`
     - display name: `Agent Vision`
     - slash command: `/agent-vision`
     - MCP server id: `agent-vision`
     - MCP tool prefix: `agent_vision_*`
     - wrapper script: `agent-vision-mcp`
     - bundle id: `works.velocity.agent-vision`
     - app bundle/display name: `AgentVision.app` / `Agent Vision`
     - GitHub URL: `https://github.com/zfifteen/agent-vision`
   - Local gate: the contract is precise enough that later changes do not invent names.

## Phase 2: Independent Core Renames

These issues depend only on #3 and can be addressed after the naming contract is committed to the repo.

2. Issue #4: Rename plugin discovery metadata
   - Depends on: #3
   - Blocks: #8, #10, #11, #13
   - Files: `.codex-plugin/plugin.json`
   - Local gate: `python3 -m json.tool .codex-plugin/plugin.json >/dev/null`

3. Issue #5: Rename MCP runtime surface
   - Depends on: #3
   - Blocks: #7, #8, #10, #11, #13
   - Files: `.mcp.json`, `Sources/*`, `Tests/*`
   - Local gate: `python3 -m json.tool .mcp.json >/dev/null` and `swift test`

4. Issue #6: Rename macOS app and Swift package identity
   - Depends on: #3
   - Blocks: #8, #10, #12, #13
   - Files: `Package.swift`, `Sources/*`, `Tests/*`, app plist references
   - Local gate: `swift test` and a release build

5. Issue #9: Regenerate public brand assets
   - Depends on: #3
   - Blocks: #10, #12, #13
   - Files: `assets/readme-hero.png`, `assets/logo.png`, `assets/composer-icon.png`
   - Local gate: asset dimensions remain 1600x900, 1024x1024, and 256x256, and docs/metadata references resolve.

## Phase 3: Surfaces That Consume Runtime And Metadata

6. Issue #7: Rename slash command and skill instructions
   - Depends on: #3, #5
   - Blocks: #10, #13
   - Files: `commands/agent-vision.md`, `skills/camera-control/SKILL.md`
   - Local gate: no bundled command or skill references `/codex-vision` or `codex_vision_*`.

7. Issue #8: Rename installer and local marketplace flow
   - Depends on: #3, #4, #5, #6
   - Blocks: #11, #12, #13
   - Files: `scripts/install-local.sh`
   - Local gate: `scripts/install-local.sh --dry-run`

## Phase 4: Validation And Public Documentation

8. Issue #11: Update CI and validation assertions
   - Depends on: #4, #5, #8
   - Blocks: #13
   - Files: `.github/workflows/ci.yml`
   - Local gate: CI assertions require `agent-vision` plugin and MCP ids.

9. Issue #10: Update public documentation
   - Depends on: #3, #4, #5, #6, #7, #9
   - Blocks: #12, #13
   - Files: `README.md`, `INSTALL.md`, `CODEX_INSTALL.md`, `PRIVACY.md`
   - Local gate: docs use implemented Agent Vision command, tool names, app name, install paths, and URLs.

## Phase 5: Release Output

10. Issue #12: Regenerate or remove stale release artifacts
    - Depends on: #3, #4, #5, #6, #7, #8, #9, #10
    - Blocks: #13
    - Files: `scripts/package-release.sh`, `release/*`
    - Local gate: release packaging emits `agent-vision` artifacts or stale `release/codex-vision-1.0.0*` artifacts are removed.

## Phase 6: Final Verification

11. Issue #13: Run final rebrand verification
    - Depends on: #3, #4, #5, #6, #7, #8, #9, #10, #11, #12
    - Blocks: none
    - Required checks:

```sh
git ls-files | xargs rg -n "Codex Vision|codex-vision|CodexVision|codex_vision|/codex-vision"
find release -type f -maxdepth 4 -print | sort | xargs rg -n "Codex Vision|codex-vision|CodexVision|codex_vision|/codex-vision"
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
swift test
scripts/install-local.sh --dry-run
```

Document any remaining `Codex` references as acceptable only when they refer to the host agent/app generically, not the plugin brand.

## Non-Blocking Follow-Up

12. Issue #2: Consider listing in awesome-codex-plugins
    - Depends on: release-ready Agent Vision naming if it is pursued.
    - Blocks: none
    - Treatment: do not mix this with the rebrand implementation. Revisit after #13 passes.
