# Expert Review: Agent Vision Grok Build Compatibility Plan

**Reviewed document:** [agent-vision-grok-build-compatibility.md](./agent-vision-grok-build-compatibility.md)  
**Review date:** 2026-07-13  
**Mode:** Expert (4 specialists, read-only analysis; leader synthesis + this write-up)  
**Branch context:** `feat/grok-build-compatibility`  
**Original verdict:** **Proceed with major revisions** — strong privacy skeleton; not yet implement-ready or release-grade as written.  
**Remediation status:** **Applied 2026-07-13** — plan rewritten to incorporate findings below. This review remains the historical audit trail; the **normative plan is the revised compatibility doc**.

### Remediation map (finding → plan change)

| Finding | Disposition in revised plan |
| --- | --- |
| F-C1 Sandbox vs paths | **D6**, **R-G9**, Phase 0b, fail closed on restricted profiles |
| F-C2 Path migration under-specified | **D4/D5**, **R-R4** Codex freeze Ship A; T-C.4 only on migration PRs |
| F-C3 Test plan not a gate | §9 rewritten: baseline-PID, controlled Phase 0, Ship A vs B checklists |
| F-H1 Skill-time env cascade | **D3**, **R-R6**, **R-G6** — install-time + PATH shim; demote `GROK_PLUGIN_ROOT` |
| F-H2 Strategy A vs B open | **D2**, **R-W7** — A locked |
| F-H3 Codex freeze | **D4**, Phase 4 = verify freeze not migrate |
| F-H4 Default path incomplete | **R-R6** normative defaults |
| F-H5 Codesign after relocate | **R-I8**, T-S.2 |
| F-H6 Dual-host uninstall | **R-I3**, **R-I7**, T-U.1–T-U.4 |
| F-H7 Roast/mood isolation | **D7**, Milestone 2, **R-G13**; Ship A snapshot only |
| F-H8 §5 / checklist gaps | §6 Ship A/B gates; §9.10 checklists |
| F-H9 Version-locked streaming copy | **D12**, **R-G7** version-agnostic |
| F-H10 Overbuilt first ship | Ship A vs Ship B / Milestone 2 tracks |
| F-M1 Skill name | **D8**, **R-G11** |
| F-M5 Tool IDs | Open Q: confirm live tool names in Phase 0/2 |
| F-M10 Plugin layout | **D11** root `plugin.json` |
| F-M11 hosts/codex move | Out of Ship A |
| Version branding | **D10** — `1.1.0` reserved for Ship B |

---

## 1. Executive summary (original)

The plan correctly freezes the hard product lessons from 1.0.2/1.0.3: **no production MCP**, **no eager camera process**, **one signed capture stack**, **file materialization as the durable image contract**, and **Phase 0 vision proof before skill theater**. Same-repo multi-host (not a fork) is the right long-term repository policy.

Where it falls short is treating **full multi-host productization**—shared runtime home, neutral frame-path migration, dual installers, `hosts/` layout, plugin packaging, Codex realignment, and roast/mood parity—as the first unit of work for an adapter that is still **unproven on Grok**. Several Must-level operational constraints (sandbox write roots, stable codesign after relocate, dual-host uninstall symmetry, install-time path stamping vs skill-time env cascades) are risks or open questions rather than closed, testable requirements. The test plan is a solid inventory but **not a falsifiable ship gate**: process checks are weaker than existing Codex scripts, Phase 0 vision scoring is gameable, and mood/roast policy collateral is not wired into acceptance.

**Recommended posture:** keep the document as the multi-host *north star*, but **shrink the first ship** to Phase 0 + one runtime install story + Grok **snapshot** (streaming disabled, no MCP), freeze Codex paths in place, lock binary strategy A, and reserve `1.1.0` multi-host branding until dual-host lifecycle and (optionally) roast/mood isolation are real.

**Post-remediation:** That posture is now encoded as closed decisions D1–D14, Ship A vs Ship B gates, and a tightened test plan in the revised compatibility document.

---

## 2. Specialist ledger

