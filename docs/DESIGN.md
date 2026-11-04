# EG for GitHub Copilot: Design Document (Phase 3)

This document describes a template that enables the elephant/goldfish (EG) workflow in VS Code GitHub Copilot. The source is `elephant-goldfish-main/` (for Claude Code, Codex, and Gemini CLI); the harness behavior is based on the probe results in `eg-probe/README.md`.

## 1. Goals and Scope

- Build a domain-agnostic EG platform. Extend review perspectives through replaceable **packs**, such as general, infra, ML, and paper review.
- Apply the same workflow to new projects (clean slate) and existing projects. The only difference is whether the profile is populated.
- Support two target harnesses in VS Code: **Local** and **Copilot**. Both must work with the same files.
- Out of scope: Claude, Codex, and Gemini harness support. Validate other harnesses with `harness-probe/` before adding them.

## 2. Three-Layer Model

| Layer | Contents | Change frequency | Owner |
|---|---|---|---|
| Core protocol | elephant, 6 skills, stage definitions, verdict format | Template updates only | EG |
| Pack | Per-stage goldfish configuration and goldfish files | Varies by domain | general: EG; others: user |
| Project profile | Project documentation locations, gate commands, storage paths | Varies by project | User |

There are two types of gates:
- **Deterministic gates**: Verdicts are based on the exit codes of the lint, typecheck, and test commands specified in the profile.
- **Judgment gates**: Verdicts are based on the verdict line from the gate goldfish.

## 3. Harness Constraints (Verified by Probes)

| Finding | Evidence | Design implication |
|---|---|---|
| goldfish can be invoked by name | Q1 | elephant invokes it by the name in the manifest |
| The `agents` allowlist is enforced only by Local and ignored by Copilot | Q2 | elephant uses `agents: ['*']`. Safety is enforced through goldfish tool restrictions |
| goldfish file contents are applied | Q3a | Put criteria and verdict lines in the goldfish body |
| Copilot does not pass `copilot-instructions.md` to goldfish | Q3b | Have goldfish read the instructions and profile directly as its first step |
| The body rule to "read first" and two-step references work | Q3c, Q3d | Use the profile as an index pointing to existing documents |
| `tools: ['read','search']` prevents writing | Q4 | All goldfish are read-only |
| Adding `web` still does not allow writing; Copilot shows an approval prompt | Q9 | Only researcher and ideator get `web`. Skills warn in advance that an approval prompt may appear |
| Conversation context is not passed to goldfish | Q5 | goldfish sees only the input passed by elephant |
| Copilot adds metadata such as `<current_datetime>` to input | Q5 | Instruct goldfish to ignore harness metadata |
| Skill arguments arrive unchanged | Q7 | Select the pack from the first word |
| `user-invocable: false` hides an item from the picker | Q8a | Hide all goldfish |
| Skills do not provide tools; they use the selected agent's tools | Q7 | Run the skill after the user selects elephant |
| Values reported by goldfish are unreliable | Note | Use only the prescribed final line for the verdict |
| goldfish (Local) cannot use the question tool | Phase 0 document | Only elephant asks questions |

## 4. File Structure

```text
<project>/
├── .github/
│   ├── copilot-instructions.md        # Adds only the EG block (EG:BEGIN … EG:END)
│   ├── agents/
│   │   ├── elephant.agent.md
│   │   └── goldfish-<pack>-<lens>.agent.md
│   ├── skills/
│   │   ├── eg-setup/SKILL.md
│   │   ├── eg-brainstorm/SKILL.md
│   │   ├── eg-prd/SKILL.md
│   │   ├── eg-new-feature/SKILL.md
│   │   ├── eg-fix-bug/SKILL.md
│   │   └── eg-precommit-review/SKILL.md
│   └── eg/
│       ├── protocol.md                # Shared core rules for skills (owned by EG)
│       ├── profile.md
│       └── packs/<pack>.md
└── .eg-work/<date-skill-slug>/         # Per-task folder (design.md, problem.md, etc.); gitignored
```

## 5. stage

A stage is when goldfish is invoked within a workflow. The core defines stage names and types; packs cannot change them.

| stage | type | skill | input passed by elephant | elephant action |
|---|---|---|---|---|
| `brainstorm` | generate | eg-brainstorm | `LENS`, `RESEARCH`, seed | Synthesize the results |
| `prd-grounding` | generate | eg-prd | `LENS`, seed | Synthesize into a codebase brief |
| `prd-research` | generate | eg-prd | `LENS`, seed, codebase brief, answered gaps | Summarize by lens and consolidate sources |
| `prd` | gate | eg-prd | PRD draft | Iterate |
| `design` | gate | eg-new-feature | Design document | Iterate. Do not write code until it passes |
| `review` | gate | eg-new-feature, eg-fix-bug, eg-precommit-review | Diff file path and optional focus | Iterate |
| `diagnosis` | compare | eg-fix-bug | Symptoms and reproduction steps only; do not pass hypotheses | Compare against its own hypothesis |

