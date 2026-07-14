# Agent Vision: Grok Build CLI Compatibility

**Status:** **Ship A shipped** (1.5.0 multi-host package). **Main now includes** sticky mood-first sessions, roast/mood parity, HARD GATE, turn-gate, and purge helpers on Grok + Codex.  
**Planning sections below** retain Ship A/B history and north-star notes; for the **current session contract**, prefer [agent-vision-grok-session-sticky.md](./agent-vision-grok-session-sticky.md) and root README / INSTALL.  
**Branch (historical):** `feat/grok-build-compatibility` (merged)  
**Date:** 2026-07-13  
**Last revised:** 2026-07-13 (sticky HARD GATE docs pass; [expert review](./agent-vision-grok-build-compatibility-review.md) applied)  
**Repository policy:** Same project, multi-host adapters — **not** a new repository.  
**Validation:** Phase 0 `read_file` PASS ([evidence](./evidence/phase-0-vision-ingest-2026-07-13.md)); live Grok session green; `scripts/test-grok-adapter.sh` green.

### Release tracks (versioning)

| Track | Tag / claim | When |
| --- | --- | --- |
| **Ship A — first public Grok cut** | Public docs + in-repo install; optional **`1.0.4`-class** tag; do **not** brand as full multi-host `1.1.0` | Phase 0 pass + runtime install + Grok **snapshot** + lifecycle gates (done) |
| **Ship B — multi-host product** | **`1.1.0` multi-host** support commitment | Ship A solid + dual-host install/uninstall + docs; roast/mood on Grok only if isolation milestone passes |

---

## 1. Purpose

Extend Agent Vision so a local **Grok Build CLI** session can use the same explicit, one-shot macOS camera capture contract that Codex uses today, without:

- reviving an idle or eagerly launched MCP camera process,
- forking the native capture stack into a second product,
- weakening the privacy and lifecycle invariants established in 1.0.3.

This document is the multi-host **contract** for Agent Vision. Ship A runtime and docs are in-tree (`hosts/grok/`, `scripts/install-runtime.sh`, `scripts/install-grok.sh`).

**Expert-review posture (locked):** multi-host *north star*; first public Grok cut is **snapshot-only** (streaming disabled, no MCP). Codex paths frozen. Binary strategy A. Reserve full multi-host `1.1.0` branding for Ship B.

---

## 2. Closed decisions

These are **locked for this initiative**. Do not re-litigate in Phase 1–3 without an explicit plan amendment.

| ID | Decision |
| --- | --- |
| D1 | **Same repository.** Shared native runtime + host adapters. No `agent-vision-grok` fork. No second Swift app unless Phase 0 forces a distinct TCC principal (not expected). |
| D2 | **Binary strategy A only.** Grok skill/plugin ships Markdown (and optional empty MCP omit). Signed `AgentVision.app` + capture helper always come from a **separate runtime install**. Do **not** embed `dist/` inside the Grok plugin for first ship. |
| D3 | **Install-time path stamp + PATH shim.** Primary capture helper is the absolute path under `$AGENT_VISION_HOME` (default `$HOME/.local/share/agent-vision`) and/or a shim at `$HOME/.local/bin/agent-vision-capture-file`. **Do not** use a skill-time multi-branch env cascade as the primary design. **`GROK_PLUGIN_ROOT` is not a primary capture resolver** (hook-scoped in Grok docs). |
| D4 | **Codex path freeze for Ship A.** Codex skill, command, and installer keep `~/.codex/agent-vision/frames` and versioned Codex plugin cache paths. No neutral-frame migration, no `hosts/codex/` physical move in Ship A. |
| D5 | **Grok frame directory (Ship A).** `$HOME/.agent-vision/frames` with user-only permissions (`0700` on the directory tree when created by install/skill). |
| D6 | **Sandbox policy (Ship A).** Supported configuration is Grok **sandbox off** (Grok default). Restricted profiles (`workspace` / `read-only` / `strict`) are **unsupported** for capture: fail closed with an explicit error before or at capture; do not silently write elsewhere or use screenshots. Optional later work may add sandbox-writable paths under `~/.grok/`. |
| D7 | **Ship A feature set.** Grok: `/agent-vision snapshot`, streaming disabled fixed copy, stop-streaming fixed copy, no MCP, `disable-model-invocation: true`. **Grok roast and mood are Milestone 2**, not Ship A Musts (weaker isolation than Codex `codex exec -i`). |
| D8 | **Grok public skill name.** `name: agent-vision` (slash `/agent-vision`). Do not ship a parallel user-invocable skill named `camera-control` on Grok. |
| D9 | **Vision ingest candidate.** After `ok: true`, Grok uses multimodal **`read_file`** on the absolute JPEG path. Phase 0 must prove this. No Ship A roast/mood; if Phase 0 fails, stop until an alternate ingest is proven (do not ship metadata-only “success”). |
| D10 | **Version branding.** Ship A ≠ `1.1.0` multi-host claim. Reserve **`1.1.0`** for Ship B. |
| D11 | **Plugin layout.** Grok host tree uses root **`plugin.json`** + `skills/` (not `.grok-plugin/` by analogy with `.codex-plugin/`). |
| D12 | **Streaming disabled copy.** Use **version-agnostic** fixed strings (do not hardcode `1.0.3` in new Grok text). Optional later: align Codex copy the same way when Codex is next touched. |
| D13 | **CI vision.** Developer-manual L3/L4 is enough for Ship A. No headless Grok vision CI requirement. |
| D14 | **Skill text is necessary but not sufficient.** Installer phrase asserts remain; behavioral process gates and Phase 0 vision rubric are required for privacy/vision claims. |

