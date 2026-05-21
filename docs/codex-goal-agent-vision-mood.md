# Goal: Implement Agent Vision Mood

Implement Agent Vision Mood in a new branch and create a detailed PR.

## Branch

Use branch: `codex/agent-vision-mood`

Preserve existing local work. Do not revert unrelated changes.

## Read First

- `docs/agent-vision-mood-technical-note.md`
- `docs/agent-vision-mood-validation-collateral.md`
- `docs/agent-vision-file-materialization-spec.md`
- `commands/agent-vision.md`
- `skills/camera-control/SKILL.md`
- `Sources/AgentVisionCore/MCPServer.swift`
- `Tests/AgentVisionTests/MCPServerTests.swift`
- `scripts/install-local.sh`

## Feature Contract

Implement `/agent-vision mood` and MCP tool `agent_vision_mood`.

Mood obtains a consented camera image, estimates current interaction state, and calibrates Codex response delivery only: pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior.

Mood must not change factual standards, permissions, approval/sandbox behavior, user intent, or task scope. Mood context is ephemeral: current response or current task phase only. User correction overrides the visual estimate.

## Architecture

The repo currently uses file-materialized image input for snapshot and roast. Reconcile Mood with that existing design.

Add `agent_vision_mood` to the MCP server, but do not pretend the Swift MCP server can perform semantic mood inference unless a real deterministic local inference path is implemented. Prefer the proven file-backed image-input pattern for visual analysis.

## Implementation

- Add `agent_vision_mood` to `tools/list`.
- Reuse existing snapshot lifecycle and camera cleanup.
- Preserve streaming behavior.
- Add `mood` to `/agent-vision` argument handling and frontmatter.
- For `/agent-vision mood`, materialize a JPEG under `$HOME/.codex/agent-vision/frames`.
- Run image analysis with `codex exec --ephemeral --skip-git-repo-check -i "$OUTPUT"` if that remains the repo's proven image-input path.
- Require strict JSON fields: `presence`, `interaction_state`, `confidence`, `observable_basis`, `assistant_adjustments`.
- Apply confidence gates from the technical note.
- Update skill, docs, installer validation snippets, and slash-command tests as needed.
- Mood must add no new raw-image persistence, mood history, training dataset, background recording, or separate image archive.

## Tests

Run:

```bash
swift test
scripts/install-local.sh --dry-run
scripts/test-slash-commands.sh
python3 -m json.tool .codex-plugin/plugin.json >/dev/null
python3 -m json.tool .mcp.json >/dev/null
```

If a validation command cannot run, report the exact blocker.

## PR

Commit changes, push branch, and create a detailed PR.

PR body must include:

- Summary
- User-facing behavior
- MCP/tool changes
- Slash command and skill changes
- Data handling
- Tests run with results
- Known limits or follow-up work

Before finishing, show:

- `git status --short`
- final branch name
- PR URL, if created