| Slot | Role | Task ID | Status | Counts toward 4? | Rewaits | Replaces | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Requirements completeness & consistency | `019f5d1e-066f-7883-be25-4cd3f0dd83d0` | success | yes | 0 | 0 | MoSCoW, 1.0.3 invariants, §5 gaps |
| 2 | Implementation plan feasibility & sequencing | `019f5d1e-066f-7883-be25-4ceb288f180f` | success | yes | 0 | 0 | Paths, sandbox, install graph, phase order |
| 3 | Test plan adequacy & falsifiability | `019f5d1e-066f-7883-be25-4cf2c1ca9734` | success | yes | 0 | 0 | L0–L5, pgrep, ship gate |
| 4 | Contrarian product-architecture critique | `019f5d1e-066f-7883-be25-4d0a5502a054` | success | yes | 0 | 0 | Scope, isolation, versioning, 1.0.2 analogues |

**successful_count = 4 of 4.** Full-team synthesis below.

---

## 3. Consensus strengths

All four specialists agreed on these positives:

1. **1.0.3 privacy lifecycle is first-class**, not folklore — R-P1–P3, R-P8, R-G2, R-G7–G8, R-C2 align with README, PRIVACY, INSTALL, and install/uninstall traceability.
2. **Shared signed app + capture-file, no second repo/app** is the correct architectural freeze unless Phase 0 forces a new permission principal (unlikely).
3. **Phase 0 vision gate before packaging theater** is the right engineering risk order: do not claim roast/mood (or even “inspect this JPEG”) on an unproven ingest path.
4. **No production MCP** for camera lifecycle must not be compromised; reopening MCP for “convenience” is the 1.0.2 failure mode in a new coat.
5. **Camera-first skill discipline** (R-G3) correctly ports a real Codex production failure (repo orientation before capture).
6. **Path de-Codexification for Grok** is necessary: live Codex skill/command hardcode `~/.codex/plugins/cache/local/agent-vision/1.0.3/...` and must not become Grok’s only resolution story.
7. **Prefer skill/install Markdown over Swift** remains true end-to-end for this initiative; capture CLI already matches the one-shot contract.

---

## 4. Cross-cutting findings (synthesized)

Findings are ordered by severity. Slot tags: **S1** requirements, **S2** implementation, **S3** tests, **S4** contrarian.

### 4.1 Critical

| ID | Finding | Sources |
| --- | --- | --- |
| F-C1 | **Sandbox vs path defaults are unresolved.** Grok `workspace` / `read-only` / `strict` profiles typically allow writes under CWD, `~/.grok/`, and temp — not proposed `~/.agent-vision/frames` or `~/.local/share/agent-vision`. No Must/Should that frame dir + runtime home are sandbox-compatible, or that sandboxed sessions are unsupported with fail-closed errors. Risk table mentions sandbox; requirements and tests do not. | S1, S2, S3 |
| F-C2 | **Path migration / dual-host path story is under-specified for the regression risk claimed.** R-R3/R-R4 leave migration open (Q3); T-C.4 is soft. Changing Codex skill/command without updating `install-local.sh` dry-run snippet corpus and `test-slash-commands.sh` will break Codex or ship split-brain. | S1, S2, S3 |
| F-C3 | **Test plan is not a release-grade gate.** Automation claims outrun assets (`test-grok-adapter.sh` does not exist; L0 is mostly MCP unit tests, not production capture-file). Several pass criteria are subjective; `pgrep \|\| true` is non-failing and weaker than existing Codex baseline-PID scripts. | S3 (with S1 on §5 loopholes) |

### 4.2 High

