#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output)
      if [[ "$#" -lt 2 ]]; then
        echo '{"ok":false,"error":{"code":"missing_output","message":"--output requires an absolute path."}}' >&2
        exit 64
      fi
      OUTPUT="$2"
      shift 2
      ;;
    --json)
      shift
      ;;
    *)
      echo '{"ok":false,"error":{"code":"unknown_argument","message":"Unsupported argument."}}' >&2
      exit 64
      ;;
  esac
done

if [[ -z "$OUTPUT" || "$OUTPUT" != /* ]]; then
  echo '{"ok":false,"error":{"code":"invalid_output","message":"--output must be an absolute path."}}' >&2
  exit 64
fi

if [[ -e "$OUTPUT" ]]; then
  echo '{"ok":false,"error":{"code":"output_exists","message":"Output file already exists."}}' >&2
  exit 73
fi

mkdir -p "$(dirname "$OUTPUT")"

python3 - "$ROOT/dist/agent-vision-mcp" "$OUTPUT" <<'PY'
import base64
import json
import pathlib
import select
import subprocess
import sys
import time

server = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])

if not server.exists():
    print(json.dumps({
        "ok": False,
        "error": {
            "code": "mcp_wrapper_missing",
            "message": f"Agent Vision MCP wrapper is missing: {server}",
        },
    }), file=sys.stderr)
    raise SystemExit(66)

process = subprocess.Popen(
    [str(server)],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
)

try:
    requests = [
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "agent-vision-capture-file", "version": "1.0.1"},
            },
        },
        {"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}},
        {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {"name": "agent_vision_snapshot", "arguments": {}},
        },
    ]
    assert process.stdin is not None
    for request in requests:
        process.stdin.write(json.dumps(request, separators=(",", ":")) + "\n")
        process.stdin.flush()
    process.stdin.close()

    response = None
    deadline = time.time() + 20
    assert process.stdout is not None
    while time.time() < deadline and response is None:
        readable, _, _ = select.select([process.stdout], [], [], 0.2)
        for stream in readable:
            line = stream.readline()
            if not line:
                continue
            message = json.loads(line)
            if message.get("id") == 2:
                response = message
                break

    if response is None:
        print(json.dumps({
            "ok": False,
            "error": {
                "code": "capture_timeout",
                "message": "Agent Vision snapshot did not return before timeout.",
            },
        }), file=sys.stderr)
        raise SystemExit(75)

    result = response.get("result") or {}
    if result.get("isError") is True:
        content = result.get("content") or []
        text = next((part.get("text") for part in content if part.get("type") == "text"), "Agent Vision snapshot failed.")
        print(json.dumps({
            "ok": False,
            "error": {"code": "capture_failed", "message": text},
        }), file=sys.stderr)
        raise SystemExit(70)

    content = result.get("content") or []
    image = next((part for part in content if part.get("type") == "image" and part.get("data")), None)
    if image is None:
        print(json.dumps({
            "ok": False,
            "error": {
                "code": "image_content_missing",
                "message": "Agent Vision snapshot returned no image content.",
            },
        }), file=sys.stderr)
        raise SystemExit(70)

    try:
        data = base64.b64decode(image["data"], validate=True)
    except Exception:
        print(json.dumps({
            "ok": False,
            "error": {
                "code": "image_decode_failed",
                "message": "Agent Vision image content was not valid base64.",
            },
        }), file=sys.stderr)
        raise SystemExit(70)

    if not data.startswith(b"\xff\xd8"):
        print(json.dumps({
            "ok": False,
            "error": {
                "code": "jpeg_invalid",
                "message": "Agent Vision image content was not a JPEG.",
            },
        }), file=sys.stderr)
        raise SystemExit(70)

    with output.open("xb") as handle:
        handle.write(data)

    metadata = result.get("structuredContent") or {}
    print(json.dumps({
        "ok": True,
        "path": str(output),
        "mimeType": image.get("mimeType", "image/jpeg"),
        "width": metadata.get("width"),
        "height": metadata.get("height"),
        "bytes": len(data),
        "timestamp": metadata.get("timestamp"),
    }, separators=(",", ":")))
finally:
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)
PY
