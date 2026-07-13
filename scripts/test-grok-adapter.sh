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
[[ "$text" == *"argument-hint: mood|snapshot|roast|streaming"* ]] && pass "argument-hint mood-first" || fail "argument-hint mood-first"
[[ "$text" == *"## Purpose (read this first)"* ]] && pass "purpose section first" || fail "purpose section first"
[[ "$text" == *"main product value is mood"* ]] || [[ "$text" == *"main product value is mood/disposition"* ]] && pass "mood primary product value" || fail "mood primary product value"
[[ "$text" == *"Mood reasoning loop"* ]] && pass "mood reasoning loop" || fail "mood reasoning loop"
[[ "$text" == *"Incorporate that knowledge into your reasoning"* ]] || [[ "$text" == *"incorporate that knowledge into reasoning"* ]] || [[ "$text" == *"Incorporate into reasoning before"* ]] && pass "incorporate into reasoning" || fail "incorporate into reasoning"
[[ "$text" == *"agent-vision-capture-file"* ]] && pass "capture helper named" || fail "capture helper named"
[[ "$text" == *"read_file"* ]] && pass "read_file vision path" || fail "read_file vision path"
[[ "$text" == *"~/.agent-vision/frames"* ]] && pass "Grok frame dir" || fail "Grok frame dir"
[[ "$text" == *"the first shell command must create the frame directory"* ]] && pass "camera-first" || fail "camera-first"
[[ "$text" == *"Do not inspect or roast the repository"* ]] && pass "no repo roast" || fail "no repo roast"
[[ "$text" == *"Agent Vision streaming is temporarily disabled"* ]] && pass "streaming disabled copy" || fail "streaming disabled copy"
[[ "$text" == *"there is no Agent Vision streaming session to stop"* ]] && pass "stop-streaming copy" || fail "stop-streaming copy"
[[ "$text" == *"Do not use codex exec"* ]] && pass "no codex exec" || fail "no codex exec"
[[ "$text" == *"## Mood workflow (primary)"* ]] && pass "mood workflow primary" || fail "mood workflow primary"
[[ "$text" == *"## Snapshot workflow (supporting)"* ]] && pass "snapshot supporting" || fail "snapshot supporting"
[[ "$text" == *"## Roast workflow (supporting)"* ]] && pass "roast supporting" || fail "roast supporting"
[[ "$text" == *"400 characters or fewer"* ]] && pass "roast length limit" || fail "roast length limit"
[[ "$text" == *"interaction_state"* ]] && pass "mood JSON keys" || fail "mood JSON keys"
[[ "$text" == *"**Do not display**"* ]] || [[ "$text" == *"Do not display"* ]] && pass "mood no display" || fail "mood no display"
[[ "$text" != *"Milestone 2"* ]] && pass "no Milestone 2 roast/mood deferral" || fail "Milestone 2 deferral still present"
[[ "$text" != *"Not in Ship A"* ]] && pass "no Ship A roast exclusion" || fail "Ship A roast exclusion still present"
[[ "$text" != *"~/.codex/plugins/cache/local/agent-vision/1.0.3"* ]] && pass "no Codex 1.0.3 cache hardcode" || fail "Codex 1.0.3 cache hardcode present"

python3 - "$PLUGIN" <<'PY'
import json, pathlib, sys
p = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert p.get("name") == "agent-vision", p
assert "mcpServers" not in p, p
desc = (p.get("description") or "").lower()
assert "mood" in desc, p
assert "disposition" in desc or "reason" in desc or "reasoning" in desc, p
print("PASS: plugin.json name, no mcpServers, mood-first description")
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

# Optional: installed skill matches if present.
# During install preflight (AGENT_VISION_INSTALL_PREFLIGHT=1), drift is warn-only so
# install-grok can upgrade an older/drifted skill instead of self-blocking.
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