| ID | Finding | Sources |
| --- | --- | --- |
| F-H1 | **Skill-time env cascade (`AGENT_VISION_HOME` → `GROK_PLUGIN_ROOT` → default) is a poor primary design.** Skills are Markdown instructions; env may be unset. **`GROK_PLUGIN_ROOT` is documented for plugin hooks**, not reliable skill/shell context. Prefer install-time single default + PATH shim (e.g. `~/.local/bin/agent-vision-capture-file`). | S2, S1 |
| F-H2 | **Binary strategy A vs B is not locked.** Body prefers A; Open Q2 reopens it. Guarantees re-litigation in Phase 2–3. Lock **A: skill/plugin + separate runtime install** for first ship. | S2, S4 |
| F-H3 | **Codex path freeze should be the 1.1.0 default, not “align in Phase 4.”** Highest Codex regression risk starts the moment skill/installer contracts change. Minimal-safe approach: Grok-only new paths; leave Codex 1.0.3 cache + `~/.codex/agent-vision/frames` until a deliberate migration. | S2, S4, S3 |
| F-H4 | **Default path contract incomplete.** `AGENT_VISION_HOME` default is “proposed” / “for example”; no single normative default + resolution-failure string as Must. | S1, S2 |
| F-H5 | **Codesign / TCC identity after relocate** is under-required. R-P8 needs Launch Services; missing Must that runtime install preserves packaged codesign identity (copy without re-sign when possible; `codesign --verify`; document re-prompt on identity change). | S1, S2 |
| F-H6 | **Dual-host uninstall/coexistence incomplete.** Grok uninstall retaining runtime is partial; missing symmetric “Codex uninstall must not remove runtime if Grok needs it,” concurrent dual-host success criterion, and release-gate T-U/T-S. | S1, S3 |
| F-H7 | **Grok roast/mood via in-session `read_file` is a weaker isolation fence than Codex `codex exec -i`.** Full semantic parity is not free. Skill text is necessary but not sufficient; metadata roast can pass static phrase checks. Consider **snapshot-first ship**; treat roast/mood as a second milestone with isolation requirements. | S4, S3 |
| F-H8 | **§5 / §8.10 omit uninstall, signing, path-resolution failure, sandbox policy** even though §8 defines some of those tests. “Green or documented intentional skips” softens the gate. | S1, S3 |
| F-H9 | **Streaming disabled copy is version-locked to 1.0.3** in current Codex artifacts; multi-host target needs version-agnostic or release-aligned strings on both hosts. | S1, S2 |
| F-H10 | **First-ship scope is overbuilt** relative to user outcome “snapshot works in Grok.” Platform work (hosts/, dual install, frame migration, 1.1.0 brand, full parity) multiplies surface before one boring path exists. | S4, S2 |

### 4.3 Medium

| ID | Finding | Sources |
| --- | --- | --- |
| F-M1 | **Grok skill public name should be `agent-vision`**, not a port of Codex skill name `camera-control` (Codex uses command file for `/agent-vision`). Avoid dual user-invocable names. | S1, S2 |
| F-M2 | **Skill discovery collisions** (user/project/plugin qualified names) not required or tested. | S1, S2 |
| F-M3 | **Error UX not a MoSCoW Must for Grok** (report helper errors; no invent-from-metadata). Codex has this; Grok could drop it. | S1, S3 |
| F-M4 | **Docs + install split under-prioritized** as Should for a claimed multi-host release. | S1, S4 |
| F-M5 | **Tool ID accuracy:** Phase 2 cites `run_terminal_command`; headless docs use `run_terminal_cmd`. Static tests will break if wrong. | S1, S2 |
| F-M6 | **Frame retention / permissions / multi-user isolation** for host-neutral path (e.g. `0700`, uninstall delete option) missing. | S1, S3 |
| F-M7 | **T-0.2 “three concrete details” is gameable**; needs controlled scene + ground-truth checklist + anti-hallucination. | S3 |
| F-M8 | **T-G.10 frontmatter-only is insufficient**; need behavioral no-process oracle + positive slash control. | S3, S4 |
| F-M9 | **Mood confidence gates / roast safety collateral** exist but are not linked into §8 ship gate. | S3, S4 |
| F-M10 | **Plugin layout:** do not invent `.grok-plugin/` by analogy with `.codex-plugin/`; Grok uses root `plugin.json` + `skills/`. Plugins may need enable/trust; install without enable = missing slash. | S2 |
| F-M11 | **Physical `hosts/codex/` move** should be out of scope for first Grok cut; keep Codex tree in place. | S2, S4 |
| F-M12 | **Silent mood ethics:** command-level consent, disk JPEG, silent delivery shaping — harder to audit on Grok; plan ports silence as free. | S4 |
| F-M13 | **R-P1 “or equivalent Grok slash skill”** is soft given `disable-model-invocation: true` (slash-only in practice). | S1 |
| F-M14 | **L0 narrative overclaims:** `swift test` does not cover production capture-file path. | S3 |

