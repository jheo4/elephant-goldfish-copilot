---
name: eg-new-feature
description: EG new feature. Design doc, goldfish design gate, implementation, review, and deterministic gates.
argument-hint: "[pack] <feature description or issue URL>"
disable-model-invocation: true
---
# EG New Feature

Build a feature with the elephant/goldfish workflow.

Read `.github/eg/protocol.md` first and follow it. This skill uses stages `design` and `review`.

## 1. Setup
Run protocol P0, P1, and P2. If the task is a GitHub issue URL or `#<number>`, fetch it (for example `gh issue view <number> --json title,body,labels,comments`) and seed the design doc from it.

## 2. Scope
Restate the request in one or two sentences. Ask the user to confirm if it is ambiguous or high-impact; otherwise continue.

Check the surface area: UI, API, database or schema, background jobs, external integrations, generated code, platform-specific work, or backend-only logic. Stop for confirmation when the request looks destructive, auth-sensitive, cross-tenant, or out of line with documented priorities.

## 3. Design doc
Write the design doc to `<work>/design.md` and show it to the user:

```markdown
# Design: <title>
- Why: <user problem this solves>
- Scope: <in scope, and explicitly out>
- Surfaces touched: <files, routes, models, components, jobs, external services>
- Interfaces: <props, signatures, API shapes, DB columns, event payloads>
- UX flow: <click by click for UI, or request by request for backend>
- Project-specific constraints: <auth, lifecycle, generated code, platform, performance, or other constraints found in the repo>
- Failure modes: <what breaks and what the user or API sees>
- Verification criteria: <unit, integration, E2E tests, and manual steps>
- Out-of-scope follow-ups: <noted, not built>
```

For UI work, sketch the structure in plain text. If a visual reference is needed, ask for the existing screen to mirror.

**No-code gate**: from here until the `design` stage passes, do not create, edit, or scaffold code. The design doc and read-only exploration are allowed. If the user asks to skip, name the open goldfish and require the explicit phrase `override the no-code gate`.

## 4. Design check (stage `design`, gate)
Run protocol P3 gate. Pass the full design doc text as the input. Revise `<work>/design.md` between rounds. Comprehension is `info`: if it said REVISE but the stage passed, continue and flag it in the final report.

## 5. Implementation
Pre-flight: confirm the `design` stage passed. If not, return to step 4. If the workspace is not a git repository, snapshot each existing file to `<work>/baseline/` before its first edit (protocol "Review input file").

Write a short ordered plan. Derive layer order from the stack, typically: data and schema, domain logic, service and API boundaries, UI, routing, generated code, then tests. Implement layer by layer and run the narrowest useful verification after each layer.

For UI changes, drive the feature using the profile's `Runtime verification` entry before calling it done. For backend changes, use focused tests, API calls, or logs.

## 6. Review (stage `review`, gate)
Run the review loop from the `eg-precommit-review` skill (its steps 4.1-4.4) with the feature name as the focus.

## 7. Deterministic gates
Run protocol P4. For UI features, walk through the golden path and one plausible edge case.

## 8. Save and report
Protocol P5. Save the final design doc. Report also: files touched by layer, tests added, design-check gap resolutions, manual walkthrough summary, and out-of-scope follow-ups.
