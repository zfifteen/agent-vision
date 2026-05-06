# Agent Vision Mood: Interaction-State Estimation for Assistant Response Calibration

**Date:** 2026-05-06  
**Status:** v2 – Revised

### Purpose

Agent Vision Mood gives Codex the ability to briefly observe the user’s visible interaction state and calibrate how it delivers the next response.

When the user runs `/agent-vision mood`, Codex captures one consented camera frame, estimates the current interaction state from visible cues (expression, posture, attention), and applies that signal to adjust response pacing, verbosity, clarification threshold, evidence density, tone, and repair behavior.

The objective is straightforward: the same correct answer becomes significantly more useful when delivered in the form the user can best absorb at that moment.

### Core Contract

The `/agent-vision mood` command returns a short-lived interaction signal scoped to the current response or task phase.

The signal includes:
- User presence
- Interaction state
- Confidence level
- Observable basis for the estimate
- Recommended response adjustments

Codex reports the state to the user and applies the adjustments immediately. The signal expires after the current turn.

### How It Works

1. User invokes `/agent-vision mood` (standalone or combined with a work request).
2. Codex calls the `agent_vision_mood` MCP tool.
3. The tool reuses the existing Agent Vision snapshot pipeline.
4. It returns a structured result.
5. Codex surfaces the state estimate and applies the corresponding policy.

If streaming mode is active, the mood call leaves the stream running.

### Result Format

```json
{
  "presence": "present",
  "interaction_state": "frustrated_or_blocked",
  "confidence": 0.72,
  "observable_basis": ["tense facial expression", "forward posture", "focused gaze"],
  "assistant_adjustments": ["reduce preamble", "lead with concrete next action"]
}
```

### Interaction States and Response Policies

| Interaction State       | Response Policy                                      |
|-------------------------|------------------------------------------------------|
| focused_neutral         | Deliver at normal scope and detail                   |
| frustrated_or_blocked   | Lead with the fix or next concrete action            |
| tired_or_overloaded     | Use short sections and one recommended path          |
| curious_or_exploratory  | Include conceptual framing and relevant alternatives |
| skeptical_or_evaluating | Increase evidence density and explicit assumptions   |
| high_stakes_or_cautious | Separate facts, assumptions, risks, and next steps   |
| absent                  | Proceed from the prompt or request confirmation      |
| uncertain               | Apply clear structure and explicit uncertainty       |

### Design Principles

- The feature observes only what is visible in one consented frame.
- It estimates observable interaction state, not private emotion.
- The result is a temporary signal for the current response only.
- All adjustments affect delivery form. Task correctness, scope, and permissions remain unchanged.
- The user can correct any estimate; the correction takes precedence.

### Evaluation

We measure success by reduced interaction friction:
- Fewer clarification turns
- Faster progress from request to useful next state
- Lower user correction rate of the state estimate
- Higher perceived fit between response style and user moment
- Maintained or improved task completion quality