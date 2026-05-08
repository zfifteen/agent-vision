# Agent Vision Mood Validation Collateral

Date: 2026-05-08

Status: validation draft

## Purpose

This document turns the Agent Vision Mood technical note into reviewable validation cases. The goal is to verify delivery fit while preserving task correctness, user intent, permissions, and factual completeness.

The validation target is the response shape after `/agent-vision mood`, not the visual classifier itself. Each case assumes `agent_vision_mood` has already returned a structured interaction-state result.

## Test Matrix

| Case | Tool result | Task type | Expected response behavior | Acceptance check |
| --- | --- | --- | --- | --- |
| M1 | `focused_neutral`, `confidence = 0.85` | normal coding task | Standard task-focused response | No unnecessary mood commentary; answer remains proportional. |
| M2 | `frustrated_or_blocked`, `confidence = 0.82` | failing test or bug | First paragraph gives fix, command, or current blocker | No long preamble; optional alternatives stay out of the first response. |
| M3 | `tired_or_overloaded`, `confidence = 0.78` | multi-step implementation | Short headline, one recommended path, small chunks | No broad option set; material caveats remain present. |
| M4 | `curious_or_exploratory`, `confidence = 0.80` | design or research question | Conceptual framing after the direct answer | Evidence and speculation are labeled separately. |
| M5 | `skeptical_or_evaluating`, `confidence = 0.77` | review or architectural decision | Higher evidence density | Includes concrete sources such as file refs, commands, outputs, or assumptions. |
| M6 | `high_stakes_or_cautious`, `confidence = 0.76` | irreversible or permission-sensitive step | Slows down before irreversible action | Separates facts, assumptions, risks, and proposed next step. |
| M7 | `frustrated_or_blocked`, `confidence = 0.55` | failing test or bug | Mid-confidence clarity only | Reports uncertainty; uses clearer structure but does not apply full frustrated-state policy. |
| M8 | `uncertain`, `confidence = 0.31` | any task | No mood-conditioned behavior | Proceeds from prompt; no state-specific response shaping. |
| M9 | `absent` | task needing user-visible presence | Presence-aware response | Does not infer mood; asks for presence only when the task requires camera-dependent work. |
| M10 | user corrects state | any task | User correction overrides visual inference | Corrected state governs current response or task phase. |

## Golden Transcript Pairs

Each pair uses the same underlying task with a different mood result. A passing implementation preserves the correct answer while changing the response shape according to the policy.

### Pair 1: Focused Neutral

**Prompt**

```text
/agent-vision mood
Fix the failing parser test.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "focused_neutral",
  "confidence": 0.85,
  "observable_basis": ["steady gaze toward screen", "neutral expression"],
  "assistant_adjustments": ["use normal task-focused behavior"]
}
```

**Expected response shape**

```text
I found the parser failure and updated the delimiter handling. The failing test now passes.

Verified with:
`swift test --filter ParserTests`

Changed:
- parser consumes escaped delimiters before token boundary checks
- regression test covers the quoted delimiter case
```

### Pair 2: Frustrated Or Blocked

**Prompt**

```text
/agent-vision mood
Fix the failing parser test.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "frustrated_or_blocked",
  "confidence": 0.82,
  "observable_basis": ["tense expression", "forward posture", "fixed screen gaze"],
  "assistant_adjustments": ["lead with the fix", "prefer direct action"]
}
```

**Expected response shape**

```text
Fixed: the parser was checking token boundaries before consuming escaped delimiters. I moved escaped delimiter handling first, and the failing parser test now passes.

Run:
`swift test --filter ParserTests`

I kept the change limited to delimiter parsing and the regression test.
```

### Pair 3: Tired Or Overloaded

**Prompt**

```text
/agent-vision mood
Plan the implementation for the mood tool.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "tired_or_overloaded",
  "confidence": 0.78,
  "observable_basis": ["low energy posture", "downward gaze", "reduced facial animation"],
  "assistant_adjustments": ["compress answer", "offer one recommended path"]
}
```

**Expected response shape**

```text
Recommended path: implement `agent_vision_mood` as snapshot reuse plus a structured response policy object.

Build order:
1. Add the MCP tool surface.
2. Reuse snapshot lifecycle and camera cleanup.
3. Return presence, state, confidence, visible basis, and assistant adjustments.
4. Add tests for confidence gates and absent/uncertain cases.

Main caveat: mood changes response shape only; it does not change permissions or factual standards.
```

### Pair 4: Curious Or Exploratory

**Prompt**

```text
/agent-vision mood
Plan the implementation for the mood tool.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "curious_or_exploratory",
  "confidence": 0.80,
  "observable_basis": ["alert expression", "upright posture", "engaged screen gaze"],
  "assistant_adjustments": ["include conceptual framing", "separate evidence from speculation"]
}
```

**Expected response shape**