---

## 3. Background and constraints

### 3.1 What already works (shared runtime)

Agent Vision 1.0.3 already provides:

| Component | Role |
| --- | --- |
| Signed `AgentVision.app` | Owns camera permission (`works.velocity.agent-vision`) |
| `dist/agent-vision-capture-file` | One-shot file materializer (Launch Services → app → JPEG + JSON) |
| Black-frame readiness | Rejects unusable warm-up frames (brightness gate, retries) |
| Codex host adapter | Slash command + skill; `codex exec -i` for roast/mood vision |
| Empty production MCP | `.mcp.json` has no servers; no idle camera process |

Codex proved that **MCP image content is not a reliable model-vision path**. The durable contract is:

```text
explicit user command
  → agent-vision-capture-file
  → absolute JPEG on disk
  → host-specific vision ingest
  → display / (later) roast / mood policy
```

### 3.2 What differs on Grok Build

| Concern | Codex 1.0.3 | Grok Build CLI |
| --- | --- | --- |
| Packaging | `.codex-plugin/`, Codex plugin cache | Skills/plugins under `~/.grok/`, `grok plugin install` |
| Slash entry | `commands/` + skill `camera-control` | Skill **name** is the slash command (`agent-vision`) |
| Vision ingest | Markdown image link + `codex exec -i` | Candidate: multimodal `read_file` (Phase 0) |
| Roast/mood isolation | Separate `codex exec -i` process | Weaker if in-session only → **Milestone 2** |
| MCP | Removed after eager-start incident | Must not be used for production camera lifecycle |
| Frame storage (Ship A) | Unchanged: `~/.codex/agent-vision/frames` | `~/.agent-vision/frames` |

### 3.3 Architectural decision (fixed)

```text
shared native runtime  +  Codex host adapter (frozen paths in Ship A)  +  Grok host adapter
```

Do **not** create `agent-vision-grok` or a second Swift app unless Phase 0 forces a distinct bundle identity.

**“Grok is a better host” is not established.** Grok may avoid Codex plugin-load MCP quirks; roast/mood isolation and install maturity are unproven until measured.

---

## 4. Goals and non-goals

### 4.1 Goals — Ship A (first useful Grok cut)

1. User can run `/agent-vision snapshot` in Grok Build and receive a real camera JPEG the model can inspect via a proven ingest path.
2. Install, Grok plugin enable/trust, idle Grok startup, unrelated prompts, streaming, and stop-streaming start **no** Agent Vision camera-capable process.
3. Shared runtime remains one signed app + one capture helper; Grok differences live in skill/install adapters.
4. Codex 1.0.3 path and no-MCP package remain intact (path freeze).
5. Requirements and tests are explicit enough to implement without rediscovery.

### 4.2 Goals — Ship B / north star (later)

1. Documented dual-host install/uninstall with symmetric runtime retention.
2. Optional Grok roast/mood with isolation design (not assumed free parity with Codex).
3. README/PRIVACY/INSTALL multi-host product claim under **`1.1.0`**.
4. Optional Codex path modernization (neutral frames / shared home) as a **separate**, tested migration.

### 4.3 Non-goals (this initiative overall)

- Re-enabling production MCP for either host.
- Streaming mode start/stop runtime.
- Audio capture, device selection, cloud upload, remote camera, browser `getUserMedia`.
- Mood history, training datasets, background mood detection, or a separate image archive.
- Windows/Linux support.
- Rewriting AVFoundation for quality unrelated to host compatibility.
- Public Grok marketplace install as a Ship A hard requirement.
- Physical move of Codex sources into `hosts/codex/` in Ship A.
- Embedding signed binaries in the Grok plugin package (strategy B).

---

## 5. Requirements

MoSCoW: **Must** blocks the named ship. **Ship A Must** blocks first Grok cut. **Ship B Must** blocks `1.1.0` multi-host claim. **Should/Could** as marked. **Won’t** deferred by design.

### 5.1 Product and privacy (Must — all ships)

| ID | Requirement |
| --- | --- |
| R-P1 | Camera capture runs only for explicit user slash invocation of `/agent-vision` with argument `snapshot` (Ship A). Ship B may add `roast` / `mood` under the same slash-only rule. Natural language alone must not start capture when `disable-model-invocation` is true. |
| R-P2 | Install, Grok plugin enable/trust, idle Grok session start, unrelated prompts, `/agent-vision streaming`, and stop-streaming must not start `AgentVision.app`, `agent-vision-mcp`, `agent-vision-capture-file`, or any Agent Vision camera-capable helper. |
| R-P3 | No production MCP server registration for Agent Vision on Grok (empty or absent MCP config for this product). |
| R-P4 | Frames remain local; no cloud upload, telemetry, analytics, or remote logging introduced by the Grok adapter. |
| R-P5 | *(Ship B / Milestone 2 if mood ships)* Mood must not change facts, permissions, approval behavior, user intent, or task scope; only permitted delivery dimensions. |
| R-P6 | *(Ship B / Milestone 2 if roast ships)* Roast remains opt-in, ≤400 characters, non-sensitive visible details only; no protected-trait / body-size / age / disability attacks. |
| R-P7 | *(Ship B / Milestone 2 if mood ships)* Mood silent by default unless user asks to debug. |
| R-P8 | Camera permission continues to attach to signed `AgentVision.app`; capture launches via Launch Services (or equivalent that preserves identity), not a bare unsigned CLI as the permission principal. |

