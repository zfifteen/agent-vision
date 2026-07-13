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
[[ "$text" == *"HARD GATE"* ]] && pass "HARD GATE present" || fail "HARD GATE present"
[[ "$text" == *"USE THE IMAGE IN REASONING"* ]] || [[ "$text" == *"use in reasoning"* ]] || [[ "$text" == *"USE image in reasoning"* ]] || [[ "$text" == *"vision **in reasoning**"* ]] || [[ "$text" == *"USE THE IMAGE"* ]] && pass "use image in reasoning" || fail "use image in reasoning"
[[ "$text" == *"identical if you had never looked"* ]] || [[ "$text" == *"identical-to-blind"* ]] || [[ "$text" == *"as if blind"* ]] && pass "blind-identical invalid" || fail "blind-identical invalid"
[[ "$text" == *"non-optional"* ]] || [[ "$text" == *"mandatory"* ]] && pass "non-optional language" || fail "non-optional language"
[[ "$text" == *"Topic is irrelevant"* ]] && pass "topic is irrelevant" || fail "topic is irrelevant"
[[ "$text" == *"FORBIDDEN"* ]] && pass "FORBIDDEN section" || fail "FORBIDDEN section"
[[ "$text" == *"Skip whitelist"* ]] || [[ "$text" == *"skip whitelist"* ]] && pass "skip whitelist" || fail "skip whitelist"
[[ "$text" == *"End-of-turn compliance"* ]] || [[ "$text" == *"End-of-turn checklist"* ]] && pass "end-of-turn checklist" || fail "end-of-turn checklist"
[[ "$text" == *"INVALID"* ]] && pass "INVALID if skip" || fail "INVALID if skip"
[[ "$text" == *"whole point"* ]] || [[ "$text" == *"enters your reasoning"* ]] && pass "product point reasoning" || fail "product point reasoning"
[[ "$text" == *"First tool call this turn MUST be"* ]] || [[ "$text" == *"First tool call this turn MUST be"* ]] || [[ "$text" == *"first tool call"* ]] || [[ "$text" == *"First tool call"* ]] && pass "first tool call capture" || fail "first tool call capture"
[[ "$text" != *"only when vision would help"* ]] && pass "no optional vision judgment" || fail "optional vision judgment still present"
[[ "$text" != *"if useful"* ]] && pass "no if-useful escape" || fail "if-useful escape still present"
[[ "$text" == *"argument-hint: mood|snapshot|roast|off|streaming"* ]] && pass "argument-hint" || fail "argument-hint"
[[ "$text" == *"agent-vision-capture-file"* ]] && pass "capture helper named" || fail "capture helper named"
[[ "$text" == *"read_file"* ]] && pass "read_file vision path" || fail "read_file vision path"
[[ "$text" == *"~/.agent-vision/frames"* ]] && pass "Grok frame dir" || fail "Grok frame dir"
[[ "$text" == *"Do not use codex exec"* ]] && pass "no codex exec" || fail "no codex exec"
[[ "$text" == *"Agent Vision streaming is temporarily disabled"* ]] && pass "streaming disabled copy" || fail "streaming disabled copy"
[[ "$text" == *"agent-vision-sticky"* ]] && pass "sticky script referenced" || fail "sticky script referenced"
[[ "$text" != *"Milestone 2"* ]] && pass "no Milestone 2 deferral" || fail "Milestone 2 deferral still present"
[[ "$text" != *"~/.codex/plugins/cache/local/agent-vision/1.0.3"* ]] && pass "no Codex 1.0.3 cache hardcode" || fail "Codex 1.0.3 cache hardcode present"

CODEX_SKILL="${ROOT}/skills/camera-control/SKILL.md"
if [[ -f "$CODEX_SKILL" ]]; then
  ct="$(cat "$CODEX_SKILL")"
  [[ "$ct" == *"HARD GATE"* ]] && pass "Codex HARD GATE" || fail "Codex HARD GATE"
  [[ "$ct" == *"Topic is irrelevant"* ]] && pass "Codex topic irrelevant" || fail "Codex topic irrelevant"
  [[ "$ct" == *"FORBIDDEN"* ]] && pass "Codex FORBIDDEN" || fail "Codex FORBIDDEN"
fi

CMD="${ROOT}/commands/agent-vision.md"
if [[ -f "$CMD" ]]; then
  [[ "$(cat "$CMD")" == *"HARD GATE"* ]] && pass "Codex command HARD GATE" || fail "Codex command HARD GATE"
fi

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
