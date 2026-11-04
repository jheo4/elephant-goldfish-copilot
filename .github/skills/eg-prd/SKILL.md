---
name: eg-prd
description: EG PRD. Codebase grounding goldfish, gap filling, research goldfish, PRD draft, and a goldfish readiness gate.
argument-hint: "[pack] <product idea or issue URL>"
disable-model-invocation: true
---
# EG PRD

Build a Product Requirements Document from a rough idea.

Read `.github/eg/protocol.md` first and follow it. This skill uses stages `prd-grounding`, `prd-research`, and `prd`. No code changes in this skill.

## 1. Setup
Run protocol P0, P1, and P2. The task is the seed. If it is a GitHub issue URL or `#<number>`, fetch it and use its title and body.

## 2. Frame
Ask the user:
1. Depth: lightweight, standard, or comprehensive.
2. Research: none, or web.
3. Output: save the PRD, chat only, and/or hand off to `/eg-new-feature`.

## 3. Codebase grounding (stage `prd-grounding`, generate)
Run protocol P3 generate with every row of the stage. Input:

```text
LENS: <lens>
SEED:
<seed>
```

Synthesize:

```text
CODEBASE BRIEF
- Closest existing surfaces:
- Patterns to mirror:
- Constraints from project docs:
- Observed gaps:
```

## 4. Gap list
List gaps grouped by: who and why; what and scope; how well; when; constraints; failure modes; pricing and go-to-market if relevant; instrumentation. Number them globally (G1, G2, ...). Ask which to fill now. Unselected gaps go to Open Questions.

For each selected gap, ask one question with 3-5 plausible answers plus "defer" and "other".

## 5. Research (stage `prd-research`, generate)
Skip if research is none and the pack has no `required` rows here. Otherwise propose 3-5 lenses from the stage and let the user adjust. Input:

```text
LENS: <lens>
RESEARCH: <web | none>
SEED:
<seed>
CODEBASE BRIEF:
<brief>
ANSWERED GAPS:
<gap id: answer>
```

Summarize by lens and consolidate sources.

## 6. Draft
Write `<work>/prd.md`:

```markdown
# PRD: <title>
## Executive Summary
## Problem Statement
## Target Users
## Current State
## Proposed Solution
## Scope
## User Stories / Jobs To Be Done
## Functional Requirements
## Non-Functional Requirements
## Success Metrics
## Risks & Mitigations
## Implementation Hints
## Open Questions
## Sources & References
## Out-of-Scope Follow-Ups
```

Skip sections only when genuinely not applicable. Deferred gaps go under Open Questions.

## 7. PRD check (stage `prd`, gate)
Run protocol P3 gate. Pass the full PRD text. Revise `<work>/prd.md` between rounds. Answer findings that need a product decision by asking the user, not by guessing.

## 8. Approve and output
Ask whether the PRD is approved, needs section revisions, should restart, or should stop. If approved, apply the chosen outputs. For handoff, print the exact prompt: `/eg-new-feature <pack> <summary>, see <saved PRD path>`.

## 9. Report
Protocol P5. Report also: depth and research, codebase brief summary, gaps surfaced, filled, and deferred, research lenses run, and next action.
