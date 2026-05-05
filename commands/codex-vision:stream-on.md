# /codex-vision:stream-on

Start a persistent Codex Vision camera session.

## Preflight

Use this command only when the user intentionally enables streaming mode.

## Plan

Call one MCP tool:

1. `codex_vision_start`

After this succeeds, streaming mode is active. Codex may call `codex_vision_frame` when visual context would help, without asking the user for each individual frame, until streaming mode is stopped.

## Commands

Call `codex_vision_start`.

## Verification

Confirm that the tool returned `isError: false`. If the tool returns an error, report that exact error.

## Response

Tell the user that streaming mode is on and that Codex can pull frames as needed until `/codex-vision:stream-off`.
