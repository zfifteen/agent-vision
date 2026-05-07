#!/usr/bin/env bash
set -euo pipefail

SERVER="$HOME/.codex/plugins/cache/local/agent-vision/1.0.1/dist/agent-vision-mcp"
CAPTURE_FILE="$HOME/.codex/plugins/cache/local/agent-vision/1.0.1/dist/agent-vision-capture-file"
OUTPUT="$HOME/.codex/agent-vision/frames/streaming-interaction-test-$$.jpg"

command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

python3 - "$SERVER" "$CAPTURE_FILE" "$OUTPUT" <<'PY'
import json
import pathlib
import select
import subprocess
import sys
import time

server = pathlib.Path(sys.argv[1])
capture_file = pathlib.Path(sys.argv[2])
output = pathlib.Path(sys.argv[3])

if not server.exists():
    raise SystemExit(f"Agent Vision MCP wrapper is missing: {server}")
if not capture_file.exists():
    raise SystemExit(f"Agent Vision file materializer is missing: {capture_file}")
if output.exists():
    raise SystemExit(f"Test output already exists: {output}")

output.parent.mkdir(parents=True, exist_ok=True)
process = subprocess.Popen(
    [str(server)],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
)

responses = {}

def send(message):
    assert process.stdin is not None
    process.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
    process.stdin.flush()

def read_until(target_id, timeout=20):
    assert process.stdout is not None
    deadline = time.time() + timeout
    while time.time() < deadline:
        readable, _, _ = select.select([process.stdout], [], [], 0.2)
        for stream in readable:
            line = stream.readline()
            if not line:
                continue
            data = json.loads(line)
            if "id" in data:
                responses[data["id"]] = data
                if data["id"] == target_id:
                    return data
    raise SystemExit(f"Timed out waiting for response id {target_id}; observed ids: {sorted(responses)}")

def assert_tool_ok(response, label):
    if "error" in response:
        raise SystemExit(f"{label} JSON-RPC error: {response['error']}")
    result = response.get("result") or {}
    if result.get("isError") is True:
        text = " ".join(
            part.get("text", "")
            for part in result.get("content", [])
            if part.get("type") == "text"
        ).strip()
        raise SystemExit(f"{label} tool error: {text}")
    return result

try:
    send({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "agent-vision-streaming-interaction-test", "version": "1.0.1"},
        },
    })
    assert_tool_ok(read_until(1), "initialize")
    send({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})

    send({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {"name": "agent_vision_start", "arguments": {}},
    })
    assert_tool_ok(read_until(2), "agent_vision_start")

    capture = subprocess.run(
        [str(capture_file), "--output", str(output), "--json"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )
    if capture.returncode != 0:
        raise SystemExit(
            "agent-vision-capture-file failed while streaming was active:\n"
            f"stdout: {capture.stdout.strip()}\n"
            f"stderr: {capture.stderr.strip()}"
        )
    try:
        capture_json = json.loads(capture.stdout.strip())
    except json.JSONDecodeError as error:
        raise SystemExit(f"agent-vision-capture-file did not print JSON: {error}: {capture.stdout!r}")
    if capture_json.get("ok") is not True:
        raise SystemExit(f"agent-vision-capture-file did not return ok=true: {capture_json}")
    if capture_json.get("path") != str(output):
        raise SystemExit(f"agent-vision-capture-file wrote unexpected path: {capture_json}")
    data = output.read_bytes()
    if not data.startswith(b"\xff\xd8"):
        raise SystemExit("agent-vision-capture-file output was not a JPEG")

    send({
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {"name": "agent_vision_frame", "arguments": {}},
    })
    frame_result = assert_tool_ok(read_until(3), "agent_vision_frame")
    frame_content = frame_result.get("content") or []
    if not any(part.get("type") == "image" and part.get("data") for part in frame_content):
        raise SystemExit("agent_vision_frame returned no image content after file capture")

    send({
        "jsonrpc": "2.0",
        "id": 4,
        "method": "tools/call",
        "params": {"name": "agent_vision_stop", "arguments": {}},
    })
    assert_tool_ok(read_until(4), "agent_vision_stop")
finally:
    try:
        if process.stdin is not None:
            process.stdin.close()
    except Exception:
        pass
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)
    output.unlink(missing_ok=True)

print("agent-vision streaming interaction passed")
PY

leaked="$(ps -axo pid=,ppid=,stat=,command= | awk '/AgentVision|agent-vision-mcp|agent-vision-capture-file/ && !/awk/ {print}')"
if [[ -n "$leaked" ]]; then
  echo "process-leak: Agent Vision processes remained after streaming interaction test:" >&2
  echo "$leaked" >&2
  exit 1
fi
