# Agent Vision — Grok Build host adapter

## Purpose

**Mood-first sticky vision-in-the-loop.** Arm once; while armed, every non-whitelist turn **captures → understands the image → uses image content in reasoning** until `/agent-vision off`.

| Mode | Role |
| --- | --- |
| `/agent-vision` or `mood` | **Primary** — arm + disposition → reason → respond (silent) |
| `snapshot` / `roast` | Supporting — arm + mode |
| `status` | Sticky + last capture age (no camera if pure status) |
| `off` | Disarm |
| Streaming | Disabled; do not arm |

### HARD GATE

While ARMED, capture without use is **INVALID**. Topic is irrelevant. Answers identical to a blind answer are invalid. Mechanical gate: `agent-vision-turn-gate begin` → capture → `record --path` → single-use `ready`.

New chat always starts **OFF**. Vision path: multimodal `read_file`. Process: one-shot capture per look (no always-on daemon). Skill frontmatter: `disable-model-invocation: false` so sticky can run with gates.

Full contract: [docs/agent-vision-grok-session-sticky.md](../../docs/agent-vision-grok-session-sticky.md).

## Install

```bash
scripts/install-runtime.sh
scripts/install-grok.sh
```

- `~/.local/bin` on `PATH` (capture + sticky / turn-gate / purge shims)
- Grok **sandbox off**
- New Grok session after install
- Primary: `/agent-vision` or `/agent-vision mood`

## Layout

```text
hosts/grok/
  plugin.json
  skills/agent-vision/SKILL.md
  skills/agent-vision/references/mood-roast-recipes.md
  README.md
```

Shared helpers (repo `scripts/`, staged to PATH by install-grok):

- `agent-vision-sticky.sh`
- `agent-vision-turn-gate.sh`
- `agent-vision-purge-frames.sh`

## Tests

```bash
scripts/test-grok-adapter.sh
scripts/test-grok-sticky-state.sh
scripts/test-agent-vision-turn-gate.sh
scripts/test-agent-vision-purge-frames.sh
```