### 4.4 Low

| ID | Finding | Sources |
| --- | --- | --- |
| F-L1 | Overlapping requirements (R-P2 ∩ R-G7 ∩ R-P3 ∩ R-G8) are consistent but can double-count in matrices. | S1 |
| F-L2 | Notarization optional/Could for public download; state explicitly. | S1 |
| F-L3 | Single version alignment across plugin.json / release tag / skill docs is only an open question. | S1, S4 |
| F-L4 | `NSCameraUsageDescription` still says “Codex session” — host-neutral copy polish. | S2 |
| F-L5 | Concurrent capture, rapid slash spam, full M1–M10 golden set — later. | S3 |

---

## 5. Requirements review (Slot 1 + synthesis)

### 5.1 What is solid

- Privacy Musts preserve the 1.0.3 hotfix intent.
- Won’t list (no production MCP, no streaming runtime, no second product, no nested `codex exec` on Grok) is appropriately tight.
- Vision proof + forbid metadata-only roast/mood (R-G4/R-G5) matches the file-materialization root cause.
- Test-oriented privacy matrix (T-G.*) is better than many planning docs.

### 5.2 Recommended requirement additions

| Suggested ID | Priority | Intent |
| --- | --- | --- |
| R-G9 | Must | Sandbox policy: works under default sandbox-off; for restricted profiles either unsupported + explicit error, or sandbox-writable frame/runtime locations with tests. |
| R-G10 | Must | Capture failure: report helper/error text; never roast/mood/invent scene from metadata. |
| R-G11 | Must | Public Grok skill `name` is `agent-vision`; no parallel user-invocable `camera-control` on Grok. |
| R-I7 | Must | Symmetric dual-host uninstall; full-uninstall definition. |
| R-I8 | Must | Runtime install preserves codesign identity; verify strict; document TCC re-prompt on identity change. |
| R-R6 | Must | Normative defaults for `AGENT_VISION_HOME` and frame dir; fail closed; never alternate image sources. |
| R-C4 | Must | Concurrent Codex + Grok install works; path migration strategy frozen before multi-host release claim. |
| R-D5 | Must (promote) | README/INSTALL/PRIVACY multi-host + no MCP before calling release multi-host. |
| R-X1 | Should | Version-agnostic streaming disabled copy. |
| R-X2 | Should | L0–L2 always-on without camera; L3–L4 env-gated. |
| R-X3 | Should | Frame dir user-only permissions; uninstall/docs for frame deletion. |

### 5.3 Recommended edits to existing

- **R-P1:** Slash-only explicit args; remove fuzzy “equivalent.”
- **R-I1 / R-I4:** Normative default path; promote install split (or `--host=`) to Must for multi-host *product* claim.
- **R-G4:** “After Phase 0 decision record…” not “primary design” while still a hypothesis in §2.2.
- **R-R2:** Pin JSON schema keys; optional fields separate.
- **§5:** Add dual-host uninstall, signing, missing-helper error, sandbox decision, frozen path migration.

---

## 6. Implementation plan review (Slot 2 + synthesis)

### 6.1 Phase ordering

**Keep:** Phase 0 first for truthful product claims.

**Fix sequencing:**

```text
0    Vision ingest proof (sandbox-off; optionally sandbox-on if claimed)
0b   Sandbox + frame-root policy decision
1a   Runtime home + capture helper (strategy A only); PATH shim; no Codex skill rewrite
2    Grok skill — snapshot first (roast/mood optional later)
3    Grok plugin (skill-only) + enable/trust + validate; no dist/ in plugin
4    Codex: docs + regression matrix; path changes only if forced by version bump
5    Static tests, release, Grok install/uninstall traceability
— later — hosts/codex move; frame path unification; roast/mood isolation milestone
```

