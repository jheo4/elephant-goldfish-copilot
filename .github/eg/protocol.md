# EG Core Protocol

This file is owned by the EG template. Every `/eg-*` skill (except `eg-setup`) follows it. Do not edit it in a project; customize through packs and the profile instead.

## Roles

- **Elephant**: you, the agent running the skill. You hold the full conversation, write documents and code, run commands, and are the only one who talks to the user.
- **Goldfish**: a fresh subagent with no chat history. It sees only the input you pass. It is read-only and cannot ask questions.

## P0. Parse the argument

The skill argument is the raw text the user typed after the skill name.

1. List the files in `.github/eg/packs/`. Each `<name>.md` is a pack named `<name>`.
2. If the first word of the argument exactly matches a pack name, that is the selected pack and the rest of the argument is the task.
3. Otherwise the whole argument is the task and the selected pack is the profile's `default-pack`, or `general` if the profile has none.
4. If the task is empty and the skill needs one, ask the user for it.

## P1. Read context

1. Read `.github/copilot-instructions.md` and `.github/eg/profile.md`.
2. Read the project docs listed under `## Project docs` in the profile that are relevant to the task.
3. If the profile says `status: not configured`, ask the user whether to run `/eg-setup` first or continue without deterministic gates. Do not guess gate commands.
4. Create this task's work directory `<work>` = `.eg-work/<yyyy-mm-dd>-<skill>-<slug>/` (`<skill>` without the `eg-` prefix, `<slug>` a short kebab-case summary of the task). Every working file of this task lives there. Never overwrite or delete another task's work directory.

## P2. Resolve the pack

A pack manifest has a header (`description`, optional `extends`, `max-rounds`) and a table with columns `stage | lens | goldfish | use`.

1. Read the selected pack. If it has `extends: <parent>`, read the parent, and so on. Stop after 3 levels. If a parent is missing or the chain loops, stop and tell the user.
2. Merge from the root ancestor down to the selected pack:
   - A row with the same `(stage, lens)` as an inherited row replaces it.
   - A row with a new `(stage, lens)` is added.
   - A row with `use: off` removes that `(stage, lens)`: it does not appear in the merged table, in the lineup line, or in saved documents, and its goldfish is never called. Mention it only in the report, as `turned off by <pack>`.
   - Rows the child does not mention are inherited.
   - `max-rounds` entries are inherited per stage and overridden per stage.
3. Check that every goldfish named in the merged table exists as `.github/agents/<goldfish>.agent.md`. If not, stop and tell the user which one is missing.
4. At the start of each stage, print:

   ```text
   [EG] pack=<pack> (extends <parent>, ...) stage=<stage>
   goldfish: <goldfish>/<lens>(<use>), ...
   deterministic: <gate names from the profile> | not configured
   ```

5. If a stage has no goldfish after merging:
   - If that is because rows were turned `off`, print `[EG] stage=<stage>: no goldfish (turned off by pack)` and continue with deterministic gates only.
   - If the stage was never defined in a pack with no `extends`, stop and ask the user how to proceed.
6. Put the merged table for the stages you ran at the top of every document you save.

## P3. Stage types

Stage names and types are fixed. Packs cannot change them.

| stage | type | input you pass |
|---|---|---|
| `brainstorm` | generate | `LENS`, `RESEARCH`, `SEED` |
| `prd-grounding` | generate | `LENS`, `SEED` |
| `prd-research` | generate | `LENS`, `RESEARCH`, `SEED`, `CODEBASE BRIEF`, `ANSWERED GAPS` |
| `prd` | gate | the PRD draft |
| `design` | gate | the design doc |
| `review` | gate | the diff file path, optional `FOCUS`, and from round 2 `PREVIOUS FIXES` |
| `diagnosis` | compare | `SYMPTOM` and `REPRO` only |

### Calling a goldfish

- Call it by its agent name as a subagent.
- Pass only the input listed above. Never pass chat history, your intent, your hypothesis, other goldfish output, or review criteria. The criteria live in the goldfish file.
- Format the input as labeled blocks, for example:

  ```text
  LENS: contrarian
  RESEARCH: none
  SEED:
  <seed text>
  ```