Rules by type:
- **gate**: The last line must be `EG-VERDICT: PASS` or `EG-VERDICT: REVISE`. For each finding, elephant either fixes it or rebuts it with evidence. Rebuttals must be supported by documents referenced in the profile, the PRD, or the user's statements. Then rerun the gate.
- **compare**: goldfish answers independently and ends with `EG-DONE`. If its answer differs from elephant's hypothesis, elephant compares the evidence and either revises the hypothesis or records why it is retaining it.
- **generate**: The last line must be `EG-DONE`. elephant synthesizes the results.
- A response without the prescribed final line is invalid. Invoke the same goldfish once more; if the line is still missing, notify the user.

## 6. Pack Manifest

Location: `.github/eg/packs/<pack>.md`.

```markdown
# EG Pack: <name>
description: <one-line description>
extends: <parent pack>            # optional
max-rounds: prd=3, design=3, review=5

| stage | lens | goldfish | use |
|---|---|---|---|
| design | critic | goldfish-general-critic | required |
```

`use` values:

| Value | Meaning |
|---|---|
| `required` | Run every round. A gate stage requires PASS. |
| `info` | Run only in the first round and use for reference only. Matches the source comprehension behavior. |
| `pool` | Candidate list. elephant selects and runs entries with the user; for example, brainstorm uses 3–5. |
| `off` | Disable an inherited row. |

**Inheritance rules**
- Replace a parent row with the same `(stage, lens)`.
- Add new `(stage, lens)` rows.
- Remove rows set to `off`.
- Inherit rows not mentioned by the child. Inherit `max-rounds` per item as well.
- Inheritance is limited to 3 levels. Stop and notify the user if there is a cycle or a parent is missing.
- Goldfish from other packs can also be referenced by name.

**Displaying configuration and handling missing entries**
- At the start of each stage, print the following format. Also record the final merged table at the top of the output document.

  ```text
  [EG] pack=<pack> (extends <parent>) stage=<stage>
  goldfish: <name>(required), <name>(info) …
  deterministic: lint, test | not configured
  ```
- If the merged result has no goldfish:
  - If explicitly set to `off`, notify the user and proceed with the deterministic gates.
  - If a stage definition is missing from a pack with no parent, stop and ask the user.

**Gate verdicts**
- Pass when all `required` goldfish for the stage return PASS.
- If `max-rounds` is exceeded, summarize the remaining findings and ask the user whether to accept, continue, or stop.

## 7. general Pack

```markdown
# EG Pack: general
description: General software development
max-rounds: prd=3, design=3, review=5

| stage | lens | goldfish | use |
|---|---|---|---|
| brainstorm | technical | goldfish-general-ideator | pool |
| brainstorm | business | goldfish-general-ideator | pool |
| brainstorm | ux | goldfish-general-ideator | pool |
| brainstorm | contrarian | goldfish-general-ideator | pool |
| brainstorm | prior-art | goldfish-general-ideator | pool |
| brainstorm | lateral | goldfish-general-ideator | pool |
| brainstorm | first-principles | goldfish-general-ideator | pool |
| prd-grounding | surfaces | goldfish-general-explorer | required |
| prd-grounding | conventions | goldfish-general-explorer | required |
| prd-research | market | goldfish-general-researcher | pool |
| prd-research | tech-patterns | goldfish-general-researcher | pool |
| prd-research | ux-precedent | goldfish-general-researcher | pool |
| prd-research | compliance | goldfish-general-researcher | pool |
| prd-research | scale | goldfish-general-researcher | pool |
| prd | readiness | goldfish-general-prd-readiness | required |
| design | comprehension | goldfish-general-comprehension | info |
| design | critic | goldfish-general-critic | required |
| design | readiness | goldfish-general-readiness | required |
| review | code | goldfish-general-reviewer | required |
| diagnosis | independent | goldfish-general-diagnostician | required |
```

There are 9 goldfish files.
- Create a separate file for each gate and compare lens because their verdict criteria differ.
- For generate lenses, use one general-purpose file per stage and pass `LENS` as input.

| File | Type | tools | Source |
|---|---|---|---|
| goldfish-general-ideator | generate | read, search, web | eg-brainstorm Parallel Goldfish |
| goldfish-general-explorer | generate | read, search | eg-prd Codebase Grounding |
| goldfish-general-researcher | generate | read, search, web | eg-prd Research |
| goldfish-general-prd-readiness | gate | read, search | Newly added (not in source) |
| goldfish-general-comprehension | gate | read, search | eg-new-feature Pass A |
| goldfish-general-critic | gate | read, search | eg-new-feature Pass B |
| goldfish-general-readiness | gate | read, search | eg-new-feature Pass C |
| goldfish-general-reviewer | gate | read, search | eg-precommit-review |
| goldfish-general-diagnostician | compare | read, search | eg-fix-bug Goldfish Diagnosis |

