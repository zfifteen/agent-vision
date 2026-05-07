# Agent Vision File Materialization Specification

## Status

File materialization is the normal Agent Vision image-access path for `/agent-vision snapshot` and `/agent-vision roast`.

The tested Codex path does not make MCP image content directly available to the assistant as inspectable vision input. The MCP result can contain base64 JPEG image content, but the user-visible slash command contract must not depend on the assistant inspecting that MCP payload in memory.

## Root Cause

The original slash command design assumed this chain:

```text
slash command -> MCP image content -> assistant vision inspection
```

The working chain is:

```text
slash command -> MCP snapshot call -> JPEG file on disk -> Markdown image link or codex exec -i
```

The plugin already has a signed native app that owns camera permission and returns JPEG bytes through MCP. A new camera binary is not required for the current contract. The missing piece is a deterministic file materializer that turns the MCP image result into a local JPEG file and reports explicit JSON.

## Runtime Contract

`dist/agent-vision-capture-file` is the public local helper for one-shot image materialization.

Invocation:

```bash
"$HOME/.codex/plugins/cache/local/agent-vision/1.0.1/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

Requirements:

- `$OUTPUT` must be an absolute path.
- `$OUTPUT` must not already exist.
- The helper must write exactly one JPEG file.
- The helper must print JSON with `ok: true`, `path`, `mimeType`, `width`, `height`, `bytes`, and `timestamp`.
- The helper must fail with explicit JSON on invalid arguments, missing wrapper, timeout, capture failure, missing image content, base64 decode failure, invalid JPEG bytes, or existing output.
- The helper must not use screenshots, existing files, alternate camera APIs, retries through another path, or silent degradation.

## Slash Command Behavior

`/agent-vision snapshot`:

1. Create `$HOME/.codex/agent-vision/frames`.
2. Choose an absolute output path inside that directory.
3. Run `agent-vision-capture-file --output "$OUTPUT" --json`.
4. Verify `ok: true` and that `path` exists.
5. Display the saved JPEG with an absolute Markdown image link.

`/agent-vision roast`:

1. Materialize a JPEG with the same file helper.
2. Run:

   ```bash
   codex exec --ephemeral -i "$OUTPUT" -- "Write exactly one playful roast of 400 characters or fewer based only on visible non-sensitive details in the attached image. Do not infer or attack protected traits, body size, age, disability, or other sensitive attributes."
   ```

3. Return the saved image link and the roast text from that image-input pass.

`/agent-vision streaming` remains an MCP streaming-mode command and calls `agent_vision_start`.

## Process Lifecycle

The MCP wrapper launches `AgentVision.app` in FIFO mode. Cleanup must terminate the FIFO output process and the launched app process before the wrapper exits.

The file materializer must close wrapper stdin after writing the complete JSON-RPC request batch. That lets the wrapper and app exit normally after the snapshot response. If the wrapper does not exit, the materializer terminates it; the wrapper cleanup is responsible for terminating the app.

## Validation

Required local checks:

```bash
bash -n scripts/agent-vision-mcp.sh scripts/agent-vision-capture-file.sh scripts/install-local.sh scripts/package-release.sh scripts/test-slash-commands.sh
./scripts/install-local.sh --dry-run
swift test
./scripts/install-local.sh
./scripts/test-slash-commands.sh
./scripts/test-streaming-interaction.sh
```

The slash-command matrix must fail if:

- Snapshot does not run the file materializer.
- Snapshot does not produce a saved JPEG.
- Streaming does not call `agent_vision_start`.
- Roast does not run the file materializer.
- Roast does not run a separate `codex exec -i` image-input pass.
- Any Agent Vision process remains after the matrix completes.
- File-backed snapshot cannot materialize a JPEG while streaming mode is active.
- Streaming mode cannot still return `agent_vision_frame` image content after a file-backed snapshot.

Repository or workspace preflight commands are reported as warnings by the matrix. They are not part of the image contract, but they remain visible so dispatch ambiguity is not hidden.