- Independent goldfish in the same round may run in parallel if the harness allows it; otherwise run them one at a time.
- Before calling a goldfish that has the `web` tool, tell the user that a web-access approval prompt may appear.

### Reading the result

- The last non-empty line must be exactly one of `EG-VERDICT: PASS`, `EG-VERDICT: REVISE`, or `EG-DONE`.
- If it is missing, call the same goldfish once more with the same input. If it is still missing, show the raw output to the user and ask how to proceed.
- Show each goldfish's output to the user before acting on it.

### gate

1. Round 1 runs `required` and `info` rows. Later rounds run only `required` rows.
2. The stage passes when every `required` goldfish ends with `EG-VERDICT: PASS`. `info` results are shown and logged but never block.
3. If not passed, collect every numbered finding from every goldfish under one heading per goldfish. For each finding, either fix the document or code, or rebut it in one line citing the profile, a project doc, the PRD, or the user's words. Do not skip findings because numbering restarts per goldfish.
4. Before the next round, print the open findings list:

   ```text
   Open findings going into round N:
   - [<lens> r<k> #<i>] fixed: <what changed>
   - [<lens> r<k> #<i>] rebutted: <verbatim reason>
   ```

5. Run the next round with the revised input. For `review`, add `PREVIOUS FIXES` listing what changed.
6. Hard cap: never start round `max-rounds + 1`. If round `max-rounds` finishes without a pass, stop immediately, do not revise or re-run, summarize open findings, and ask the user to accept, keep working, or abandon. Only an explicit user "keep working" reply allows more rounds. Passing on a later round than expected is not an excuse to exceed the cap.

### compare

1. Write down your own answer before calling the goldfish.
2. Call the goldfish with the stage input only.
3. Compare. If the goldfish has stronger evidence, update your answer. If yours is still better, write down why. Record agreement or divergence.

### generate

1. Run the selected rows. `pool` rows are run only when chosen with the user; `required` rows always run.
2. Synthesize the outputs as the skill describes. Keep the lens name next to each idea or finding.

## P4. Deterministic gates

1. Run each command under `## Deterministic gates` in the profile one at a time, skipping entries that say `not configured`.
2. New failures caused by the current change block progress. Pre-existing failures are out of scope; if unsure, compare against `base-branch`. List pre-existing failures in the final report.

### Review input file

The `review` stage always receives one file: `<work>/review-round<N>.diff`, where `<N>` is the review round (also in `eg-fix-bug`).

- **Git repository:** build it from git as described in the `eg-precommit-review` skill.
- **No git repository:** the goldfish must still see what changed, not whole files.
  1. Before the first edit to any existing file in this task, copy it to `<work>/baseline/<relative-path>` (skip if a baseline already exists). Files created in this task have no baseline.
  2. Start the diff file with the line `### no git repository; changes versus <work>/baseline`.
  3. For each baseline file, append `diff -u <work>/baseline/<path> <path>` output under a `### <path>` header. For each file created in this task, append `### new file: <path>` and its full contents. Skip files with no changes.
  4. If a file was edited without a baseline (for example the task started before this rule applied), append its full contents under `### unbaselined file: <path>` and say so in the final report.

## P5. Save and report

1. Save documents under the profile's `doc-path`, named `<yyyy-mm-dd>-<skill>-<slug>.md`, after asking the user. Put the merged pack table at the top.
2. Working files go in `<work>`. When the task ends, delete only the throwaway inputs `<work>/review-round*.diff` and `<work>/baseline/`. Keep `design.md`, `problem.md`, and `prd.md` in `<work>` even if the user declines to save them under `doc-path`, and tell the user where they are.
3. The final report always includes: pack used, stages run, rounds per gate stage, final verdicts, every rebuttal verbatim, deterministic gate results, and for the review stage how its input was built (git or baseline, and any unbaselined files).
4. Never stage or commit. Follow the project's commit policy if the user later asks to commit.
