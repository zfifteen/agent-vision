# Mood and roast recipes (Grok)

Long recipes kept out of the main skill body. Follow the skill HARD GATE first.

## Mood JSON contract

After capture + `read_file`, form internally (do not display unless debug):

- `presence`: `present` | `absent` | `uncertain`
- `interaction_state`: `focused_neutral` | `frustrated_or_blocked` | `tired_or_overloaded` | `curious_or_exploratory` | `skeptical_or_evaluating` | `high_stakes_or_cautious` | `absent` | `uncertain`
- `confidence`: 0–1
- `observable_basis`: string array (visible cues only)
- `assistant_adjustments`: string array (delivery only)

### Gates

- Below 0.40, or absent/occluded/multi-person/unusable → `uncertain`/`absent`, no mood-conditioned behavior
- 0.40–0.69 → low-risk clarity only
- 0.70+ → state-specific delivery from playbooks in SKILL.md

Never infer medical, psychological, intoxication, crisis, protected-trait, identity, or safety-state categories. Mood must not change facts, permissions, approval behavior, user intent, or task scope.

## Roast

After capture + `read_file`: one playful roast ≤400 characters from visible non-sensitive details only (outfit, posture, expression, lighting, room chaos). No protected traits, body size, age, disability. Include Markdown image link + roast text. Must be grounded in **this turn’s** image.

## Ambiguity burst

If first capture is unusable (helper `ok: false`, black frame, or after `read_file` presence is clearly unreadable), run **one** second one-shot capture and `read_file` again. Still no always-on camera. If still unusable → report error / treat mood as uncertain; do not invent content.