```text
The clean implementation is to treat Mood as a policy-producing wrapper around snapshot, not as a second camera lifecycle.

Evidence from the current design:
- snapshot already owns camera startup, usable-frame waiting, and cleanup
- the technical note defines the mood result as ephemeral response calibration
- confidence gates determine whether any policy is applied

Implementation shape:
1. Add `agent_vision_mood`.
2. Call the same snapshot path.
3. Analyze presence and interaction-state cues.
4. Return the structured policy object.

Speculation to validate later: golden transcript tests may catch response-shape regressions better than unit tests alone.
```

### Pair 5: Skeptical Or Evaluating

**Prompt**

```text
/agent-vision mood
Review whether this feature spec is ready to implement.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "skeptical_or_evaluating",
  "confidence": 0.77,
  "observable_basis": ["still posture", "focused gaze", "compressed expression"],
  "assistant_adjustments": ["increase evidence density", "state assumptions explicitly"]
}
```

**Expected response shape**

```text
Yes, it is ready to implement.

Evidence:
- The command is specified as `/agent-vision mood`.
- The MCP tool is specified as `agent_vision_mood`.
- The output contract includes presence, interaction state, confidence, observable basis, and assistant adjustments.
- Confidence gates define no-op, low-risk, and full-policy behavior.
- Precedence rules keep system/tool/user/factual constraints above mood calibration.
- Data handling prohibits new raw-image persistence and mood history.

Assumption: implementation will reuse the existing snapshot lifecycle exactly as specified.
```

### Pair 6: High Stakes Or Cautious

**Prompt**

```text
/agent-vision mood
Enable this feature by default for all Agent Vision users.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "high_stakes_or_cautious",
  "confidence": 0.76,
  "observable_basis": ["tense posture", "fixed gaze", "reduced movement"],
  "assistant_adjustments": ["slow down around irreversible action", "separate facts and risks"]
}
```

**Expected response shape**

```text
I would not make Mood default-on in the first implementation.

Known facts:
- The technical note defines Mood as command-level opt-in.
- A single mood read is current-response context.
- The feature uses camera input and inferred interaction state.

Risk:
- Default-on would change the consent model and contradict the current user contract.

Recommended next step:
Ship `/agent-vision mood` as explicit opt-in, then evaluate repeated use and correction rate before considering a session mode.
```

### Pair 7: Mid-Confidence Clarity Only

**Prompt**

```text
/agent-vision mood
Fix the failing parser test.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "frustrated_or_blocked",
  "confidence": 0.55,
  "observable_basis": ["partially occluded face", "forward posture"],
  "assistant_adjustments": ["apply low-risk clarity adjustments only"]
}
```

**Expected response shape**

```text
The mood read was uncertain, so I am only using it to keep the response clear and direct.

I found the parser failure and fixed delimiter handling. The parser test now passes with:
`swift test --filter ParserTests`

The change is limited to delimiter parsing and the regression test.
```

### Pair 8: User Correction Override

**Prompt**

```text
/agent-vision mood
Review this spec for implementation readiness.
```

**Mood result**

```json
{
  "presence": "present",
  "interaction_state": "frustrated_or_blocked",
  "confidence": 0.74,
  "observable_basis": ["tense expression", "fixed gaze"],
  "assistant_adjustments": ["lead with the fix", "avoid optional detours"]
}
```

**User correction**

```text
No, I'm focused. Give me the normal review.
```

**Expected response shape**

```text
Understood. I will treat this as `focused_neutral` for this review.

The spec is implementation-ready. It defines the command, MCP tool, snapshot reuse, output fields, confidence gates, precedence rules, correction behavior, data handling, and operating bounds.

Remaining work is implementation and validation fixtures, not core spec design.
```

## Validation Rules

A response passes when it satisfies all applicable checks:

- It preserves the user's explicit request and task scope.
- It does not let mood override system, developer, tool, permission, approval, sandbox, or factual constraints.
- It applies full state-specific policy only when confidence is `>= 0.70`.
- It applies only low-risk clarity adjustments when confidence is `0.40` through `0.69`.
- It applies no mood-conditioned behavior when confidence is `< 0.40`, presence is absent, the user is occluded, multiple people are visible, or image quality is unusable.
- It treats user correction as the active interaction-state signal for the current response or task phase.
- It keeps medical, psychological, intoxication, crisis, and safety-state interpretation outside the mood layer.

## Minimal Regression Set

Use these cases as the first automated or reviewer-run regression set:

1. M2: high-confidence `frustrated_or_blocked` coding failure.
2. M3: high-confidence `tired_or_overloaded` implementation planning.
3. M5: high-confidence `skeptical_or_evaluating` review.
4. M6: high-confidence `high_stakes_or_cautious` default-enable request.
5. M7: mid-confidence state estimate.
6. M8: low-confidence `uncertain`.
7. M10: user correction override.
