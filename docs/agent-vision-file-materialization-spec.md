# Agent Vision File Materialization Specification

## Status

**Active.** File materialization is the normal Agent Vision image-access path for all public hosts.

| Host | Materialize | Vision / display ingest |
| --- | --- | --- |
| Codex (1.5.0) | `agent-vision-capture-file` → `~/.codex/agent-vision/frames` | Markdown image link; roast/mood use `codex exec -i` |
| Grok Build | `agent-vision-capture-file` → `~/.agent-vision/frames` | Multimodal `read_file` on the absolute path; Markdown for snapshot/roast; mood silent |

The tested Codex path does not make MCP image content directly available to the assistant as inspectable vision input. Production Grok and Codex user contracts therefore **must not** depend on MCP image payloads in memory.

## Root cause (historical)

The original design assumed:

```text
slash command -> MCP image content -> assistant vision inspection
```

The working multi-host chain is:

```text
slash command
  -> agent-vision-capture-file
  -> JPEG file on disk
  -> host-specific ingest (Markdown / read_file / codex exec -i)
```

## Runtime contract

`agent-vision-capture-file` is the public local helper for one-shot image materialization.

### Invocation (preferred)

PATH shim (after `scripts/install-runtime.sh`):

```bash
agent-vision-capture-file --output "$OUTPUT" --json
```

Absolute default runtime home:

```bash
"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

Codex 1.5.0 package:

```bash
"$HOME/.codex/plugins/cache/local/agent-vision/1.5.0/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

(`1.0.2` cache paths in older docs are historical only.)

### Requirements

- `$OUTPUT` must be an absolute path.
- `$OUTPUT` must not already exist.
- The helper must write exactly one JPEG file.
- The helper must print JSON with `ok: true`, `path`, `mimeType`, `width`, `height`, `bytes`, and `timestamp` (optional: `meanBrightness`).
- On failure: explicit JSON error codes; never screenshots, existing photos, alternate camera APIs, or silent degradation.
- Helper resolves `AgentVision.app` relative to its install layout (`…/dist/AgentVision.app`) and launches capture via Launch Services.

## Host slash behavior

### Snapshot (both hosts)

1. Create the host frame directory.
2. Choose an absolute output path inside it.
3. Run `agent-vision-capture-file --output "$OUTPUT" --json`.
4. Verify `ok: true` and that `path` exists.
5. **Codex:** display Markdown image link.  
   **Grok:** `read_file` on the path, then Markdown image link + analysis.

### Roast / mood (Codex only in current public cut)

Materialize JPEG, then analyze with the host vision path: Codex uses `codex exec -i`; Grok uses multimodal `read_file` on the absolute path with the same roast/mood prompts and gates.

### Streaming

Disabled on both public hosts. Fixed user-visible copy; **no** Agent Vision process.

## Process lifecycle

One-shot capture launches `AgentVision.app` only for that request and must exit afterward. Install and idle host sessions must not start the app or helper.

Production installs do **not** register an Agent Vision MCP server. Source-tree MCP code remains for tests/dev only.

## Validation

```bash
bash -n scripts/agent-vision-capture-file.sh scripts/install-runtime.sh scripts/install-grok.sh
scripts/test-grok-adapter.sh
scripts/test-capture-file-cli.sh
# optional live:
AGENT_VISION_LIVE=1 scripts/test-capture-file-cli.sh
swift test
# Codex package path (when installed):
# scripts/install-local.sh --dry-run
# scripts/test-slash-commands.sh
```

See also:

- [agent-vision-grok-build-compatibility.md](./agent-vision-grok-build-compatibility.md)
- [agent-vision-grok-install-uninstall-traceability.md](./agent-vision-grok-install-uninstall-traceability.md)
- [agent-vision-install-uninstall-traceability.md](./agent-vision-install-uninstall-traceability.md)