Replace the source completion phrases as follows:

| Source | New verdict line |
|---|---|
| `design ready`, `implementation ready`, `comprehension passed`, `no findings` | `EG-VERDICT: PASS` |
| `design needs revision`, `implementation not ready`, `comprehension unclear`, findings present | `EG-VERDICT: REVISE` |
| `lens complete`, `diagnosis complete` | `EG-DONE` |

## 8. goldfish File Format

```markdown
---
description: <one-line lens description>
tools: ['read', 'search']          # Add 'web' only for researcher and ideator
user-invocable: false
---
# goldfish-<pack>-<lens>

## 0. Read first
Before anything else, read `.github/copilot-instructions.md` and `.github/eg/profile.md`,
then the project docs the profile points to that are relevant to your input.

## 1. Stance
You are a fresh reader with no prior context. Do not ask questions. Do not edit files.
Ignore harness metadata in your input (for example <current_datetime>).

## 2. Input
<input contract for this stage type>

## 3. Criteria
<lens-specific criteria; for gate lenses, state exactly when to answer REVISE>

## 4. Output
<output format>
Last line, exactly one of:
EG-VERDICT: PASS | EG-VERDICT: REVISE        (gate)
EG-DONE                                     (compare / generate)
```

- Name files `goldfish-<pack>-<lens>`. For derived packs, make the lineage clear in the name, e.g. `goldfish-general-varpack1-structure`.
- Set the `name` field to the same value as the filename. This format was verified by probes.
- Do not use `agents` or `handoffs`. Copilot ignores or rejects them.

## 9. elephant

```markdown
---
name: elephant
description: EG coordinator. Select this agent, then run an /eg-* skill.
tools: ['agent', 'read', 'search', 'edit', 'execute', 'web', 'todo']
agents: ['*']
---
```

Rules for the body:
- Do not invoke goldfish until instructed by the skill.
- Pass goldfish only the input specified by the stage. Do not pass conversation history, intent, other goldfish results, or verdict criteria.
- Use only the prescribed final line for verdicts.
- Only elephant asks the user questions.
- Preserve the source No-code gate. Do not modify code before the `design` stage passes, unless the user explicitly overrides this.
- Do not commit.

## 10. Skills

Shared frontmatter:

```yaml
name: eg-<workflow>
description: <one line>
argument-hint: "[pack] <task description>"
disable-model-invocation: true
```

### Shared Flow (Except eg-setup)
Write shared rules once in `.github/eg/protocol.md` (P0–P5), and have each skill read this file in its first step. Keep only workflow-specific tasks in each skill body.

0. **Parse arguments**: If the first word exactly matches a pack name that exists in `.github/eg/packs/`, use that pack. Otherwise, treat the entire argument as the task description and use the profile's `default-pack` (or `general` if unset).
1. **Read context**: Read `copilot-instructions.md`, `profile.md`, and the documents referenced by the profile. If the profile is `not configured`, ask the user whether to run eg-setup first or proceed without deterministic gates.
2. **Resolve pack**: Merge inheritance and print the configuration.
3. **Workflow-specific tasks**: Follow the table below.
4. **Run goldfish**: Handle according to the stage type. Before invoking goldfish that use the web, warn that an approval prompt may appear.
5. **Deterministic gates**: Run the profile commands one at a time. Block only errors introduced by the current change. Record pre-existing failures as out of scope.
6. **Save and summarize**: Save to the profile's `doc-path`. Summarize the pack used, number of rounds, verdicts, and verbatim rebuttals.

### Workflow-Specific Tasks

| Skill | Workflow-specific tasks (based on source) | stage |
|---|---|---|
| eg-setup | Inspect the repository, draft a profile, and save it after user confirmation. Check the EG block in copilot-instructions. | None |
| eg-brainstorm | Refine and confirm seed → choose 3–5 lenses from pool → run ideators in parallel → synthesize | brainstorm |
| eg-prd | Codebase grounding → list gaps and questions → research (optional) → draft PRD → readiness gate | prd-grounding, prd-research, prd |
| eg-new-feature | Restate scope → design document → design gate (No-code gate) → implementation plan and layer-by-layer implementation → review → deterministic gates | design, review |
| eg-fix-bug | Determine whether the fix is trivial → problem doc → compare independent diagnoses → failing test → fix → review → deterministic gates | diagnosis, review |
| eg-precommit-review | Preliminary checks (skip when only docs changed, etc.) → deterministic gates → iterate on review | review |

