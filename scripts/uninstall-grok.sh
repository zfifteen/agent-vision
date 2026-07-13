#!/usr/bin/env bash
# Remove the Grok Build host adapter. Does not remove the shared runtime unless --with-runtime.
set -euo pipefail

USER_SKILL_DIR="${HOME}/.grok/skills/agent-vision"
USER_PLUGIN_DIR="${HOME}/.grok/plugins/agent-vision"
WITH_RUNTIME=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --with-runtime)
      WITH_RUNTIME=1
      shift
      ;;
    -h|--help)
      echo "Usage: scripts/uninstall-grok.sh [--with-runtime]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

rm -rf "$USER_SKILL_DIR"
echo "Removed skill dir (if present): $USER_SKILL_DIR"
rm -rf "$USER_PLUGIN_DIR"
echo "Removed plugin dir (if present): $USER_PLUGIN_DIR"

if [[ "$WITH_RUNTIME" == "1" ]]; then
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  bash "${ROOT}/scripts/uninstall-runtime.sh"
else
  echo "Left Agent Vision runtime installed (pass --with-runtime to remove it)."
  echo "Codex installs were not modified."
fi
