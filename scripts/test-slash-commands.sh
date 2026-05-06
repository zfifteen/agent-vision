#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

command -v codex >/dev/null || { echo "codex CLI is required." >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

run_case() {
  local name="$1"
  local prompt="$2"
  local expected_tool="$3"
  local log
  log="$(mktemp "${TMPDIR:-/tmp}/agent-vision-${name}.XXXXXX.jsonl")"

  codex exec \
    --json \
    --ephemeral \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$ROOT" \
    "$prompt" >"$log"
  local codex_status=$?
  if [[ "$codex_status" -ne 0 ]]; then
    echo "$name: codex exec exited $codex_status" >&2
    rm -f "$log"
    return 1
  fi

  python3 - "$log" "$name" "$expected_tool" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
name = sys.argv[2]
expected_tool = sys.argv[3]

events = []
for line in path.read_text(encoding="utf-8").splitlines():
    if line.startswith("{"):
        events.append(json.loads(line))

tool_results = []
final_messages = []
for event in events:
    if event.get("type") != "item.completed":
        continue
    item = event.get("item") or {}
    if item.get("type") == "mcp_tool_call":
        tool_results.append(item)
    elif item.get("type") == "agent_message":
        final_messages.append(item.get("text") or "")

matches = [item for item in tool_results if item.get("tool") == expected_tool]
if not matches:
    actual = ", ".join(item.get("tool", "<missing>") for item in tool_results) or "<none>"
    raise SystemExit(f"{name}: expected MCP tool {expected_tool}, observed {actual}")

for item in matches:
    if item.get("error"):
        raise SystemExit(f"{name}: MCP tool {expected_tool} errored: {item['error']}")

if expected_tool in {"agent_vision_snapshot", "agent_vision_frame"}:
    result = matches[-1].get("result") or {}
    content = result.get("content") or []
    has_image = any(part.get("type") == "image" and part.get("data") for part in content)
    if not has_image:
        raise SystemExit(f"{name}: MCP result did not contain image content")

final_text = "\n".join(final_messages).lower()
failure_terms = [
    "metadata only",
    "tool contract failure",
    "no grounded roast possible",
    "not image content i can inspect",
]
for term in failure_terms:
    if term in final_text:
        raise SystemExit(f"{name}: agent reported image contract failure: {term}")

print(f"{name}: {expected_tool} passed")
PY
  local check_status=$?

  rm -f "$log"
  return "$check_status"
}

check_no_agent_vision_processes() {
  local leaked
  leaked="$(ps -axo pid=,ppid=,stat=,command= | awk '/AgentVision|agent-vision-mcp/ && !/awk/ {print}')"
  if [[ -n "$leaked" ]]; then
    echo "process-leak: Agent Vision processes remained after slash command matrix:" >&2
    echo "$leaked" >&2
    return 1
  fi
}

failures=0

run_case "snapshot" "/agent-vision snapshot" "agent_vision_snapshot" || failures=$((failures + 1))
run_case "streaming" "/agent-vision streaming" "agent_vision_start" || failures=$((failures + 1))
run_case "roast" "/agent-vision roast" "agent_vision_snapshot" || failures=$((failures + 1))
check_no_agent_vision_processes || failures=$((failures + 1))

if [[ "$failures" -ne 0 ]]; then
  echo "agent-vision slash command matrix failed: $failures case(s)" >&2
  exit 1
fi

echo "agent-vision slash command matrix passed"
