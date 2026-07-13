#!/usr/bin/env bash
set -euo pipefail

baseline_agent_vision_pids="$(ps -axo pid=,command= | awk '/AgentVision|agent-vision-mcp|agent-vision-capture-file/ && !/awk/ {print $1}' | paste -sd, -)"

leaked_after_noop() {
  ps -axo pid=,ppid=,stat=,command= | awk -v baseline="$baseline_agent_vision_pids" '
    BEGIN {
      split(baseline, ids, /,/)
      for (i in ids) {
        if (ids[i] != "") {
          seen[ids[i]] = 1
        }
      }
    }
    /AgentVision|agent-vision-mcp|agent-vision-capture-file/ && !/awk/ && !seen[$1] {print}
  '
}

leaked="$(leaked_after_noop)"
if [[ -n "$leaked" ]]; then
  echo "process-leak: Agent Vision processes were already running before disabled-streaming validation:" >&2
  echo "$leaked" >&2
  exit 1
fi

echo "agent-vision streaming is disabled in 1.5.0; no streaming interaction test is available until the explicit runtime lands."