### 5.2 Shared runtime (Must)

| ID | Requirement |
| --- | --- |
| R-R1 | Grok and Codex share the same `AgentVision.app` capture-file entrypoint and black-frame readiness policy (3 attempts, 5s between unusable frames, mean brightness threshold). |
| R-R2 | Capture helper public CLI: absolute `--output`, refuse existing path, write exactly one JPEG, print JSON with required keys: `ok`, `path`, `mimeType`, `width`, `height`, `bytes`, `timestamp`. Optional existing key: `meanBrightness`. |
| R-R3 | **Grok (Ship A)** default frame directory: `$HOME/.agent-vision/frames` (create on demand, mode `0700` on dirs when created by Agent Vision tooling). |
| R-R4 | **Codex (Ship A):** keep `$HOME/.codex/agent-vision/frames` and existing skill/command paths. **No migration required for Ship A.** Any future Codex migration is a separate change with its own matrix (T-C.4a–g). |
| R-R5 | Shared binaries must not hardcode a single host’s versioned plugin cache path as the only way to find the app. |
| R-R6 | **Normative defaults:** `AGENT_VISION_HOME` default `$HOME/.local/share/agent-vision` containing `dist/AgentVision.app` and `dist/agent-vision-capture-file`. Capture helper invocation in Grok skill uses either that absolute path or `agent-vision-capture-file` on PATH after install places a shim under `$HOME/.local/bin`. On total miss → **fail with explicit error**; never screenshots, never existing photos, never alternate camera APIs. |

### 5.3 Grok host adapter

| ID | Priority | Requirement |
| --- | --- | --- |
| R-G1 | Ship A Must | Grok-discoverable skill `name: agent-vision` exposes `/agent-vision` with arguments `snapshot \| streaming` (and documents roast/mood as unavailable or Milestone 2 until shipped). |
| R-G2 | Ship A Must | Frontmatter `disable-model-invocation: true`. |
| R-G3 | Ship A Must | For snapshot (and later roast/mood), **first** tool action is capture (create frame dir + run capture helper). No repository orientation before capture. |
| R-G4 | Ship A Must | After Phase 0 decision record, vision ingest uses the proven path (candidate: `read_file` on absolute JPEG after `ok: true`). |
| R-G5 | Ship A Must | If Phase 0 fails, do not ship snapshot-as-success with metadata-only inspection. Document and prove alternate ingest first. |
| R-G6 | Ship A Must | Skill uses install-stamped absolute helper path and/or PATH shim per R-R6 — **not** `~/.codex/plugins/cache/local/agent-vision/<version>/...` as the sole path, and **not** `GROK_PLUGIN_ROOT` as primary resolver. |
| R-G7 | Ship A Must | Streaming and stop-streaming launch no process; return **version-agnostic** fixed disabled / no-session copy (D12). |
| R-G8 | Ship A Must | Installer/plugin must not register Agent Vision MCP in plugin config or `~/.grok/config.toml`. |
| R-G9 | Ship A Must | Sandbox: supported = sandbox off. Restricted profiles unsupported for capture → explicit fail closed (D6). |
| R-G10 | Ship A Must | On capture failure (`ok: false`, missing helper, permission denied), report helper/error text; **must not** invent scene content from metadata. (When roast/mood exist: must not roast/mood-calibrate from metadata.) |
| R-G11 | Ship A Must | Public skill name is `agent-vision` only for user-invocable Grok surface (D8). |
| R-G12 | Ship A Should | Document qualified slash forms (`user:agent-vision`, `plugin:agent-vision`) if name collision occurs. |
| R-G13 | Milestone 2 Must | Grok roast/mood require either a Grok-native second-pass isolation design or an explicit reduced product claim; skill phrase asserts alone are insufficient. |

### 5.4 Codex compatibility (Must)

| ID | Requirement |
| --- | --- |
| R-C1 | Existing Codex snapshot/roast/mood remain available; Ship A does not rewrite Codex skill/command paths. |
| R-C2 | Codex install still refuses production MCP registration and excludes `agent-vision-mcp` from packaged user runtime. |
| R-C3 | If a later change touches shared path/env for Codex, update skill/command **and** `install-local.sh` dry-run snippets **and** `test-slash-commands.sh` in the same change. |
| R-C4 | **Ship B Must:** Concurrent Codex + Grok install: both hosts work; single app identity; no MCP on either; path strategy documented. Ship A: Grok runtime may coexist with Codex cache install without removing Codex files. |

### 5.5 Install / uninstall

