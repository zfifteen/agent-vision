# Agent Vision Rebrand Issues

Source audit: `docs/agent-vision-rebrand-audit.md`

This document stages GitHub issues for the Agent Vision rebrand. It records dependency order and release blockers; the audit report remains the detailed evidence source.

## Dependency Summary

- `I1` is the root naming contract.
- Runtime/API, app/package identity, and asset work can proceed after `I1`.
- Installer, CI, docs, and release packaging depend on completed runtime/app/config naming.
- Final validation depends on every release-blocking issue.

## Issues

### Issue 1: Lock Canonical Agent Vision Naming Contract

- `Action`: Record the final slug, display name, slash command, MCP server id, MCP tool prefix, wrapper script name, bundle id, app name, and GitHub URL.
- `Depends on`: None
- `Blocks`: 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
- `Audit reference`: Rename Defaults
- `Release blocking`: Yes

### Issue 2: Rename Plugin Discovery Metadata

- `Action`: Update public plugin metadata and prompt examples to Agent Vision values.
- `Depends on`: 1
- `Blocks`: 6, 8, 9, 10, 11
- `Audit reference`: Plugin discovery metadata
- `Release blocking`: Yes

### Issue 3: Rename MCP Runtime Surface

- `Action`: Update MCP server id, tool names, tool descriptions, user-visible MCP responses, and test expectations.
- `Depends on`: 1
- `Blocks`: 5, 6, 8, 9, 10, 11
- `Audit reference`: MCP runtime API; MCP server configuration
- `Release blocking`: Yes

### Issue 4: Rename macOS App And Swift Package Identity

- `Action`: Update app bundle/display identity and decide the minimum Swift package/product rename needed to prevent public leakage.
- `Depends on`: 1
- `Blocks`: 6, 8, 9, 10, 11
- `Audit reference`: macOS app identity; Swift package/product/module/test names
- `Release blocking`: Yes

### Issue 5: Rename Slash Command And Skill Instructions

- `Action`: Rename `/codex-vision` to `/agent-vision` and update command/skill tool references.
- `Depends on`: 1, 3
- `Blocks`: 8, 10, 11
- `Audit reference`: Slash command; Skill instructions
- `Release blocking`: Yes

### Issue 6: Rename Installer And Local Marketplace Flow

- `Action`: Update install paths, cache paths, local marketplace registration, config sections, dry-run checks, app bundle references, wrapper script references, and admission-check text.
- `Depends on`: 1, 2, 3, 4
- `Blocks`: 9, 10, 11
- `Audit reference`: Installer and local marketplace registration
- `Release blocking`: Yes

### Issue 7: Regenerate Public Brand Assets

- `Action`: Replace hero, logo, and composer icon with Agent Vision assets at existing dimensions.
- `Depends on`: 1
- `Blocks`: 8, 10, 11
- `Audit reference`: Brand assets
- `Release blocking`: Yes

### Issue 8: Update Public Documentation

- `Action`: Update README, install docs, privacy doc, diagrams, examples, URLs, and user-facing prose after names and assets are settled.
- `Depends on`: 1, 2, 3, 4, 5, 7
- `Blocks`: 10, 11
- `Audit reference`: Public docs
- `Release blocking`: Yes

### Issue 9: Update CI And Validation Assertions

- `Action`: Update manifest assertions and validation commands to Agent Vision identifiers.
- `Depends on`: 2, 3, 6
- `Blocks`: 11
- `Audit reference`: CI manifest assertions
- `Release blocking`: Yes

### Issue 10: Regenerate Or Remove Stale Release Artifacts

- `Action`: Remove or regenerate `release/codex-vision-1.0.0*` so distributed contents reflect Agent Vision.
- `Depends on`: 2, 3, 4, 5, 6, 7, 8
- `Blocks`: 11
- `Audit reference`: Release packaging; Generated Release Output
- `Release blocking`: Yes

### Issue 11: Run Final Rebrand Verification

- `Action`: Run targeted old-name searches, JSON validation, Swift tests, and installer dry-run; record remaining acceptable `Codex` host-app references if any.
- `Depends on`: 2, 3, 4, 5, 6, 7, 8, 9, 10
- `Blocks`: None
- `Audit reference`: Verification Commands For Implementation Pass
- `Release blocking`: Yes
