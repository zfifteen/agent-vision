#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

command -v codex >/dev/null || { echo "codex CLI is required." >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

baseline_agent_vision_pids="$(ps -axo pid=,command= | awk '/AgentVision|agent-vision-mcp/ && !/awk/ {print $1}' | paste -sd, -)"

run_case() {
  local name="$1"
  local prompt="$2"
  local expected_contract="$3"
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

  python3 - "$log" "$name" "$expected_contract" <<'PY'
import json
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
name = sys.argv[2]
expected_contract = sys.argv[3]

events = []
for line in path.read_text(encoding="utf-8").splitlines():
    if line.startswith("{"):
        events.append(json.loads(line))

tool_results = []
command_results = []
final_messages = []
for event in events:
    if event.get("type") != "item.completed":
        continue
    item = event.get("item") or {}
    if item.get("type") == "mcp_tool_call":
        tool_results.append(item)
    elif item.get("type") == "command_execution":
        command_results.append(item)
    elif item.get("type") == "agent_message":
        final_messages.append(item.get("text") or "")

created_paths = set()
jpg_pattern = re.compile(r"/Users/[^)\s\"']+\.jpg")
for item in command_results:
    created_paths.update(jpg_pattern.findall(item.get("command") or ""))
    created_paths.update(jpg_pattern.findall(item.get("aggregated_output") or ""))
for message in final_messages:
    created_paths.update(jpg_pattern.findall(message))

def capture_json_results():
    results = []
    for item in command_results:
        output = item.get("aggregated_output") or ""
        for line in output.splitlines():
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue
            if data.get("ok") is True and data.get("path"):
                results.append(data)
    return results

def assert_no_failure_terms():
    final_text = "\n".join(final_messages).lower()
    failure_terms = [
        "metadata only",
        "tool contract failure",
        "no grounded roast possible",
        "not image content i can inspect",
        "roast from metadata",
        "roast from markdown",
    ]
    for term in failure_terms:
        if term in final_text:
            raise SystemExit(f"{name}: agent reported image contract failure: {term}")

def warn_repository_detour():
    blocked_fragments = [
        "rg --files",
        "git status",
        "README.md",
        "Package.swift",
        "find .. -name AGENTS.md",
        "Sources/AgentVisionCore",
    ]
    for item in command_results:
        command = item.get("command") or ""
        for fragment in blocked_fragments:
            if fragment in command:
                print(f"{name}: warning: camera command detoured into repository inspection: {command}", file=sys.stderr)
                return

def assert_capture_file():
    capture_commands = [
        item for item in command_results
        if "agent-vision-capture-file" in (item.get("command") or "")
    ]
    if not capture_commands:
        observed = "\n".join(item.get("command") or "<missing>" for item in command_results) or "<none>"
        raise SystemExit(f"{name}: expected agent-vision-capture-file command, observed {observed}")

    captures = capture_json_results()
    if not captures:
        raise SystemExit(f"{name}: expected capture JSON with ok=true and path")

    for capture in captures:
        frame = pathlib.Path(capture["path"])
        if not frame.exists():
            raise SystemExit(f"{name}: captured frame path does not exist: {frame}")
        if capture.get("mimeType") != "image/jpeg":
            raise SystemExit(f"{name}: expected image/jpeg, observed {capture.get('mimeType')}")
        if (capture.get("bytes") or 0) <= 0:
            raise SystemExit(f"{name}: captured frame byte count was not positive")
    return captures

def assert_markdown_image():
    final_text = "\n".join(final_messages)
    if "![" not in final_text or ".jpg" not in final_text:
        raise SystemExit(f"{name}: final response did not include a Markdown JPEG image link")

def assert_mood_is_internal():
    final_text = "\n".join(final_messages)
    lower = final_text.lower()
    forbidden_fragments = [
        "![",
        ".jpg",
        "presence",
        "interaction_state",
        "confidence",
        "observable_basis",
        "assistant_adjustments",
        "strict json",
        "confidence band",
        "contract held",
    ]
    for fragment in forbidden_fragments:
        if fragment in lower:
            raise SystemExit(f"{name}: final response leaked mood internals: {fragment}")

def assert_streaming_disabled(expected_text):
    final_text = "\n".join(final_messages)
    if expected_text not in final_text:
        raise SystemExit(f"{name}: expected streaming disabled text")
    forbidden_tools = [item for item in tool_results if (item.get("tool") or "").startswith("agent_vision_")]
    if forbidden_tools:
        actual = ", ".join(item.get("tool", "<missing>") for item in forbidden_tools)
        raise SystemExit(f"{name}: disabled streaming must not call Agent Vision tools, observed {actual}")
    forbidden_commands = [
        item.get("command") or ""
        for item in command_results
        if "agent-vision-capture-file" in (item.get("command") or "")
        or "agent-vision-mcp" in (item.get("command") or "")
        or "AgentVision.app" in (item.get("command") or "")
    ]
    if forbidden_commands:
        raise SystemExit(f"{name}: disabled streaming launched Agent Vision command: {forbidden_commands[0]}")

try:
    assert_no_failure_terms()
    warn_repository_detour()
    if expected_contract == "capture-file":
        assert_capture_file()
        assert_markdown_image()
    elif expected_contract == "streaming":
        assert_streaming_disabled("Agent Vision streaming is temporarily disabled in 1.5.0 while the runtime is being moved to an explicit start/stop design.")
    elif expected_contract == "stop-streaming":
        assert_streaming_disabled("Agent Vision streaming is disabled in 1.5.0, so there is no Agent Vision streaming session to stop.")
    elif expected_contract == "roast":
        assert_capture_file()
        image_passes = [
            item for item in command_results
            if "codex exec" in (item.get("command") or "") and " -i " in (item.get("command") or "")
            and "--skip-git-repo-check" in (item.get("command") or "")
        ]
        if not image_passes:
            observed = "\n".join(item.get("command") or "<missing>" for item in command_results) or "<none>"
            raise SystemExit(f"{name}: expected separate codex exec --skip-git-repo-check -i image-input pass, observed {observed}")
        assert_markdown_image()
    elif expected_contract == "mood":
        assert_capture_file()
        image_passes = [
            item for item in command_results
            if "codex exec" in (item.get("command") or "")
            and " -i " in (item.get("command") or "")
            and "--skip-git-repo-check" in (item.get("command") or "")
            and "presence, interaction_state, confidence, observable_basis, assistant_adjustments" in (item.get("command") or "")
        ]
        if not image_passes:
            observed = "\n".join(item.get("command") or "<missing>" for item in command_results) or "<none>"
            raise SystemExit(f"{name}: expected separate codex exec --skip-git-repo-check -i mood JSON image-input pass, observed {observed}")
        assert_mood_is_internal()
    else:
        raise SystemExit(f"{name}: unknown expected contract {expected_contract}")
finally:
    for frame in sorted(created_paths):
        pathlib.Path(frame).unlink(missing_ok=True)

print(f"{name}: {expected_contract} passed")
PY
  local check_status=$?

  rm -f "$log"
  return "$check_status"
}

check_no_agent_vision_processes() {
  local leaked
  leaked="$(ps -axo pid=,ppid=,stat=,command= | awk -v baseline="$baseline_agent_vision_pids" '
    BEGIN {
      split(baseline, ids, /,/)
      for (i in ids) {
        if (ids[i] != "") {
          seen[ids[i]] = 1
        }
      }
    }
    /AgentVision|agent-vision-mcp/ && !/awk/ && !seen[$1] {print}
  ')"
  if [[ -n "$leaked" ]]; then
    echo "process-leak: Agent Vision processes remained after slash command matrix:" >&2
    echo "$leaked" >&2
    return 1
  fi
}

failures=0

run_case "snapshot" "/agent-vision snapshot" "capture-file" || failures=$((failures + 1))
run_case "streaming" "/agent-vision streaming" "streaming" || failures=$((failures + 1))
run_case "stop-streaming" "/agent-vision stop streaming" "stop-streaming" || failures=$((failures + 1))
run_case "roast" "/agent-vision roast" "roast" || failures=$((failures + 1))
run_case "mood" "/agent-vision mood" "mood" || failures=$((failures + 1))
check_no_agent_vision_processes || failures=$((failures + 1))

if [[ "$failures" -ne 0 ]]; then
  echo "agent-vision slash command matrix failed: $failures case(s)" >&2
  exit 1
fi

echo "agent-vision slash command matrix passed"