| ID | Priority | Requirement |
| --- | --- | --- |
| R-I1 | Ship A Must | **Runtime install** stages signed app + capture helper to `$AGENT_VISION_HOME` (default `$HOME/.local/share/agent-vision`) and installs PATH shim when practical. |
| R-I2 | Ship A Must | Grok enable installs/registers skill or plugin **without** starting the camera. |
| R-I3 | Ship A Must | Uninstall Grok removes skill/plugin registration; does **not** remove shared runtime if Codex (or user) still needs it. |
| R-I7 | Ship A Must | **Symmetric dual-host uninstall:** removing Codex adapter must not remove shared runtime if Grok still needs it; full uninstall removes adapters + optional runtime + asserts no MCP leftovers. |
| R-I8 | Ship A Must | Runtime install **preserves codesign identity** of packaged `AgentVision.app` when possible (copy without re-signing); run `codesign --verify --deep --strict`; document that identity change implies new TCC camera grant. |
| R-I4 | Ship A Must | Split entrypoints: `install-runtime`, existing Codex install path, `install-grok` (and matching uninstalls). |
| R-I5 | Ship B Should | Packaged release may ship both host adapters; user may install one or both. |
| R-I6 | Could | `grok plugin install zfifteen/agent-vision --trust` from GitHub without path surgery (still requires separate runtime install under strategy A). |
| R-I9 | Ship A Must | Install/enable/trust paths must not include hooks that launch the camera or capture helper. |

### 5.6 Documentation and naming

| ID | Priority | Requirement |
| --- | --- | --- |
| R-D1 | Ship A Should / Ship B Must | README states host support level honestly (experimental Grok vs full multi-host). |
| R-D2 | Should | Naming contract updated only if new public identifiers appear (prefer `agent-vision`). |
| R-D3 | Ship A Should / Ship B Must | PRIVACY.md mentions Grok Build as an additional local host when Grok is shipped. |
| R-D4 | Could | Codex and Grok install docs cross-link. |
| R-D5 | Ship B Must | README, INSTALL (or host install docs), PRIVACY fully describe multi-host, no production MCP, frame locations, per-host install/uninstall before `1.1.0` claim. |
| R-D6 | Ship A Should | Frame retention: document that JPEGs remain under `~/.agent-vision/frames` until user deletes; optional uninstall note. |

### 5.7 Explicit non-requirements (Won’t)

| ID | Statement |
| --- | --- |
| R-W1 | Won’t add production MCP tools for Grok in this initiative. |
| R-W2 | Won’t implement streaming start/stop runtime here. |
| R-W3 | Won’t create a separate GitHub product solely for Grok. |
| R-W4 | Won’t require nested `codex exec` from Grok sessions. |
| R-W5 | Won’t ship production hooks that launch the camera on session start. |
| R-W6 | Won’t treat restricted Grok sandbox profiles as supported in Ship A. |
| R-W7 | Won’t embed `dist/` in the Grok plugin (strategy B) in Ship A. |
| R-W8 | Won’t migrate Codex frame/cache paths as part of Ship A. |

---

## 6. Success criteria

### 6.1 Ship A gate (first “works on Grok” claim)

On a developer Mac (sandbox off), all of:

1. **Phase 0** controlled-scene vision evidence recorded (no private images in git).
2. Runtime install to default `AGENT_VISION_HOME`; `codesign --verify --deep --strict` passes; **no** Agent Vision process after install.
3. `/agent-vision snapshot` in Grok: first action capture; `ok: true`; file under `~/.agent-vision/frames`; model describes ground-truth scene details via proven ingest; residual process gone (baseline-PID poll).
4. Idle Grok, unrelated prompt, streaming, stop-streaming: **zero new** Agent Vision processes.
5. T-G.10 static + behavioral: no capture without slash.
6. Capture failure path: explicit error; no invented scene (R-G10).
7. Static `test-grok-adapter.sh` green; empty/absent MCP for Agent Vision.
8. Codex: if Codex files untouched, record “Codex frozen”; if touched, full dry-run + slash matrix green.
9. Docs state experimental/Ship A scope honestly (not `1.1.0` multi-host unless Ship B also green).

### 6.2 Ship B gate (`1.1.0` multi-host)

All of Ship A, plus:

1. Dual-host install/uninstall matrix (T-U.*, R-I7, R-C4).
2. R-D5 documentation complete.
3. If Grok roast/mood claimed: R-G13 isolation + mood collateral / roast safety probes.
4. Version branding and release packaging explicit.

---

## 7. Target design

### 7.1 Logical layout (Ship A)

```text
agent-vision/
  Sources/                         # shared Swift (minimal change)
  dist/                            # build outputs
  skills/ + commands/              # KEEP Codex sources of truth (frozen)
  hosts/grok/
    plugin.json                    # Grok root convention (D11)
    skills/agent-vision/SKILL.md
  scripts/
    install-runtime.sh             # NEW
    install-grok.sh / uninstall-grok.sh
    install-local.sh               # existing Codex; may call install-runtime later
    test-grok-adapter.sh           # NEW
    test-capture-file-cli.sh       # NEW (errors always; live success env-gated)
  docs/
```

**Do not** move Codex into `hosts/codex/` in Ship A. Optional later cleanup only.

### 7.2 Runtime path (Ship A — Grok snapshot)

```text
User: /agent-vision snapshot
  → Grok skill (disable-model-invocation)
  → mkdir -p "$HOME/.agent-vision/frames" (0700)
  → agent-vision-capture-file --output "$ABS_JPEG" --json
       (PATH shim or $AGENT_VISION_HOME/dist/... absolute)
  → verify ok:true && path exists
  → read_file(abs path)   # after Phase 0 proof
  → Markdown image link + analysis
  → no residual Agent Vision process
```

