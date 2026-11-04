---
name: eg-fix-bug
description: EG bug fix. Problem doc, independent goldfish diagnosis, failing test, fix, review, and deterministic gates.
argument-hint: "[pack] <bug description or issue URL>"
disable-model-invocation: true
---
# EG Fix Bug

Fix a bug with the elephant/goldfish workflow.

Read `.github/eg/protocol.md` first and follow it. This skill uses stages `diagnosis` and `review`.

## 1. Setup
Run protocol P0, P1, and P2. If the task is a GitHub issue URL or `#<number>`, fetch it and seed the problem doc from it.

## 2. Triviality gate
For typo fixes in copy or comments, dead-code removal, version bumps, formatter-only diffs, and single-line config tweaks: skip steps 4 and 5, make the fix, then still run steps 7 and 8.

## 3. Problem doc
Write `<work>/problem.md` and show it:

```markdown
# Problem: <title>
- Symptom: <what the user observes>
- Repro: <steps, failing test, URL, log, or "need to derive">
- Suspected area: <file, module, route, job, or screen>
- Hypothesized root cause: <one sentence>
- Blast radius: <surfaces that could be affected>
- Fixed means: <specific test, behavior, or output>
```

If there is no repro and the bug is not obvious from reading one file, stop and ask for a concrete repro. For UI bugs, reproduce using the profile's `Runtime verification` entry when possible.

## 4. Diagnosis (stage `diagnosis`, compare)
Run protocol P3 compare. Your own answer is the hypothesized root cause in the problem doc. Pass the goldfish only:

```text
SYMPTOM: <symptom>
REPRO: <repro>
```

Never pass the suspected area or your hypothesis. Update the problem doc with the comparison result.

## 5. Failing test
If the workspace is not a git repository, snapshot each existing file to `<work>/baseline/` before its first edit, including test files (protocol "Review input file").

Capture the bug as a failing test at the narrowest tier that shows it. Run it and confirm it fails for the reason in the problem doc; if it fails for another reason, fix the test first.

For UI bugs where an automated test is disproportionate, write a manual repro script (navigate, act, observe) and confirm the bug is visible.

## 6. Fix
Make the smallest change that turns the failing test green and matches "Fixed means". No adjacent refactors or unrequested fallbacks. Re-run the test; it must pass. For UI bugs, re-run the manual repro.

## 7. Review (stage `review`, gate)
Run the review loop from the `eg-precommit-review` skill (its steps 4.1-4.4) with the bug summary as the focus.

## 8. Deterministic gates
Run protocol P4.

## 9. Save and report
Protocol P5. Report also: root cause, fix location, regression test, and goldfish-vs-elephant agreement or divergence.
