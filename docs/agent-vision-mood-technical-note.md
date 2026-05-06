# Agent Vision Mood: Interaction-State Estimation for Assistant Response Calibration

Date: 2026-05-06

Status: concept note

## Abstract

Agent Vision Mood is a proposed slash-command and MCP-tool extension for Codex. When the user invokes `/agent-vision mood`, Codex calls a new `agent_vision_mood` tool, which obtains a consented camera snapshot through the existing Agent Vision snapshot path. If the image contains a usable view of the user, the tool estimates the user's current interaction state from visible expression, posture, attention, and weak environmental context. Codex then uses that estimate to calibrate the next response's shape: pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior. The feature improves delivery fit. It does not change factual standards, permissions, or the authority of the user's explicit request.

## Motivation

The same correct answer can have different practical value depending on the user's current state. A user who is focused and evaluating a design needs evidence and precision. A user who is frustrated by a blocked workflow needs fewer detours and a concrete next action. A user who is tired may benefit from a short result, a small number of options, and a clear stopping point.

Agent Vision already gives Codex an explicit, local way to inspect one visible frame when the user asks for camera context. Mood extends that mechanism from object inspection to interaction calibration. The image is not treated as a source of hidden intent. It is treated as local evidence about how much explanation, uncertainty, and interaction friction the current moment can support.

The compact product claim is:

```text
effective_help = task_correctness * delivery_fit
```

Codex still has to solve the requested task correctly. Mood targets the second factor by estimating the response form that will make the correct work easier for the user to use.

## User Contract

The user-facing command is:

```text
/agent-vision mood
```

When the command is used by itself, Codex should call `agent_vision_mood` and report the interaction-state read in compact terms: whether the user was present, the inferred state, the confidence level, the visible basis, and the response adjustments Codex will apply next.

When the command is used immediately before or inside a work request, Codex should call `agent_vision_mood` before generating the substantive answer. The returned state becomes ephemeral context for the next answer or current task phase.

Expected user-visible cases:

- **Present and readable:** Codex reports a concise state estimate and applies the response policy.
- **Absent:** Codex reports that no user was visible and proceeds without mood conditioning.
- **Occluded or poor image:** Codex reports that the image did not support a reliable read and proceeds without mood conditioning.
- **Ambiguous read:** Codex reports uncertainty, uses only low-risk adjustments such as clearer structure or shorter pacing, and treats the state as weak evidence.
- **User correction:** If the user corrects the inferred state, the correction overrides the visual inference for the current response or task phase.

Mood is opt-in at the command level. A single mood read should not become persistent background state unless a later feature explicitly introduces a session mode.

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

`agent_vision_mood` should reuse the existing snapshot lifecycle. It starts the camera if needed, waits for one usable JPEG frame, and stops the camera only if the mood call started it. If streaming is already active, the mood call should not stop the streaming session.

The tool result should be structured enough for Codex to consume deterministically. A representative shape:

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

This result is not a user profile. It is a short-lived context object for response calibration.

## Inference Target

The internal target is interaction state, not emotion as a private psychological fact. The tool estimates what can be observed from one consented frame and converts that estimate into assistant-facing response guidance.

The primary variables are:

- **Presence:** whether a user is visible and plausibly available for interaction.
- **Attention:** whether the user appears engaged with the screen, away from the keyboard, distracted, or uncertain.
- **Expression and posture:** visible signs that may support labels such as focused, strained, frustrated, tired, curious, skeptical, or neutral.
- **Image quality:** whether lighting, occlusion, blur, or framing limits confidence.
- **Surroundings:** weak context only, such as poor lighting or visible work materials. Surroundings should not dominate the read.

The output labels should be practical rather than clinical. Useful labels include:

- `focused_neutral`
- `frustrated_or_blocked`
- `tired_or_overloaded`
- `curious_or_exploratory`
- `skeptical_or_evaluating`
- `high_stakes_or_cautious`
- `absent`
- `uncertain`

The exact label set can evolve, but every label should exist because it maps to a distinct response policy. A label that does not change assistant behavior is not useful for v1.

## Policy Mapping

The policy map is the core feature. Mood is valuable only when it changes how Codex helps.

| Interaction state | Codex response calibration |
| --- | --- |
| `focused_neutral` | Use normal task-focused behavior. Keep the response proportional to the request. |
| `frustrated_or_blocked` | Lead with the concrete fix or next action. Reduce preamble. Avoid speculative branches. Own prior friction plainly if relevant. |
| `tired_or_overloaded` | Compress the answer. Use short sections. Offer one recommended path. Avoid long option sets. |
| `curious_or_exploratory` | Allow more conceptual framing, alternatives, and hypothesis development. Keep evidence and speculation distinct. |
| `skeptical_or_evaluating` | Increase evidence density. Include exact commands, observed outputs, file references, and explicit assumptions. |
| `high_stakes_or_cautious` | Slow down around irreversible actions. Separate known facts, assumptions, risks, and proposed next steps. |
| `absent` | Do not infer mood. Proceed from the prompt or wait if the task requires the user's presence. |
| `uncertain` | Use conservative response improvements only: clearer structure, fewer assumptions, and explicit uncertainty. |

These adjustments influence response form, not truth. Codex should still answer the actual prompt, preserve the requested scope, and follow the same tool and permission rules.

The main control surfaces are:

- **Verbosity budget:** how much explanation to include before or after the result.
- **Clarification threshold:** whether to ask a question or make a narrow assumption and proceed.
- **Evidence density:** how much supporting detail, command output, and citation to include.
- **Pacing:** whether to move in small steps or provide a broader synthesis.
- **Directness:** whether to lead with action, recommendation, or conceptual framing.
- **Repair behavior:** whether to acknowledge friction and correct course before continuing.

For example, if the same code failure is paired with `frustrated_or_blocked`, Codex should inspect, fix, and report concrete verification with little ceremony. If it is paired with `skeptical_or_evaluating`, Codex should include more evidence about why the fix matches the failure. If it is paired with `curious_or_exploratory`, Codex can include the causal model and nearby alternatives after the main result.

## Evaluation

The primary evaluation target is not emotion classification accuracy in isolation. The target is whether mood-conditioned responses help the user complete work with less friction.

Useful measures include:

- **Clarification loop count:** fewer back-and-forth turns before action begins.
- **Task progress latency:** shorter time from request to useful next state.
- **Correction rate:** how often users correct the inferred interaction state.
- **Perceived fit:** user rating or qualitative feedback on whether the response matched the moment.
- **Rework rate:** how often the assistant has to rewrite the answer for tone, length, evidence, or directness.
- **Completion quality:** whether task correctness remains unchanged or improves while delivery fit improves.

A minimal offline evaluation can use paired transcripts. For each task, compare a normal Codex response with a mood-conditioned response generated from the same prompt and a labeled interaction state. Reviewers should judge whether the conditioned response preserved correctness while improving fit for that state.

An online evaluation can track explicit user corrections and follow-up friction after `/agent-vision mood`. The feature should be considered successful when users correct it rarely, use it repeatedly, and reach useful outcomes with fewer conversational repairs.

## Limits

One image is limited evidence. Mood reads should carry confidence, observable basis, and uncertainty. The user's words override the visual inference. The state should be short-lived by default. The feature should not diagnose the user, infer long-term personality, or store covert emotional history.

These limits keep the feature aligned with its actual purpose: a local, opt-in calibration signal that helps Codex choose the right response shape for the current moment.