Codex path unchanged (skill → Codex cache helper → `~/.codex/agent-vision/frames` → Markdown / `codex exec -i`).

### 7.3 Path resolution (normative — install-time, not skill-time cascade)

| Item | Normative value |
| --- | --- |
| `AGENT_VISION_HOME` | Default `$HOME/.local/share/agent-vision` |
| App | `$AGENT_VISION_HOME/dist/AgentVision.app` |
| Helper | `$AGENT_VISION_HOME/dist/agent-vision-capture-file` |
| PATH shim | `$HOME/.local/bin/agent-vision-capture-file` → helper (when install can write it) |
| Grok frames | `$HOME/.agent-vision/frames` |
| Codex frames (Ship A) | `$HOME/.codex/agent-vision/frames` (unchanged) |
| `GROK_PLUGIN_ROOT` | Not used for capture helper resolution |

Grok skill template uses **one** of:

```bash
# Preferred after install-runtime
agent-vision-capture-file --output "$OUTPUT" --json
```

or the absolute default:

```bash
"$HOME/.local/share/agent-vision/dist/agent-vision-capture-file" --output "$OUTPUT" --json
```

Missing helper → explicit failure message instructing user to run runtime install.

### 7.4 Grok skill contract (Ship A outline)

```yaml
name: agent-vision
description: >-
  Explicit local Mac camera snapshot for Grok Build via Agent Vision.
  Use only when the user invokes /agent-vision (snapshot or streaming args).
  Do not auto-start the camera.
disable-model-invocation: true
argument-hint: snapshot|streaming
compatibility: >-
  macOS; Grok sandbox off; requires Agent Vision runtime install
  (AgentVision.app under AGENT_VISION_HOME).
```

Body must encode:

- camera-first discipline for `snapshot`,
- single capture command template (PATH or absolute default),
- snapshot → proven vision ingest + Markdown image link,
- streaming / stop-streaming **version-agnostic** fixed strings, no process,
- capture failure reporting (R-G10),
- no MCP tools,
- no `codex exec` requirement,
- no sole dependency on Codex plugin cache paths,
- roast/mood: “not in Ship A” or forward reference to Milestone 2 (do not implement half measures).

### 7.5 MCP policy

| Surface | Policy |
| --- | --- |
| Grok plugin | Omit MCP or empty `mcpServers` only |
| Production Codex package | Remain empty (1.0.3) |
| Source `MCPServer.swift` | Dev/tests only; not installed for Grok |
| `~/.grok/config.toml` | Installer must not add Agent Vision MCP |

### 7.6 Streaming

Disabled with version-agnostic fixed user-visible copy; no process launch. Full redesign is a separate initiative.

### 7.7 Milestone 2 — Grok roast / mood (not Ship A)

Only after:

1. Ship A snapshot boring and lifecycle green,
2. Explicit isolation design (e.g. headless second-pass with image input, or other host-enforced fence),
3. R-G13 + roast safety + mood collateral tests.

Do not claim Codex parity solely via in-session `read_file` + skill obedience.

---

## 8. Implementation plan

### Phase 0 — Vision contract proof (blocker)

**Objective:** Prove Grok can see a real Agent Vision JPEG under a **controlled scene**.

| Step | Work |
| --- | --- |
| 0.1 | Place 3 known props (A/B/C) in frame; do **not** name them in the model prompt. |
| 0.2 | Capture JPEG via helper to `~/.agent-vision/frames/probe-*.jpg`. |
| 0.3 | Grok session: `read_file` absolute path; ask only for visible objects/colors/layout (no prop names in prompt). |
| 0.4 | Score with checklist: ≥2 of 3 ground-truth details; zero confident false details. |
| 0.5 | Optional T-0.3: unusable/black fixture if available. |
| 0.6 | Write evidence note under `docs/evidence/` (transcript summary, date, pass/fail). **No private images in git.** |
| 0.7 | If fail: stop Ship A skill work; prototype alternate ingest; re-run Phase 0. |

**Exit criteria:** Written “primary vision ingest = …” decision with one passing controlled-scene demonstration.

### Phase 0b — Sandbox / path policy confirmation

| Step | Work |
| --- | --- |
| 0b.1 | Confirm D6: sandbox off works for mkdir frame dir + `open` app + write JPEG. |
| 0b.2 | Spot-check restricted profile: expect fail closed (document actual error). |
| 0b.3 | Record results in evidence note. |

### Phase 1 — Runtime install only (no Codex skill rewrite)

**Objective:** Stable shared home for Grok without touching Codex contracts.

| Step | Work |
| --- | --- |
| 1.1 | Implement `scripts/install-runtime.sh` → `$AGENT_VISION_HOME` layout; copy signed app **without re-sign** when possible; `codesign --verify --deep --strict`. |
| 1.2 | PATH shim to `$HOME/.local/bin/agent-vision-capture-file` when possible. |
| 1.3 | Create `~/.agent-vision` with `0700` if installer owns that step. |
| 1.4 | Assert no camera process after install (baseline-PID). |
| 1.5 | Leave Codex `install-local.sh` / skill paths **unchanged**. |

**Exit criteria:** Helper runs from shared home; JSON contract unchanged; R-I8 hold.

