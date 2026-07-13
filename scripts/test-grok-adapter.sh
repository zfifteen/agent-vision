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
[[ "$text" == *"disable-model-invocation: false"* ]] && pass "disable-model-invocation false" || fail "disable-model-invocation false"
[[ "$text" == *"argument-hint: mood|snapshot|roast|off|streaming"* ]] && pass "argument-hint sticky modes" || fail "argument-hint sticky modes"
[[ "$text" == *"Session sticky model"* ]] && pass "session sticky model" || fail "session sticky model"
[[ "$text" == *"NEW conversation"* ]] || [[ "$text" == *"New chat starts OFF"* ]] && pass "new chat starts OFF" || fail "new chat starts OFF"
[[ "$text" == *"agent-vision-sticky.sh"* ]] && pass "sticky script referenced" || fail "sticky script referenced"
[[ "$text" == *"/agent-vision off"* ]] && pass "off command" || fail "off command"
[[ "$text" == *"substantive"* ]] && pass "substantive turn capture" || fail "substantive turn capture"
[[ "$text" == *"Incorporate that understanding into your reasoning"* ]] || [[ "$text" == *"incorporate that into reasoning"* ]] || [[ "$text" == *"Incorporate that understanding"* ]] && pass "incorporate into reasoning" || fail "incorporate into reasoning"
[[ "$text" == *"agent-vision-capture-file"* ]] && pass "capture helper named" || fail "capture helper named"
[[ "$text" == *"read_file"* ]] && pass "read_file vision path" || fail "read_file vision path"
[[ "$text" == *"~/.agent-vision/frames"* ]] && pass "Grok frame dir" || fail "Grok frame dir"
[[ "$text" == *"first shell command"* ]] && pass "camera-first" || fail "camera-first"
[[ "$text" == *"Do not use codex exec"* ]] && pass "no codex exec" || fail "no codex exec"
[[ "$text" == *"Agent Vision streaming is temporarily disabled"* ]] && pass "streaming disabled copy" || fail "streaming disabled copy"
[[ "$text" != *"Milestone 2"* ]] && pass "no Milestone 2 deferral" || fail "Milestone 2 deferral still present"
[[ "$text" != *"~/.codex/plugins/cache/local/agent-vision/1.0.3"* ]] && pass "no Codex 1.0.3 cache hardcode" || fail "Codex 1.0.3 cache hardcode present"

# Codex sticky contract present
CODEX_SKILL="${ROOT}/skills/camera-control/SKILL.md"
if [[ -f "$CODEX_SKILL" ]]; then
  ct="$(cat "$CODEX_SKILL")"
  [[ "$ct" == *"Session sticky model"* ]] && pass "Codex sticky model" || fail "Codex sticky model"
  [[ "$ct" == *"/agent-vision off"* ]] || [[ "$ct" == *"`off`"* ]] && pass "Codex off" || fail "Codex off"
fi

python3 - "$PLUGIN" <<'PY'
import json, pathlib, sys
p = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert p.get("name") == "agent-vision", p
assert "mcpServers" not in p, p
desc = (p.get("description") or "").lower()
assert "sticky" in desc and "mood" in desc, p
print("PASS: plugin.json name, no mcpServers, sticky mood description")
PY

for script in \
  install-runtime.sh uninstall-runtime.sh \
  install-grok.sh uninstall-grok.sh \
  agent-vision-sticky.sh \
  test-capture-file-cli.sh test-grok-adapter.sh test-grok-sticky-state.sh
do
  path="${ROOT}/scripts/${script}"
  if [[ -f "$path" ]]; then
    bash -n "$path" && pass "bash -n $script" || fail "bash -n $script"
  fi
done

if [[ -f "${HOME}/.grok/skills/agent-vision/SKILL.md" ]]; then
  if diff -q "$SKILL" "${HOME}/.grok/skills/agent-vision/SKILL.md" >/dev/null; then
    pass "installed user skill matches repo"
  elif [[ "${AGENT_VISION_INSTALL_PREFLIGHT:-0}" == "1" ]]; then
    echo "WARN: installed user skill differs from repo; install will overwrite it." >&2
    pass "installed skill drift ignored during install preflight"
  else
    fail "installed user skill differs from repo (re-run install-grok.sh to upgrade)"
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-grok-adapter: FAILED" >&2
  exit 1
fi
echo "test-grok-adapter: OK"