### 6.2 Lock before coding (close open questions)

| Question | Expert recommendation |
| --- | --- |
| Binary distribution | **A only** for first ship |
| Frame paths | Grok: `~/.agent-vision/frames` **or** `~/.grok/agent-vision/frames` if sandbox-on is in scope; **Codex keeps** `~/.codex/agent-vision/frames` for first cut |
| Path resolution | Install-time default + PATH shim; **demote `GROK_PLUGIN_ROOT`** from primary capture resolver |
| Codex tree move | **Out of scope** for first Grok PR |
| Version branding | **Experimental / 1.0.4-class** until multi-host ops true; reserve **1.1.0** for dual-host support commitment |
| First feature set | **Snapshot + disabled streaming + no MCP**; roast/mood as milestone 2 unless isolation is designed |

### 6.3 Layout recommendation (minimal)

```text
agent-vision/
  Sources/ ...                 # unchanged
  dist/ ...
  skills/ + commands/          # KEEP as Codex sources of truth
  hosts/grok/
    plugin.json                # root convention, not .grok-plugin/
    skills/agent-vision/SKILL.md
  scripts/
    install-runtime.sh         # NEW
    install-grok.sh            # NEW
    install-local.sh           # Codex (existing); may call install-runtime later
```

### 6.4 Effort (rough consensus)

| Work | Size | Driver |
| --- | --- | --- |
| Phase 0 (+ 0b) | S | Manual sessions + policy decision |
| Runtime install + PATH | M–L | Codesign copy policy, packaging |
| Grok snapshot skill | S–M | Port + matrix |
| Grok plugin enable/uninstall | M | Trust/enable UX |
| Codex frozen + docs | S | Low if no path rewrite |
| Full roast/mood + path migration + dual brand | L | Avoid in first cut |

**Overall first useful ship (strategy A, Codex frozen, snapshot-only): M**, dominated by install path and Phase 0 — not Swift.

---

## 7. Test plan review (Slot 3 + synthesis)

### 7.1 Layer honesty

| Layer | Plan claim | Reality |
| --- | --- | --- |
| L0 | `swift test` | Real; covers readiness threshold + MCP protocol — **not** production capture-file |
| L1 | Static Grok contract | **Not implemented** — must write `test-grok-adapter.sh` |
| L2 | Process lifecycle | Plan’s `pgrep \|\| true` is **weaker** than Codex baseline-PID scripts |
| L3–L4 | Live capture + vision | Manual; Phase 0 rubric too soft |
| L5 | Codex regression | Strong assets exist; path migration rows weak |

### 7.2 Process checks — required pattern

Copy from `scripts/test-slash-commands.sh` / `test-streaming-interaction.sh`:

- Baseline PID set before action.
- Fail only on **new** matches.
- Include `mcp-fifo` / helper names carefully.
- Residual poll: define N (e.g. 10s) and interval.
- Nonzero exit on failure — no decorative `|| true` on assertions.

### 7.3 Phase 0 rubric upgrade

Replace freeform “three concrete details” with:

1. Controlled scene (known props A/B/C **not** named in the prompt).
2. Scorer checklist: ≥2 of 3 ground-truth details; zero confident false details.
3. Transcript + date in evidence note; **no private images in git**.
4. Black-frame / unusable fixture when available (T-0.3 required if fixture exists).

### 7.4 T-G.10 (disable-model-invocation)

| Check | Role |
| --- | --- |
| Static frontmatter | Necessary, insufficient |
| Host docs version noted | Semantics of the flag |
| Behavioral: no slash, camera-ish prompts | No new Agent Vision processes; no capture command in tool log if available |
| Positive control: slash snapshot | Does capture |

Do not treat “model said it can’t see” as pass.

### 7.5 Minimum ship gate vs should/could

**Minimum before any “Grok-compatible” claim:**