### Phase 2 — Grok skill (snapshot only)

| Step | Work |
| --- | --- |
| 2.1 | Add `hosts/grok/skills/agent-vision/SKILL.md` per §7.4. |
| 2.2 | Encode R-G1–R-G11 for Ship A; tool names match live Grok harness (`run_terminal_cmd` / interactive equivalent — verify in Phase 0/2). |
| 2.3 | Single skill source of truth (no dual `commands/` unless required). |
| 2.4 | Manual matrix: snapshot, streaming, stop-streaming, failure, auto-invoke negative. |

**Exit criteria:** Ship A manual matrix green on developer Mac, sandbox off.

### Phase 3 — Grok plugin packaging (skill-only)

| Step | Work |
| --- | --- |
| 3.1 | `hosts/grok/plugin.json` (name `agent-vision`, version aligned with packaging track). |
| 3.2 | No MCP registration; no `dist/` binaries in plugin (D2). |
| 3.3 | `install-grok` / `uninstall-grok`: enable skill or `grok plugin install <path> --trust` + enable as required; never launch camera. |
| 3.4 | Document two-step UX: runtime install, then Grok adapter. |
| 3.5 | `grok plugin validate` on host tree. |

**Exit criteria:** Fresh profile can install runtime + Grok adapter and pass lifecycle matrix.

### Phase 4 — Codex freeze verification (not path migration)

| Step | Work |
| --- | --- |
| 4.1 | Confirm Codex skill/command/installer **unchanged** (or only intentional non-path docs). |
| 4.2 | If any Codex file changed: run full dry-run + `test-slash-commands.sh`. |
| 4.3 | Ship A docs: honest experimental Grok section; do not claim full multi-host `1.1.0` unless Ship B done. |
| 4.4 | **Out of scope:** `hosts/codex/` move; Codex frame migration. |

### Phase 5 — Automation and Ship A hardening

| Step | Work |
| --- | --- |
| 5.1 | `scripts/test-grok-adapter.sh` (static contracts). |
| 5.2 | `scripts/test-capture-file-cli.sh` (error paths always; live success `AGENT_VISION_LIVE=1`). |
| 5.3 | Lifecycle harness with **baseline PID set** (pattern from `test-slash-commands.sh`). |
| 5.4 | Grok install/uninstall traceability doc (sibling to Codex traceability). |
| 5.5 | Ship A packaging decision (experimental / 1.0.4-class) — not `1.1.0` multi-host unless Ship B. |

### Milestone 2 — Grok roast / mood (after Ship A)

Separate plan amendment: isolation design, skill text, tests linking [mood validation collateral](./agent-vision-mood-validation-collateral.md), roast safety probes.

### Sequencing

```text
0 vision ──► 0b sandbox confirm ──► 1 runtime install ──► 2 snapshot skill
                                              │
                                              ▼
                                         3 plugin (skill-only)
                                              │
                                              ▼
                                         4 Codex freeze verify + honest docs
                                              │
                                              ▼
                                         5 automation / Ship A package
                                              │
                                              ▼
                                    Milestone 2 roast/mood (optional)
                                              │
                                              ▼
                                         Ship B 1.1.0 multi-host
```

**Highest risk:** Phase 0 vision ingest.  
**Highest regression risk:** Accidental Codex skill/path edits (avoid in Ship A).  
**Highest privacy risk:** MCP reintroduction or auto-invocation — R-P2, R-P3, R-G2, R-G8, T-G.10.

### Implementation notes

- Prefer skill Markdown and install scripts over Swift unless capture contract must change.
- Do not reintroduce `agent-vision-mcp` into packaged Grok or Codex user installs.
- Skill phrase asserts are necessary; process/vision behavioral gates are required for claims (D14).
- Keep roast/mood inference out of Swift.
- Never commit real user camera frames to git.
- Prefer copy-without-re-sign for runtime install (R-I8).

---

## 9. Test plan

### 9.1 Test layers

| Layer | What | Automate? | Where |
| --- | --- | --- | --- |
| L0 | Swift unit tests (readiness threshold + MCP protocol **dev surface**) | Yes CI | `swift test` — **does not** prove production capture-file |
| L1 | Static Grok/Codex contracts | Yes CI | `test-grok-adapter.sh`, install dry-run |
| L2 | Process lifecycle (baseline PID) | Yes local script | shell; fail nonzero |
| L3 | Live capture hardware | Env-gated | `AGENT_VISION_LIVE=1` |
| L4 | Host vision semantic | Manual rubric | Phase 0 + T-G.4 |
| L5 | Codex regression | Yes if Codex touched | dry-run + `test-slash-commands.sh` |

### 9.2 Phase 0 tests (vision gate)

| ID | Automate? | Procedure | Pass oracle |
| --- | --- | --- | --- |
| T-0.1 | Partial | Capture to `~/.agent-vision/frames/probe-*.jpg` | `ok: true`; JPEG magic; file size matches `bytes` if present |
| T-0.2 | Manual | Controlled scene; `read_file`; open-ended “what is visible?” | ≥2 of 3 ground-truth props; 0 confident false details |
| T-0.3 | Manual if fixture | Unusable/black image path | No rich invented desk scene |

**Fail action:** stop Ship A skill; fix ingest (R-G5).

### 9.3 Shared runtime tests

