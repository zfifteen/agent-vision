# Agent Vision Mood: Interaction-State Estimation for Assistant Response Calibration

**Date:** 2026-05-06  
**Status:** v2 – Full revised version (confident affirmative tone)

### Purpose

Agent Vision Mood gives Codex the ability to briefly observe the user’s visible interaction state and calibrate how it delivers the next response.

When the user runs `/agent-vision mood`, Codex captures one consented camera frame through the existing Agent Vision snapshot path, estimates the current interaction state from visible cues (expression, posture, attention, and light environmental context), and applies that estimate to adjust response pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior.

The objective is clear: the same correct answer becomes significantly more useful when delivered in the form the user can best absorb at that moment.

### Motivation

The same correct answer can have very different practical value depending on the user’s current state.

A user who is focused and evaluating a design needs evidence and precision.
A user who is frustrated by a blocked workflow needs fewer detours and a concrete next action.
A user who is tired may benefit from a short result, a small number of options, and a clear stopping point.

Agent Vision already provides Codex with an explicit, local way to inspect one visible frame when the user asks for camera context. Mood extends that mechanism from object inspection to interaction calibration.

The compact product claim is:

```text
effective_help = task_correctness × delivery_fit
```

Codex still solves the requested task correctly. Mood targets the second factor by estimating the response form that will make the correct work easier for the user to use.

### Core Contract

The user-facing command is:

```text
/agent-vision mood
```

When used by itself, Codex calls `agent_vision_mood` and reports the interaction-state read in compact terms: whether the user was present, the inferred state, the confidence level, the visible basis, and the response adjustments it will apply next.

When used immediately before or inside a work request, Codex calls `agent_vision_mood` before generating the substantive answer. The returned state becomes ephemeral context for the next answer or current task phase.

Expected user-visible cases:

- **Present and readable:** Codex reports a concise state estimate and applies the response policy.
- **Absent:** Codex reports that no user was visible and proceeds without mood conditioning.
- **Occluded or poor image:** Codex reports that the image did not support a reliable read and proceeds without mood conditioning.
- **Ambiguous read:** Codex reports uncertainty, uses only low-risk adjustments such as clearer structure or shorter pacing, and treats the state as weak evidence.
- **User correction:** If the user corrects the inferred state, the correction overrides the visual inference for the current response or task phase.

Mood is opt-in at the command level. A single mood read does not become persistent background state unless a later feature explicitly introduces a session mode.

### System Model

The pipeline is:

```text
/agent-vision mood
  → Codex slash-command workflow
  → agent_vision_mood MCP tool
  → existing Agent Vision snapshot path
  → usable-frame and presence check
  → visual interaction-state analysis
  → structured mood result
  → Codex response calibration
```

`agent_vision_mood` reuses the existing snapshot lifecycle. It starts the camera if needed, waits for one usable JPEG frame, and stops the camera only if the mood call started it. If streaming is already active, the mood call leaves the streaming session running.

The tool result is structured for Codex to consume deterministically:

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
    "reduce preamble",
    "prefer direct action",
    "state assumptions plainly",
    "avoid optional detours"
  ]
}
```

This result is a short-lived context object for response calibration.

### Inference Target

The target is interaction state, not emotion as a private psychological fact. The tool estimates what can be observed from one consented frame and converts that estimate into assistant-facing response guidance.

The primary variables are:
- **Presence:** whether a user is visible and plausibly available for interaction.
- **Attention:** whether the user appears engaged with the screen, away from the keyboard, distracted, or uncertain.
- **Expression and posture:** visible signs that may support labels such as focused, strained, frustrated, tired, curious, skeptical, or neutral.
- **Image quality:** whether lighting, occlusion, blur, or framing limits confidence.
- **Surroundings:** weak context only, such as poor lighting or visible work materials. Surroundings do not dominate the read.

The output labels are practical rather than clinical. Useful labels include:
- `focused_neutral`
- `frustrated_or_blocked`
- `tired_or_overloaded`
- `curious_or_exploratory`
- `skeptical_or_evaluating`
- `high_stakes_or_cautious`
- `absent`
- `uncertain`

Every label exists because it maps to a distinct response policy. A label that does not change assistant behavior is not useful.

### Policy Mapping

The policy map is the core of the feature. Mood is valuable only when it changes how Codex helps.

| Interaction State       | Codex Response Calibration                                      |
|-------------------------|-----------------------------------------------------------------|
| `focused_neutral`       | Use normal task-focused behavior. Keep the response proportional to the request. |
| `frustrated_or_blocked` | Lead with the concrete fix or next action. Reduce preamble. Avoid speculative branches. Own prior friction plainly if relevant. |
| `tired_or_overloaded`   | Compress the answer. Use short sections. Offer one recommended path. Avoid long option sets. |
| `curious_or_exploratory`| Allow more conceptual framing, alternatives, and hypothesis development. Keep evidence and speculation distinct. |
| `skeptical_or_evaluating` | Increase evidence density. Include exact commands, observed outputs, file references, and explicit assumptions. |
| `high_stakes_or_cautious` | Slow down around irreversible actions. Separate known facts, assumptions, risks, and proposed next steps. |
| `absent`                | Do not infer mood. Proceed from the prompt or wait if the task requires the user’s presence. |
| `uncertain`             | Use conservative response improvements only: clearer structure, fewer assumptions, and explicit uncertainty. |

These adjustments influence response form, not truth. Codex answers the actual prompt, preserves the requested scope, and follows the same tool and permission rules.

The main control surfaces are:
- **Verbosity budget:** how much explanation to include before or after the result.
- **Clarification threshold:** whether to ask a question or make a narrow assumption and proceed.
- **Evidence density:** how much supporting detail, command output, and citation to include.
- **Pacing:** whether to move in small steps or provide a broader synthesis.
- **Directness:** whether to lead with action, recommendation, or conceptual framing.
- **Repair behavior:** whether to acknowledge friction and correct course before continuing.

### Evaluation

The primary evaluation target is not emotion classification accuracy in isolation. The target is whether mood-conditioned responses help the user complete work with less friction.

Useful measures include:
- **Clarification loop count:** fewer back-and-forth turns before action begins.
- **Task progress latency:** shorter time from request to useful next state.
- **Correction rate:** how often users correct the inferred interaction state.
- **Perceived fit:** user rating or qualitative feedback on whether the response matched the moment.
- **Rework rate:** how often the assistant has to rewrite the answer for tone, length, evidence, or directness.
- **Completion quality:** whether task correctness remains unchanged or improves while delivery fit improves.

A minimal offline evaluation can use paired transcripts. For each task, compare responses with and without mood conditioning on the measures above.

### Design Principles

- The feature observes only what is visible in one consented frame.
- It estimates observable interaction state, not private emotion.
- The result is a temporary signal for the current response only.
- All adjustments affect delivery form. Task correctness, scope, and permission rules remain unchanged.
- The user can correct any estimate; the correction takes precedence.
- Mood is valuable only when it meaningfully changes how Codex helps the user.