### Review Input
- goldfish has no terminal, so it cannot run `git diff` directly.
- Therefore, elephant writes `git status`, `git diff`, `git diff --cached`, `git diff <base>...HEAD`, and the list of untracked files to `<work>/review-round<N>.diff` (`<work>` is the per-task folder `.eg-work/<yyyy-mm-dd>-<skill>-<slug>/`). Pass goldfish only this file path and optional focus.
- From the second round onward, also pass a list of changes made in the previous round.
- If this is not a git repository, elephant copies existing files to `<work>/baseline/` before first modifying them, then writes the `diff -u` output and full contents of new files to the same diff file during review. The filename is always `review-round<N>.diff`.

## 11. Profile

Location: `.github/eg/profile.md`. This is an index pointing to documents that contain the facts, rather than a copy of those facts.

```markdown
# EG Profile
status: configured | not configured

## EG settings
default-pack: general
doc-path: docs/eg/
base-branch: main

## Project docs
- README.md: <what it covers>
- docs/...: <what it covers>

## Deterministic gates
lint: <command | not configured>
typecheck: <command | not configured>
test: <command | not configured>
e2e: <command | not configured>

## Runtime verification
dev-server: <command and URL | not configured>
```

- List gate commands directly; do not just point to their locations.
- Review checklists and stack-specific cautions are criteria for judgment, so keep them in packs. The profile may list only the locations of those documents.

EG block in `copilot-instructions.md`:

```markdown
<!-- EG:BEGIN -->
## Elephant/Goldfish
This project uses the EG workflow. Profile: `.github/eg/profile.md`. Packs: `.github/eg/packs/`.
To start: select the `elephant` agent, then run `/eg-new-feature`, `/eg-fix-bug`, `/eg-prd`, `/eg-brainstorm`, `/eg-precommit-review`, or `/eg-setup`.
<!-- EG:END -->
```

## 12. Distribution and Installation

Template repository structure. Empty the existing `github-copilot-eg-template/` and recreate it.

```text
github-copilot-eg-template/
├── .github/            # Content to copy into the target project (Section 4)
├── install.sh
├── harness-probe/      # Moved from eg-probe
├── LICENSE.elephant-goldfish   # Original MIT license
├── docs/DESIGN.md      # This document
└── README.md
```

Installation:
- **New project**: Copy `.github/` and add `.eg-work/` to `.gitignore`.
- **Existing project**: Run `install.sh <target>`.
  - Do not overwrite existing files; print only a list of conflicts.
  - Add the EG block to `copilot-instructions.md`. On reinstall, replace only that block.
  - Add `.eg-work/` to `.gitignore`.
- Also document the manual copy procedure in the README.

File ownership:

| EG-owned (overwritten on update) | User-owned (left untouched) |
|---|---|
| `skills/eg-*`, `agents/elephant`, `agents/goldfish-general-*`, `eg/protocol.md`, `eg/packs/general.md`, EG block | `eg/profile.md`, user-created packs and goldfish |

To customize the general pack, create a derived pack with `extends: general` rather than editing the general pack file directly.

## 13. Phase 4: Implementation and Validation

### Implementation Order
1. Recreate the template repository and move `eg-probe/` to `harness-probe/`.
2. Create elephant, the general pack manifest, and 9 goldfish files.
3. Create 6 skills. Start with eg-precommit-review; its simple gate loop will serve as the model for the other skills.
4. Create `install.sh` and the README.

### Validation Items (for Local and Copilot separately)

| ID | What to verify | Why it is still unknown |
|---|---|---|
| V1 | Whether elephant can run gate commands with `execute` | The probed elephant did not have `execute` |
| V2 | Whether reviewer can read `<work>/*.diff` and cite file:line | Reading limits for large diffs are unknown |
| V3 | Whether elephant merges inheritance correctly | Verify with a derived pack at depth 2 |
| V4 | Whether it handles missing prescribed final lines or truncated responses | Truncation during relay has already been observed |
| V5 | Q8b: Whether skills are not invoked automatically | Not yet verified in either harness |
| V6 | Whether goldfish can be invoked in parallel (brainstorm, research) | Not yet verified. Invoke sequentially if not possible |
| V7 | Whether the full eg-new-feature workflow completes in a sample project | Integration validation |
| V8 | install.sh: empty project, project with existing instructions, reinstall | **Passed** (2026-10-31, five scenarios: empty/existing/reinstall/`--update`/invalid input) |

## 14. Open Decisions

- Name and location of `.eg-work/`. For now, assume it lives at the repository root and is gitignored.
- Whether to write the template README and this document in English. Decide based on the intended audience.
- Whether to record the model used with the Copilot harness. Results may vary by model.
