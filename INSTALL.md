# Install Agent Vision

Agent Vision supports two hosts. Pick the section that matches your assistant.

| Host | Status | What you get |
| --- | --- | --- |
| [Codex](#codex-stable-package) | Stable package **1.5.0** | snapshot, roast, mood; streaming disabled |
| [Grok Build](#grok-build) | Public (**1.5.0**+) | snapshot, roast, mood; streaming disabled |

Shared rules on both hosts:

- No production Agent Vision MCP server.
- Install, enable, idle startup, unrelated prompts, streaming, and stop-streaming must **not** start a camera-capable process.
- Camera permission attaches to signed `AgentVision.app`.

---

## Codex (stable package)

Ask Codex to install from the repository URL:

```text
Install Agent Vision from https://github.com/zfifteen/agent-vision
```

Codex should download the packaged release, extract it, run `./install.sh`, and open a **new** Codex session so `/agent-vision` is loaded.

### Manual package install

```bash
curl -L -o agent-vision-1.5.0.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.5.0/agent-vision-1.5.0.tar.gz
tar -xzf agent-vision-1.5.0.tar.gz
cd agent-vision-1.5.0
./install.sh
```

The installer stages the signed packaged `AgentVision.app`, stages the plugin under `~/plugins/agent-vision`, updates `~/.agents/plugins/marketplace.json`, and registers the local marketplace plus `agent-vision@local` in `~/.codex/config.toml`.

Agent Vision 1.5.0 does not register an MCP server.

If an already-open Codex chat does not show `/agent-vision` after a successful install, open a new Codex chat or session so the slash-command index refreshes.

QA traceability: [docs/agent-vision-install-uninstall-traceability.md](docs/agent-vision-install-uninstall-traceability.md).  
Agent install script: [CODEX_INSTALL.md](CODEX_INSTALL.md).

### Codex developer source install

For developers and release producers only (builds and signs locally):

```bash
git clone https://github.com/zfifteen/agent-vision.git
cd agent-vision
scripts/install-local.sh
```

Requires Swift, Xcode command line tools, and a local signing identity.

### Codex first use

```text
/agent-vision snapshot
/agent-vision streaming
/agent-vision roast
/agent-vision mood
```

- **snapshot** — one usable JPEG under `~/.codex/agent-vision/frames`, Markdown image link, camera off.
- **streaming** — disabled message; no process.
- **roast** — snapshot + `codex exec -i` playful roast.
- **mood** — snapshot + `codex exec -i` silent delivery calibration.

### Codex uninstall

From the package tree:

```bash
./uninstall.sh
```

Or from a clone: `scripts/uninstall-local.sh` / packaged uninstall scripts. Removes Codex plugin staging, cache, marketplace entry, and legacy MCP config. Does **not** remove a separately installed Grok runtime home unless you also run `scripts/uninstall-runtime.sh`.

---

## Grok Build

**Primary value on Grok is mood:** one explicit local frame → ascertain disposition → incorporate into reasoning before the answer or task work. Snapshot and roast share the same capture path as supporting modes. Streaming is disabled. Image analysis uses multimodal `read_file` on the saved JPEG.

### Requirements

- macOS with a working built-in camera
- A tree that contains a **signed** `dist/AgentVision.app` and `dist/agent-vision-capture-file` (this repository after a release build, or a checkout that already has `dist/`)
- Grok Build CLI with **sandbox off** (default) for capture
- `~/.local/bin` on your `PATH` (so the `agent-vision-capture-file` shim resolves)

### Install

From the **1.5.0** package (recommended) or a clone with signed `dist/`:

```bash
# Package:
#   curl -L -o agent-vision-1.5.0.tar.gz https://github.com/zfifteen/agent-vision/releases/download/v1.5.0/agent-vision-1.5.0.tar.gz
#   tar -xzf agent-vision-1.5.0.tar.gz && cd agent-vision-1.5.0
#
# Or clone + local/signed dist, then:

# 1) Shared camera runtime → ~/.local/share/agent-vision + PATH shim
scripts/install-runtime.sh

# 2) Grok skill (+ optional ~/.grok/plugins/agent-vision tree)
scripts/install-grok.sh
```

Open a **new** Grok session, then prefer:

```text
/agent-vision mood
```

Optionally combine mood with a work request in the same turn so disposition shapes how Grok helps. Frames are written under `~/.agent-vision/frames`. Grok inspects the JPEG with multimodal `read_file` after capture.

Dry-run checks (no install):

```bash
# Requires a codesigned dist/AgentVision.app in the tree (release dist/ or local package build).
scripts/install-runtime.sh --dry-run
scripts/install-grok.sh --dry-run
scripts/test-grok-adapter.sh
```

QA traceability: [docs/agent-vision-grok-install-uninstall-traceability.md](docs/agent-vision-grok-install-uninstall-traceability.md).  
Host adapter notes: [hosts/grok/README.md](hosts/grok/README.md).

After upgrading the skill (roast/mood), open a **new** Grok session so the skill reloads.

### Grok first use

| Command | Result |
| --- | --- |
| `/agent-vision mood` | **Primary** — ascertain disposition, fold into reasoning, then respond/act (silent; no image/JSON dump) |
| `/agent-vision snapshot` | Supporting — one JPEG, camera off, image in chat after `read_file` |
| `/agent-vision roast` | Supporting — capture + `read_file` + playful roast; image + roast text |
| `/agent-vision streaming` | Disabled message; no process |
| stop streaming / turn off camera | No session message; no process |

### Grok uninstall

```bash
# Remove Grok skill/plugin only (keep shared runtime for Codex or later use)
scripts/uninstall-grok.sh

# Remove shared runtime + PATH shim
scripts/uninstall-runtime.sh

# Also delete saved Grok frames
scripts/uninstall-runtime.sh --remove-frames
```

`uninstall-grok.sh --with-runtime` removes the adapter and the runtime in one step.

---

## First capture and permissions

macOS asks for camera permission for **Agent Vision** (`AgentVision.app`) the first time capture runs. Repeated prompts usually mean the app identity changed—rerun `install-runtime.sh` or the Codex installer that restaged the app.

Black warm-up frames: Agent Vision retries up to 3 times with 5 seconds between attempts, then errors instead of returning a useless image.

---

## Privacy

See [PRIVACY.md](PRIVACY.md). Frames stay local. No cloud upload. No production MCP. No idle camera process.