| ID | Automate? | Procedure | Pass |
| --- | --- | --- | --- |
| T-R.1 | Yes | `swift test` | Green |
| T-R.2 | Yes | CLI: missing `--output` / relative / existing file | Explicit JSON errors, nonzero exit (`test-capture-file-cli.sh`) |
| T-R.3 | Env-gated | Successful capture | Required JSON keys; bytes match; process exits |
| T-R.4 | Manual | Covered lens if safe | Retries then error; no successful black product frame |
| T-R.5 | Yes | Install runtime; baseline-PID before/after | No **new** Agent Vision processes |

### 9.4 Grok adapter matrix

| ID | Ship | Procedure | Pass oracle |
| --- | --- | --- | --- |
| T-G.1 | A | Install Grok adapter | Skill visible; no new camera process |
| T-G.2 | A | Idle Grok after install | No new Agent Vision processes |
| T-G.3 | A | Unrelated prompt | No new processes |
| T-G.4 | A | `/agent-vision snapshot` | Capture first; JPEG path; vision rubric; residual gone (poll 10s @ 0.5s) |
| T-G.5 | B/M2 | `/agent-vision roast` | Image + roast from vision; ≤400; safety probe |
| T-G.6 | B/M2 | `/agent-vision mood` | Silent; no leak; gates per mood collateral subset |
| T-G.7 | A | `/agent-vision streaming` | Fixed disabled text; no process |
| T-G.8 | A | stop streaming / turn off camera | Fixed no-session text; no process |
| T-G.9 | A | Capture failure | Exact error; no invented scene |
| T-G.10 | A | Auto-invoke attempts without slash | Static frontmatter + **no new processes** + positive slash control same setup |

### 9.5 Lifecycle / privacy process assertions

**Required pattern** (copy from `scripts/test-slash-commands.sh` / `test-streaming-interaction.sh`):

1. Record baseline PIDs matching Agent Vision patterns.
2. Run action.
3. Fail if **new** PIDs appear (except during allowed capture window).
4. After capture: poll up to **10s** every **0.5s** until no residual new processes; else fail.
5. Exit nonzero on failure — **never** `pgrep ... || true` as the sole assertion.

Patterns to watch (refine to reduce false positives):

```text
agent-vision-capture-file
agent-vision-mcp
AgentVision.app
mcp-fifo
```

MCP config: parse/assert no Agent Vision MCP server keys in `~/.grok/config.toml` / plugin MCP files; **fail closed** if present.

### 9.6 Codex regression

| ID | When | Procedure | Pass |
| --- | --- | --- | --- |
| T-C.1 | Always for Ship A docs | Note Codex frozen **or** run install dry-run | No MCP; helper present if install run |
| T-C.2 | If Codex touched | Codex snapshot | JPEG materializes; camera stops |
| T-C.3 | If Codex touched | Streaming disabled | No process |
| T-C.4 | **Only if Codex paths change** | Migration submatrix below | All rows green |

**T-C.4 submatrix (path migration PRs only):**

| ID | Procedure | Pass |
| --- | --- | --- |
| T-C.4a | Dry-run snippets match files | install dry-run green |
| T-C.4b | Live Codex snapshot under documented frame dir | path prefix assert |
| T-C.4c | Legacy dir still works if dual-support | ok + file |
| T-C.4d | Symlink/redirect policy if used | documented policy holds |
| T-C.4e | Helper resolution not only `.../1.0.3/...` | static + optional live |
| T-C.4f | Packaged install excludes `agent-vision-mcp` | existing checks |
| T-C.4g | Uninstall one host does not break the other | dual-host matrix |

Ship A **skips** T-C.4 by freezing Codex paths (D4).

### 9.7 Static contract tests (`test-grok-adapter.sh`)

1. Skill exists; frontmatter `name: agent-vision`, `disable-model-invocation: true`.
2. Body: camera-first discipline; version-agnostic streaming disabled copy; PATH or absolute default helper; `read_file` (or frozen Phase 0 ingest); **no** `codex exec` requirement; **no** sole Codex `1.0.3` cache path.
3. `plugin.json` name/version sane; no camera MCP advertisement.
4. Empty/absent MCP under Grok host tree.
5. `bash -n` on new install/uninstall scripts.
6. Roast/mood: either absent from Ship A skill or clearly Milestone 2-only.

### 9.8 Permission and signing

| ID | Procedure | Pass |
| --- | --- | --- |
| T-S.1 | First capture (manual) | TCC prompt for Agent Vision app name when needed |
| T-S.2 | After runtime install | `codesign --verify --deep --strict` |
| T-S.3 | Relaunch after grant | No spurious re-prompt unless identity changed |
| T-S.4 | Document-only if re-sign tested | Identity change → expected re-prompt |

### 9.9 Uninstall tests

| ID | Procedure | Pass |
| --- | --- | --- |
| T-U.1 | Uninstall Grok only | Slash gone; runtime may remain |
| T-U.2 | Uninstall runtime; Grok skill remains | Explicit missing-helper failure |
| T-U.3 | Full uninstall | No MCP leftovers; adapters removed |
| T-U.4 | Dual-host: uninstall Codex only | Grok runtime retained if Grok still installed |

### 9.10 Acceptance checklists

#### Ship A (minimum)

