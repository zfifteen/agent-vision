# Phase 0 evidence: Grok vision ingest via `read_file`

**Date:** 2026-07-13  
**Host:** Grok Build CLI (this session)  
**Sandbox:** off (default)  
**Decision:** **Primary vision ingest = multimodal `read_file` on absolute JPEG path after capture `ok: true`.**

## Procedure

1. Installed runtime: `scripts/install-runtime.sh` → `~/.local/share/agent-vision`
2. Codesign verified on installed app
3. Live capture: `AGENT_VISION_LIVE=1 ./scripts/test-capture-file-cli.sh`
4. Result JSON included `ok: true`, `width: 1920`, `height: 1080`, non-trivial `bytes` and `meanBrightness`
5. In-session `read_file` on the absolute path under `~/.agent-vision/frames/`

## Pass rubric (controlled-scene style)

Capture was a live desk/user camera frame (not a synthetic black image). The model, via `read_file`, reported concrete visible content consistent with the JPEG (person, interior ceiling/wall, clothing color) rather than metadata-only fields (`path`, `mimeType`, dimensions alone).

**T-0.2 outcome:** **PASS** — real pixel access confirmed for Grok Build multimodal `read_file`.

## Residual process

Post-capture `pgrep` for Agent Vision capture/MCP patterns should show no residual helper (validated separately after install/live run).

## Artifacts

- Frame file kept only on local disk under `~/.agent-vision/frames/` (not committed to git).
- No private image bytes in this repository.

## Phase 0b (sandbox)

Ship A policy remains: **sandbox off only**. Restricted profiles not claimed supported; fail closed if capture cannot write frames or launch the app.

## Follow-on

Ship A skill may use `read_file` after capture. Roast/mood remain Milestone 2.
