# Install Agent Vision

Agent Vision supports two hosts. Pick the section that matches your assistant.

| Host | Status | What you get |
| --- | --- | --- |
| [Codex](#codex-stable-package) | Stable package **1.5.0** (+ sticky HARD GATE on main) | sticky mood-first; snapshot, roast, mood; streaming disabled |
| [Grok Build](#grok-build) | Public (**1.5.0**+) | sticky mood-first; snapshot, roast, mood; streaming disabled |

Shared rules on both hosts:

- **Sticky:** arm with `/agent-vision` (default mood); re-capture on every non-whitelist turn until `/agent-vision off`. New chat always starts **OFF**.
- **HARD GATE:** while armed, capture → understand pixels → **use image content in reasoning** is mandatory (topic irrelevant). Capture without use is invalid.
- No production Agent Vision MCP server.
- Install, enable, idle startup, disarmed prompts, streaming, and stop-streaming must **not** start a camera-capable process.
- Camera permission attaches to signed `AgentVision.app`.
- Each look is still a one-shot process (not an always-on daemon).

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

Sticky HARD GATE, turn-gate, and purge helpers land on **main** after the frozen 1.5.0 tarball. For the latest skill behavior: pull main and run `scripts/install-local.sh`, or re-stage `skills/camera-control` and the `agent-vision-{sticky,turn-gate,purge-frames}` scripts into the plugin cache.

QA traceability: [docs/agent-vision-install-uninstall-traceability.md](docs/agent-vision-install-uninstall-traceability.md).  
Agent install script: [CODEX_INSTALL.md](CODEX_INSTALL.md).  
Sticky contract: [docs/agent-vision-grok-session-sticky.md](docs/agent-vision-grok-session-sticky.md).

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
/agent-vision
/agent-vision mood
/agent-vision snapshot
/agent-vision roast
/agent-vision status
/agent-vision off
/agent-vision streaming
```

- **bare / mood** — **primary** — arm sticky + disposition calibration (silent) + HARD GATE loop on later turns.
- **snapshot** — one usable JPEG under `~/.codex/agent-vision/frames`, Markdown image link, camera off after the look; arms sticky.
- **roast** — snapshot + `codex exec -i` playful roast; arms sticky.
- **status** — sticky + last capture age (no camera if pure status).
- **off** — disarm; no further captures.
- **streaming** — disabled message; no process; does not arm.

### Codex uninstall

From the package tree:

```bash
./uninstall.sh
```

Or from a clone: `scripts/uninstall-local.sh` / packaged uninstall scripts. Removes Codex plugin staging, cache, marketplace entry, and legacy MCP config. Does **not** remove a separately installed Grok runtime home unless you also run `scripts/uninstall-runtime.sh`.

---

## Grok Build

**Primary value is sticky mood-first vision:** arm with `/agent-vision` (default mood), then each substantive turn captures a local frame, understands the image, and folds that into reasoning until `/agent-vision off`. Snapshot and roast are supporting modes. Streaming is disabled. Image analysis uses multimodal `read_file`. New chat always starts **OFF**.

### Requirements

- macOS with a working built-in camera
- A tree that contains a **signed** `dist/AgentVision.app` and `dist/agent-vision-capture-file` (this repository after a release build, or a checkout that already has `dist/`)
- Grok Build CLI with **sandbox off** (default) for capture
- `~/.local/bin` on your `PATH` (so `agent-vision-capture-file` and helper shims resolve)

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

# 2) Grok skill + sticky / turn-gate / purge PATH helpers (+ optional ~/.grok/plugins/agent-vision tree)
scripts/install-grok.sh
```

Open a **new** Grok session, then:

```text
/agent-vision
```

or `/agent-vision mood`. That **arms** sticky vision for the conversation. Later substantive turns re-capture and re-use vision until:

```text
/agent-vision off
```

Frames under `~/.agent-vision/frames`. Multimodal `read_file` after each capture. Session state under `~/.agent-vision/session-state.json` and `turn-gate.json` (helpers never start the camera).

Dry-run checks (no install):

```bash
# Requires a codesigned dist/AgentVision.app in the tree (release dist/ or local package build).
scripts/install-runtime.sh --dry-run
scripts/install-grok.sh --dry-run
scripts/test-grok-adapter.sh
scripts/test-grok-sticky-state.sh
scripts/test-agent-vision-turn-gate.sh
```

QA traceability: [docs/agent-vision-grok-install-uninstall-traceability.md](docs/agent-vision-grok-install-uninstall-traceability.md).  
Host adapter notes: [hosts/grok/README.md](hosts/grok/README.md).  
Sticky contract: [docs/agent-vision-grok-session-sticky.md](docs/agent-vision-grok-session-sticky.md).

After upgrading the skill (roast/mood/sticky/HARD GATE), open a **new** Grok session so the skill reloads.

### Grok first use

| Command | Result |
| --- | --- |
| `/agent-vision` or `mood` | **Primary** — arm sticky + disposition → reason → respond (silent) |
| `/agent-vision snapshot` \| `roast` | Arm sticky + supporting mode |
| Substantive turn while armed | **HARD GATE:** capture → understand → use in reasoning → turn-gate ready → respond |
| `/agent-vision status` | Sticky + last capture age; no capture if pure status |
| `/agent-vision off` (also stop / turn off camera) | Disarm; no further captures |
| `/agent-vision streaming` | Disabled; does not arm |

Optional frame retention: `agent-vision-purge-frames --ttl-days 7 --all` (or `/agent-vision off --purge-frames` when supported by the skill).

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

Black warm-up frames: Agent Vision retries up to 3 times with 5 seconds between attempts, then errors instead of returning a useless image. Skills may run one ambiguity-burst second capture if the first frame is unusable.

---

## Privacy

See [PRIVACY.md](PRIVACY.md). Frames stay local. No cloud upload. No production MCP. No idle camera process.
