#!/usr/bin/env bash
# Static contract tests for the Grok Build host adapter (L1). No camera required.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${ROOT}/hosts/grok/skills/agent-vision/SKILL.md"
PLUGIN="${ROOT}/hosts/grok/plugin.json"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

command -v python3 >/dev/null || {
  echo "python3 is required for plugin.json validation." >&2
  exit 1
}

[[ -f "$SKILL" ]] || { echo "Missing $SKILL" >&2; exit 1; }
[[ -f "$PLUGIN" ]] || { echo "Missing $PLUGIN" >&2; exit 1; }

text="$(cat "$SKILL")"
if [[ "$text" == ---$'\n'* ]]; then pass "frontmatter present"; else fail "frontmatter missing"; fi
[[ "$text" == *"name: agent-vision"* ]] && pass "name: agent-vision" || fail "name: agent-vision"
[[ "$text" == *"disable-model-invocation: true"* ]] && pass "disable-model-invocation" || fail "disable-model-invocation"
[[ "$text" == *"agent-vision-capture-file"* ]] && pass "capture helper named" || fail "capture helper named"
[[ "$text" == *"read_file"* ]] && pass "read_file vision path" || fail "read_file vision path"
[[ "$text" == *"~/.agent-vision/frames"* ]] && pass "Grok frame dir" || fail "Grok frame dir"
[[ "$text" == *"the first shell command must create the frame directory"* ]] && pass "camera-first" || fail "camera-first"
[[ "$text" == *"Do not inspect or roast the repository"* ]] && pass "no repo roast" || fail "no repo roast"
[[ "$text" == *"Agent Vision streaming is temporarily disabled"* ]] && pass "streaming disabled copy" || fail "streaming disabled copy"
[[ "$text" == *"there is no Agent Vision streaming session to stop"* ]] && pass "stop-streaming copy" || fail "stop-streaming copy"
[[ "$text" == *"Do not use codex exec"* ]] && pass "no codex exec" || fail "no codex exec"
[[ "$text" == *"Ship A"* ]] && pass "Ship A scope marked" || fail "Ship A scope marked"
[[ "$text" != *"~/.codex/plugins/cache/local/agent-vision/1.0.3"* ]] && pass "no Codex 1.0.3 cache hardcode" || fail "Codex 1.0.3 cache hardcode present"

python3 - "$PLUGIN" <<'PY'
import json, pathlib, sys
p = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert p.get("name") == "agent-vision", p
assert "mcpServers" not in p, p
print("PASS: plugin.json name and no mcpServers")
PY

for script in \
  install-runtime.sh uninstall-runtime.sh \
  install-grok.sh uninstall-grok.sh \
  test-capture-file-cli.sh test-grok-adapter.sh
do
  path="${ROOT}/scripts/${script}"
  if [[ -f "$path" ]]; then
    bash -n "$path" && pass "bash -n $script" || fail "bash -n $script"
  fi
done

# Optional: installed skill matches if present
if [[ -f "${HOME}/.grok/skills/agent-vision/SKILL.md" ]]; then
  if diff -q "$SKILL" "${HOME}/.grok/skills/agent-vision/SKILL.md" >/dev/null; then
    pass "installed user skill matches repo"
  else
    fail "installed user skill differs from repo (re-run install-grok.sh)"
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-grok-adapter: FAILED" >&2
  exit 1
fi
echo "test-grok-adapter: OK"
