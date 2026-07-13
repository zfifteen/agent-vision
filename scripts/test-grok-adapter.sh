#!/usr/bin/env bash
# Static contract tests for the Grok Build host adapter (L1). No camera required.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${ROOT}/hosts/grok/skills/agent-vision/SKILL.md"
REF="${ROOT}/hosts/grok/skills/agent-vision/references/mood-roast-recipes.md"
PLUGIN="${ROOT}/hosts/grok/plugin.json"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }
[[ -f "$SKILL" ]] || { echo "Missing $SKILL" >&2; exit 1; }
[[ -f "$REF" ]] || { echo "Missing $REF" >&2; exit 1; }
[[ -f "$PLUGIN" ]] || { echo "Missing $PLUGIN" >&2; exit 1; }

text="$(cat "$SKILL")"
ref="$(cat "$REF")"

[[ "$text" == ---$'\n'* ]] && pass "frontmatter present" || fail "frontmatter missing"
[[ "$text" == *"name: agent-vision"* ]] && pass "name" || fail "name"
[[ "$text" == *"disable-model-invocation: false"* ]] && pass "disable-model-invocation false" || fail "disable-model-invocation"
[[ "$text" == *"HARD GATE"* ]] && pass "HARD GATE" || fail "HARD GATE"
[[ "$text" == *"USE THE IMAGE IN REASONING"* ]] || [[ "$text" == *"USE"* && "$text" == *"reasoning"* ]] && pass "use image in reasoning" || fail "use image in reasoning"
[[ "$text" == *"identical-to-blind"* ]] || [[ "$text" == *"identical to a blind"* ]] || [[ "$text" == *"Blind-identical"* ]] && pass "blind-identical invalid" || fail "blind-identical"
[[ "$text" == *"Topic is irrelevant"* ]] && pass "topic irrelevant" || fail "topic irrelevant"
[[ "$text" == *"FORBIDDEN"* ]] && pass "FORBIDDEN" || fail "FORBIDDEN"
[[ "$text" == *"Skip whitelist"* ]] || [[ "$text" == *"skip whitelist"* ]] && pass "skip whitelist" || fail "skip whitelist"
[[ "$text" == *"Disposition playbooks"* ]] && pass "disposition playbooks" || fail "disposition playbooks"
[[ "$text" == *"frustrated_or_blocked"* ]] && pass "playbook state frustrated" || fail "playbook frustrated"
[[ "$text" == *"tired_or_overloaded"* ]] && pass "playbook state tired" || fail "playbook tired"
[[ "$text" == *"Ambiguity burst"* ]] && pass "ambiguity burst" || fail "ambiguity burst"
[[ "$text" == *"turn-gate"* ]] && pass "turn-gate referenced" || fail "turn-gate referenced"
[[ "$text" == *"agent-vision-sticky status"* ]] || [[ "$text" == *"status"* && "$text" == *"last_capture"* ]] || [[ "$text" == *"agent-vision-sticky status"* ]] && pass "status command" || fail "status command"
[[ "$text" == *"agent-vision-purge-frames"* ]] && pass "purge referenced" || fail "purge referenced"
[[ "$text" == *"references/mood-roast-recipes.md"* ]] && pass "references link" || fail "references link"
[[ "$text" == *"agent-vision-capture-file"* ]] && pass "capture helper" || fail "capture helper"
[[ "$text" == *"read_file"* ]] && pass "read_file" || fail "read_file"
[[ "$text" == *"Do not use codex exec"* ]] && pass "no codex exec" || fail "no codex exec"
[[ "$text" != *"only when vision would help"* ]] && pass "no optional vision" || fail "optional vision"
# Long mood JSON keys live in references, not bloating skill-only requirement
[[ "$ref" == *"interaction_state"* ]] && pass "ref mood keys" || fail "ref mood keys"
[[ "$ref" == *"Ambiguity burst"* ]] && pass "ref ambiguity burst" || fail "ref ambiguity burst"
[[ "$ref" == *"400 characters"* ]] && pass "ref roast length" || fail "ref roast length"

CODEX_SKILL="${ROOT}/skills/camera-control/SKILL.md"
ct="$(cat "$CODEX_SKILL")"
[[ "$ct" == *"HARD GATE"* ]] && pass "Codex HARD GATE" || fail "Codex HARD GATE"
[[ "$ct" == *"Disposition playbooks"* ]] && pass "Codex playbooks" || fail "Codex playbooks"
[[ "$ct" == *"Ambiguity burst"* ]] && pass "Codex ambiguity" || fail "Codex ambiguity"
[[ "$ct" == *"turn-gate"* ]] && pass "Codex turn-gate" || fail "Codex turn-gate"

CMD="${ROOT}/commands/agent-vision.md"
[[ "$(cat "$CMD")" == *"HARD GATE"* ]] && pass "command HARD GATE" || fail "command HARD GATE"
[[ "$(cat "$CMD")" == *"playbook"* ]] || [[ "$(cat "$CMD")" == *"Playbooks"* ]] && pass "command playbooks" || fail "command playbooks"

python3 - "$PLUGIN" <<'PY'
import json, pathlib, sys
p = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert p.get("name") == "agent-vision"
assert "mcpServers" not in p
print("PASS: plugin.json")
PY

for script in \
  install-runtime.sh uninstall-runtime.sh install-grok.sh uninstall-grok.sh \
  agent-vision-sticky.sh agent-vision-turn-gate.sh agent-vision-purge-frames.sh \
  test-capture-file-cli.sh test-grok-adapter.sh test-grok-sticky-state.sh \
  test-agent-vision-turn-gate.sh test-agent-vision-purge-frames.sh
do
  path="${ROOT}/scripts/${script}"
  if [[ -f "$path" ]]; then
    bash -n "$path" && pass "bash -n $script" || fail "bash -n $script"
  fi
done

if [[ -f "${HOME}/.grok/skills/agent-vision/SKILL.md" ]]; then
  if diff -q "$SKILL" "${HOME}/.grok/skills/agent-vision/SKILL.md" >/dev/null; then
    pass "installed skill matches"
  elif [[ "${AGENT_VISION_INSTALL_PREFLIGHT:-0}" == "1" ]]; then
    pass "install preflight skill drift warn"
  else
    fail "installed skill differs (re-run install-grok.sh)"
  fi
  # references should be installed if install-grok copies skill dir
  if [[ -f "${HOME}/.grok/skills/agent-vision/references/mood-roast-recipes.md" ]]; then
    pass "installed references present"
  else
    # not fail if install only copies SKILL.md — check install-grok
    pass "installed references optional unless install copies tree"
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-grok-adapter: FAILED" >&2
  exit 1
fi
echo "test-grok-adapter: OK"
