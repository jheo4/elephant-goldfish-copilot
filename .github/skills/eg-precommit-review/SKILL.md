---
name: eg-precommit-review
description: EG pre-commit review loop. Runs deterministic gates and an independent goldfish review of pending changes.
argument-hint: "[pack] [extra focus for the reviewer]"
disable-model-invocation: true
---
# EG Precommit Review

Validate pending changes before commit with a fresh reviewer that sees the diff cold.

Read `.github/eg/protocol.md` first and follow it. This skill uses stage `review`. The task text from P0, if any, is an extra focus area for the reviewer.

## 1. Setup
Run protocol P0, P1, and P2.

## 2. Preflight
Skip the review loop, and say so, for: documentation-only changes, typo-only edits, version bumps, dependency updates with no code changes, formatter-only diffs, and merge commits. Run it for everything else.

If the project uses generated code and the diff touches generation inputs, regenerate first. Source and generated files must be committed together.

## 3. Deterministic gates
Run protocol P4.

## 4. Review loop (stage `review`, gate)
For each round N:

1. Write the pending changes to `<work>/review-round<N>.diff`. If the workspace is not a git repository, follow "Review input file" in the protocol instead of the git commands below. Otherwise run these commands one at a time and append each command and its output under a header line `### <command>`:
   - `git status`
   - `git diff`
   - `git diff --cached`
   - `git diff <base-branch>...HEAD`
   - `git log <base-branch>..HEAD --oneline`
   - `git ls-files --others --exclude-standard`
   Use the profile's `base-branch`. Then append the full contents of each untracked file that is not ignored.
2. Call the review goldfish with:

   ```text
   DIFF: <work>/review-round<N>.diff
   FOCUS: <task text, or none>
   PREVIOUS FIXES:
   - <file:line - what changed>   (round 2 and later only)
   ```

3. Triage and loop as protocol P3 gate describes. Fix findings in code, or rebut each in one line: `not a bug because ...`, `out of scope because ...`, `intentional trade-off documented in ...`, or `user explicitly asked for this: "..."`.
4. After fixes, re-run the deterministic gates before the next round.

## 5. Final report
Protocol P5, plus: findings fixed, findings rebutted verbatim, and pre-existing failures treated as out of scope. Do not save a document unless the user asks.
