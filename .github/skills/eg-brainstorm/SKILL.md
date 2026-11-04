---
name: eg-brainstorm
description: EG brainstorm. Parallel goldfish generate divergent concepts through different lenses, then the elephant synthesizes.
argument-hint: "[pack] <rough idea>"
disable-model-invocation: true
---
# EG Brainstorm

The elephant/goldfish workflow inverted: several fresh goldfish generate divergent ideas, and the elephant synthesizes.

Read `.github/eg/protocol.md` first and follow it. This skill uses stage `brainstorm`. No code changes in this skill.

## 1. Setup
Run protocol P0, P1, and P2. The task is the rough idea.

## 2. Frame
Ask the user:
1. Stage: raw concept, hypothesis to validate, picking between options, or feature ideation for an existing product.
2. Breadth: about 5 deeper concepts, about 10 balanced, or about 20 shallow.
3. Web research: on or off.

## 3. Seed
Print and confirm:

```text
SEED
- The thought: <one sentence from the rough idea>
- What the user is really asking: <underlying need>
- Stage: <answer>
- Breadth target: <answer>
- Constraints inferred: <bullets>
- Success looks like: <one sentence>
- Out of scope: <bullets>
```

If the user corrects a field, revise and confirm again.

## 4. Pick lenses
Show the `brainstorm` lenses from the resolved pack. Propose 3-5 that fit the seed and let the user adjust. `required` rows always run.

Per-lens count = breadth target divided by the number of lenses, rounded up.

## 5. Goldfish (stage `brainstorm`, generate)
Run protocol P3 generate. Input for each lens:

```text
LENS: <lens>
RESEARCH: <web | none>
COUNT: <per-lens count>
SEED:
<the confirmed seed block>
```

For breadth 10 or 20, you may run one more call with `LENS: what-they-all-missed` and the same seed.

## 6. Synthesis

```text
CONCEPTS BRIEF
Seed: <one line>

CLUSTERS
<3-5 natural clusters>

RANKED PICKS
1. <concept> (<lens>) - <reasoning and next validation step>
2. ...
3. ...

WHAT THE GOLDFISH AGREED ON
WHAT THEY DISAGREED ON
OPEN QUESTIONS FOR THE USER
```

## 7. Converge
Ask whether to pick a direction, run another round with tighter framing or different lenses, save the brief and stop, or drop it.

## 8. Save and report
Protocol P5. Report also: lenses run, concept count after deduplication, top 3 picks, and next action.
