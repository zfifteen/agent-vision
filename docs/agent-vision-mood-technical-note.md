# Agent Vision Mood: Interaction-State Estimation for Assistant Response Calibration

Date: 2026-05-06

Status: concept note

## Abstract

Agent Vision Mood is a proposed slash-command and MCP-tool extension for Codex. The user invokes `/agent-vision mood`; Codex calls `agent_vision_mood`; the tool obtains a consented camera snapshot through the existing Agent Vision snapshot path. A usable view of the user gives Codex a local interaction-state signal from visible expression, posture, attention, and environmental cues. Codex uses that signal to tune the next response's pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior.

The feature improves delivery fit while preserving the user's request, factual standards, permissions, and tool rules.

## Motivation

The same correct answer can land differently across user states. A focused user evaluating a design benefits from evidence and precision. A frustrated user blocked by a workflow benefits from a concrete next action. A tired user benefits from a compact result, a single recommended path, and a clear stopping point.

Agent Vision already gives Codex an explicit, local way to inspect one visible frame when the user asks for camera context. Mood extends that mechanism from object inspection to interaction calibration. The image becomes local evidence for response shape: how much explanation, uncertainty, evidence, and interaction friction the current moment can support.

The compact product claim is:

```text
effective_help = task_correctness * delivery_fit
```

Mood targets the second factor. Codex solves the requested task and shapes the delivery so the user can use the result more easily.

## User Contract

The user-facing command is:

```text
/agent-vision mood
```

Standalone use returns a compact interaction-state read:

- user presence
- inferred interaction state
- confidence
- visible basis
- response adjustments for the next answer

Use immediately before or inside a work request gives Codex ephemeral context for the next answer or current task phase.

Expected user-visible cases:

- **Present and readable:** Codex reports a concise state estimate and applies the response policy.
- **Absent:** Codex reports user absence and continues from the prompt.
- **Occluded or poor image:** Codex reports low visual support and continues from the prompt.
- **Ambiguous read:** Codex reports uncertainty and uses clearer structure, steadier pacing, and explicit uncertainty.
- **User correction:** The user's correction becomes the interaction-state signal for the current response or task phase.

Mood is opt-in at the command level. A single mood read is a current-response signal. A future session mode can introduce longer-lived behavior.

## System Model

The proposed pipeline is:

```text
/agent-vision mood
  -> Codex slash-command workflow
  -> agent_vision_mood MCP tool
  -> existing Agent Vision snapshot path
  -> usable-frame and presence check
  -> visual interaction-state analysis
  -> structured mood result
  -> Codex response calibration
```

`agent_vision_mood` reuses the existing snapshot lifecycle. It starts the camera when needed, waits for one usable JPEG frame, and returns the camera to its prior mode. An active streaming session stays active across the mood read.

The tool result is structured for deterministic consumption:

```json
{
  "presence": "present",
  "interaction_state": "frustrated_or_blocked",
  "confidence": 0.72,
  "observable_basis": [
    "tense facial expression",
    "forward posture",
    "focused gaze toward the screen"
  ],
  "assistant_adjustments": [
    "lead with the fix",
    "prefer direct action",
    "state assumptions plainly",
    "keep side paths out of the first response"
  ]
}
```

The result is a current-response interaction signal for response calibration.

## Inference Target

The tool estimates visible interaction state: what the user appears ready to do with the next response. A single consented frame supplies observable cues, and the tool converts those cues into assistant-facing response guidance.

Primary variables:

- **Presence:** visible user availability for interaction.
- **Attention:** screen engagement, gaze direction, and apparent task focus.
- **Expression and posture:** visible cues supporting labels such as focused, strained, frustrated, tired, curious, skeptical, or neutral.
- **Image quality:** lighting, occlusion, blur, and framing as confidence inputs.
- **Surroundings:** contextual cues such as lighting and visible work materials as secondary support.

The output labels are practical response-shaping labels:

- `focused_neutral`
- `frustrated_or_blocked`
- `tired_or_overloaded`
- `curious_or_exploratory`
- `skeptical_or_evaluating`
- `high_stakes_or_cautious`
- `absent`
- `uncertain`

Each label maps to a distinct response policy.

## Policy Mapping

The policy map is the core feature. Mood matters when it changes how Codex helps.

| Interaction state | Codex response calibration |
| --- | --- |
| `focused_neutral` | Use normal task-focused behavior. Keep the response proportional to the request. |
| `frustrated_or_blocked` | Lead with the concrete fix or next action. Start with what changed, what to run, and what result to expect. Own prior friction plainly when relevant. |
| `tired_or_overloaded` | Give a compact answer. Use brief sections. Offer one recommended path. Keep the option set small. |
| `curious_or_exploratory` | Include conceptual framing, alternatives, and hypothesis development. Keep evidence and speculation distinct. |
| `skeptical_or_evaluating` | Increase evidence density. Include exact commands, observed outputs, file references, and explicit assumptions. |
| `high_stakes_or_cautious` | Slow down around irreversible actions. Separate known facts, assumptions, risks, and proposed next steps. |
| `absent` | Continue from the prompt. For tasks that require the user's visible presence, ask for presence before camera-dependent work. |
| `uncertain` | Use clearer structure, modest claims, and explicit uncertainty. |

These adjustments shape response form. Codex answers the actual prompt, preserves the requested scope, and follows the same tool and permission rules.

Main control surfaces:

- **Verbosity budget:** amount of explanation before or after the result.
- **Clarification threshold:** question versus narrow assumption and action.
- **Evidence density:** supporting detail, command output, and citation level.
- **Pacing:** small steps versus broader synthesis.
- **Directness:** action, recommendation, or conceptual framing first.
- **Repair behavior:** acknowledge friction and correct course before continuing.

For the same code failure, `frustrated_or_blocked` leads Codex to inspect, fix, and report concrete verification with little ceremony. `skeptical_or_evaluating` adds evidence connecting the fix to the failure. `curious_or_exploratory` adds the causal model and nearby alternatives after the main result.

## Evaluation

The primary evaluation target is delivery fit during real work. Mood-conditioned responses should help the user reach useful outcomes with reduced conversational repair.

Useful measures:

- **Clarification loop count:** turns before action begins.
- **Task progress latency:** time from request to useful next state.
- **Correction rate:** frequency of user corrections to the inferred interaction state.
- **Perceived fit:** user rating or qualitative feedback on response fit.
- **Rework rate:** answer rewrites for tone, length, evidence, or directness.
- **Completion quality:** task correctness and delivery fit together.

A minimal offline evaluation can use paired transcripts. For each task, compare a normal Codex response with a mood-conditioned response generated from the same prompt and a labeled interaction state. Reviewers judge correctness preservation and fit improvement for that state.

An online evaluation can track explicit user corrections and follow-up friction after `/agent-vision mood`. Success means repeated use, rare corrections, and useful outcomes with reduced conversational repair.

## Operating Bounds

One image is a current-moment signal. Mood reads include confidence, observable basis, and uncertainty. The user's words govern the response. The state applies to the current response by default. The feature estimates interaction state for delivery fit.

These bounds keep the feature aligned with its purpose: a local, opt-in calibration signal that helps Codex choose the right response shape for the current moment.