- [ ] Phase 0 controlled-scene evidence
- [ ] `swift test`
- [ ] Capture-file CLI error suite (+ live success or Phase 0 substitute)
- [ ] `test-grok-adapter.sh` static (frontmatter, empty MCP, no sole Codex cache path, streaming copy, camera-first text)
- [ ] Baseline-PID lifecycle: install-runtime, install-grok, idle, unrelated, streaming, stop, post-snapshot residual
- [ ] Manual T-G.4 snapshot + T-G.9 failure
- [ ] T-G.10 static + behavioral
- [ ] Codex dry-run + slash matrix **if** Codex files touched; else documented Codex-frozen
- [ ] Dual-host uninstall “runtime retained when other host present” if both installers exist
- [ ] Codesign verify on installed app
- [ ] Docs: multi-host privacy + install (even for experimental cut)

**Should (same release if claiming roast/mood):** roast safety probe; mood collateral subset; silent mood leak check.

**Could / defer:** concurrent capture; full M1–M10; headless CI vision; GitHub marketplace install as gate; `hosts/codex/` move.

### 7.6 Path migration submatrix (if Codex paths change)

If and only if Codex skill/command move:

| ID | Intent |
| --- | --- |
| T-C.4a | Dry-run snippets match files |
| T-C.4b | Live Codex snapshot under documented frame dir |
| T-C.4c | Legacy dir still works if dual-support |
| T-C.4d | Symlink/redirect policy if used |
| T-C.4e | Helper resolution not only `.../1.0.3/...` |
| T-C.4f | Packaged install excludes MCP wrapper |
| T-C.4g | Uninstall one host does not break the other |

**Expert preference:** avoid this matrix in the first Grok PR by freezing Codex paths.

---

## 8. Contrarian conclusions (Slot 4 + synthesis)

### 8.1 Thesis (accepted with nuance)

The plan is excellent as a **privacy-preserving multi-host north star** and weaker as a **first-delivery plan**. The risk of failing “like 1.0.2” is not only MCP reintroduction; it is any host lifecycle or convenience path that starts camera-capable code without explicit intent, plus **skill-as-kernel** green checks that do not enforce vision isolation.

### 8.2 Top failure modes to design against

1. Skill text / static asserts pass; production roast/mood is metadata-shaped.
2. Silent mood + failed/partial vision → un-auditable behavior shaping.
3. Premature multi-host reorg breaks Codex before Grok works.
4. Two-step install left half-done; skill present, helper missing, poor UX.
5. Plugin trust/post-install/helpfulness launches app; or leftover MCP binary gets registered later.

### 8.3 Thin path that captures ~80% of stated goal #1

1. Install runtime once (existing signed app + capture helper → one default home).
2. Grok skill: mkdir frames → capture → `read_file` → Markdown image.
3. Streaming fixed disabled string; empty MCP; `disable-model-invocation: true`.
4. One absolute helper path or PATH shim — no four-branch resolver in skill text.

Roast/mood/plugin marketplace/`hosts/`/Codex migration are the long tail and most of the risk.

---

## 9. Conflicts resolved

| Tension | Resolution |
| --- | --- |
| Phase 0 first vs packaging bottleneck | **Both:** Phase 0 first for truth; immediately after, **one** install story before full parity features. |
| Shared neutral frames (R-R3) vs freeze Codex | **Grok adopts neutral (or Grok-safe) path; Codex frozen** until deliberate migration PR. |
| Prefer A vs Open Q2 | **Lock A**; remove Q2 as open for this initiative. |
| Full roast/mood Musts vs weaker Grok isolation | **Keep product semantics in the north-star doc**; **scope first ship to snapshot** or require isolation design before Grok roast/mood Musts apply. |
| 1.1.0 multi-host brand vs experimental skill | **Do not cut 1.1.0** until dual-host snapshot + lifecycle matrices are green and support commitment is intentional. |
| “Grok is a better host” | **Not established.** Better for avoiding Codex plugin MCP quirks; unproven/worse for roast/mood isolation and install maturity until measured. |

---

## 10. Overall recommendation

### Proceed with major revisions

**Do next (implementation order after this review):**