- [ ] Phase 0 controlled-scene evidence (T-0.1–T-0.2)
- [ ] Phase 0b sandbox note (supported = off)
- [ ] T-R.1, T-R.2; T-R.3 if hardware available
- [ ] T-R.5 runtime install lifecycle
- [ ] T-S.2 codesign verify
- [ ] `test-grok-adapter.sh` green
- [ ] Baseline-PID: install-grok, idle, unrelated, streaming, stop, post-snapshot residual
- [ ] T-G.4, T-G.7, T-G.8, T-G.9, T-G.10
- [ ] Codex frozen note **or** T-C.1–T-C.3
- [ ] Honest docs (experimental Grok; not false `1.1.0` multi-host)

#### Ship B / Milestone 2 (additional)

- [ ] T-U.1–T-U.4 dual-host
- [ ] R-D5 docs
- [ ] T-G.5 / T-G.6 with rubrics + mood collateral subset if claimed
- [ ] R-G13 isolation documented and tested
- [ ] Version tag `1.1.0` decision recorded

---

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| `read_file` lacks reliable vision | Blocks Ship A snapshot claim | Phase 0 controlled rubric; stop if fail |
| Restricted sandbox write/open fails | Capture fails | D6 unsupported + fail closed; 0b evidence |
| Skill-time path cascade | Flaky first command | D3 install-time + PATH shim |
| Strategy B / plugin binaries | Signing + hash-path churn | D2 lock A |
| Codex path rewrite thrash | Break dry-run / users | D4 freeze; T-C.4 only on migration PRs |
| MCP “for convenience” | 1.0.2-class privacy bug | R-P3, R-G8, R-W1; static + config asserts |
| Auto-invoke camera | Non-consensual capture | R-G2 + instrumented T-G.10 |
| Metadata roast/mood on Grok | False product claim | Ship A excludes; Milestone 2 isolation (R-G13) |
| Codesign/TCC after relocate | Capture permission fail | R-I8 copy-without-re-sign + verify |
| Dual-host uninstall footgun | Deletes runtime other host needs | R-I7, T-U.4 |
| Two-step install half-done | Skill present, helper missing | Explicit error (R-R6); install docs |
| Skill phrase asserts only | Green CI, bad behavior | D14; baseline-PID + Phase 0 |
| Over-branding 1.1.0 early | Support debt | D10 Ship A vs Ship B tracks |

---

## 11. Remaining open questions

Closed for Ship A:

1. **Phase 0 outcome:** `read_file` on absolute JPEGs provides reliable vision (PASS — evidence note).
2. **PATH shim:** Installed to `$HOME/.local/bin`; skill also documents absolute default helper path.

Still open (not blocking Ship A):

1. **Milestone 2 isolation mechanism** for Grok roast/mood.
2. **Ship B** dual-host lifecycle product packaging and `1.1.0` branding.

---

## 12. Deliverables checklist

| Deliverable | Status |
| --- | --- |
| Branch `feat/grok-build-compatibility` | Created |
| Plan + expert review + revision | Done |
| Phase 0 evidence | Done — [evidence](./evidence/phase-0-vision-ingest-2026-07-13.md) |
| Runtime + Grok install scripts | Done |
| Grok skill + plugin | Done under `hosts/grok/` |
| Static + CLI tests | Done |
| Public docs (README, INSTALL, PRIVACY, RELEASE_NOTES, naming, materialization, Grok traceability) | Done |
| External live Grok session | Green (operator-validated) |
| Milestone 2 roast/mood | Deferred |
| Ship B `1.1.0` | Deferred |

---

## 13. References

### In-repo

- [agent-vision-grok-build-compatibility-review.md](./agent-vision-grok-build-compatibility-review.md) — expert review applied herein
- [agent-vision-file-materialization-spec.md](./agent-vision-file-materialization-spec.md)
- [agent-vision-install-uninstall-traceability.md](./agent-vision-install-uninstall-traceability.md) — Codex 1.0.3
- [agent-vision-grok-install-uninstall-traceability.md](./agent-vision-grok-install-uninstall-traceability.md) — Grok Ship A
- [agent-vision-native-camera-redesign-spec.md](./agent-vision-native-camera-redesign-spec.md)
- [agent-vision-mood-technical-note.md](./agent-vision-mood-technical-note.md)
- [agent-vision-mood-validation-collateral.md](./agent-vision-mood-validation-collateral.md)
- [agent-vision-naming-contract.md](./agent-vision-naming-contract.md)
- [README.md](../README.md), [PRIVACY.md](../PRIVACY.md), [INSTALL.md](../INSTALL.md)
- Codex skill: `skills/camera-control/SKILL.md`
- Codex command: `commands/agent-vision.md`

### External (Grok Build)

- `~/.grok/docs/user-guide/08-skills.md` — skills, `disable-model-invocation`
- `~/.grok/docs/user-guide/09-plugins.md` — plugin layout, trust, `GROK_PLUGIN_ROOT` (hooks)
- `~/.grok/docs/user-guide/07-mcp-servers.md`
- `~/.grok/docs/user-guide/18-sandbox.md` — write roots for restricted profiles

---

## 14. Next implementation action

Ship A is complete for public release of Grok snapshot support.

```text
Optional next: Milestone 2 (Grok roast/mood isolation) or Ship B dual-host packaging.
Public users: INSTALL.md (Grok Build section) + /agent-vision snapshot.
```