1. Update the compatibility doc (or a short addendum) with **closed decisions**: strategy A, Codex path freeze, first-ship = snapshot, versioning posture, sandbox policy, install-time path stamp.
2. **Phase 0** controlled-scene vision evidence.
3. **`install-runtime` + PATH shim** (no camera on install).
4. **Grok skill** for snapshot only (+ streaming disabled).
5. Static + baseline-PID lifecycle tests.
6. Then optionally: roast/mood milestone, plugin packaging polish, Codex path migration, 1.1.0 release train.

**Do not do in the first cut:**

- Physical `hosts/codex/` migration.
- Plugin-embedded `dist/` (strategy B).
- Skill-time multi-env resolution as primary design.
- Claiming full multi-host 1.1.0 support on an unreleased experimental skill alone.
- Shipping Grok roast/mood as “same as Codex” without isolation or a deliberate reduced claim.

**Never compromise:**

- No production MCP for camera lifecycle.
- No camera process on install / enable / idle / unrelated / streaming / stop.
- No metadata-only roast/mood as success.
- Signed `AgentVision.app` as permission principal.
- `disable-model-invocation: true` on Grok.
- Frames local only.
- Codex 1.0.3 package must not re-gain MCP via Grok work.

---

## 11. Suggested edits to the source plan (checklist for author)

Revision backlog for `agent-vision-grok-build-compatibility.md` (**completed 2026-07-13**):

- [x] Add § “Closed decisions” locking A, Codex freeze, snapshot-first, versioning.
- [x] Add R-G9–G11, R-I7–I8, R-R6, R-C4, R-D5 (or equivalent).
- [x] Soften or stage roast/mood Musts for Grok first ship vs north-star product.
- [x] Replace skill-time resolution cascade with install-time + PATH shim; demote `GROK_PLUGIN_ROOT`.
- [x] Add Phase 0b sandbox; fix Phase 1 vs Phase 4 regression narrative.
- [x] Correct Grok plugin layout (root `plugin.json`, not `.grok-plugin/`).
- [x] Note tool ID naming must match live Grok harness (confirm in Phase 0/2).
- [x] Version-agnostic streaming disabled copy requirement.
- [x] Rewrite process asserts to baseline-PID pattern.
- [x] Rewrite T-0.2 controlled scene; instrument T-G.10; expand T-C.4 only if Codex paths change.
- [x] Wire mood validation collateral into Milestone 2 / Ship B; two-tier ship gate.
- [x] Tighten success criteria (Ship A/B; no open-ended privacy/vision skips).
- [x] Cross-link install/uninstall Grok traceability as Phase 5 deliverable.

---

## 12. Residual uncertainty (after full team)

1. Whether interactive Grok multimodal `read_file` on arbitrary absolute JPEGs is reliable (Phase 0) — **still the product-blocking unknown**.
2. Whether Launch Services `open` of a signed app outside the sandbox write set works while the agent shell cannot `mkdir` the frame dir — needs empirical 0b.
3. Whether Grok injects `GROK_PLUGIN_ROOT` into skill-invoked shell (unlikely for primary design).
4. Exact interactive vs headless tool identifiers for shell.
5. Product decision on silent mood disclosure for Grok early adopters (ethics/UX, not only engineering).

---

## 13. Document control

| Field | Value |
| --- | --- |
| Review type | Expert 4-slot analytic review |
| Repo writes by specialists | None |
| This file | Leader synthesis after join of 4 successful reports |
| Follow-up (original) | Plan revision, then Phase 0 |
| Follow-up (done) | Compatibility plan revised 2026-07-13; next: Phase 0 implementation |

### Post-remediation verdict

| Item | Status |
| --- | --- |
| Closed decisions (A, Codex freeze, snapshot-first, paths, sandbox, versioning) | Encoded in plan §2 |
| Requirements gaps (sandbox, identity, dual-host uninstall, error UX, R-R6) | Encoded in plan §5 |
| Implementation sequencing | Plan §8 (0 → 0b → 1 → 2 snapshot → 3 → 4 freeze → 5) |
| Test plan falsifiability | Plan §9 (baseline-PID, controlled Phase 0, Ship A/B checklists) |
| Ready for Phase 0 code/runtime work | **Yes** |

---

*End of review.*
