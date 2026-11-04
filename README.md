# EG for GitHub Copilot

A template for using the elephant/goldfish (EG) workflow with GitHub Copilot in VS Code.

- **elephant**: An agent that knows the full conversation and codebase. It writes docs and code, runs commands, and talks with you.
- **goldfish**: A read-only subagent that starts fresh without chat history. It reviews or generates ideas using only the documents elephant provides, catching issues that familiarity can make you miss.

Based on Vladyslav Shvedov’s elephant-goldfish (MIT), which is for Claude Code, Codex, and Gemini CLI. See [docs/DESIGN.md](docs/DESIGN.md) for the design rationale.

## Supported harnesses

Verified with the **Local** and **Copilot** harnesses in VS Code Chat. To use another harness, validate it first with [harness-probe/README.md](harness-probe/README.md).

## Installation

### Existing project

```sh
./install.sh /path/to/project
```

- Existing files are never overwritten. Files with different contents are skipped and listed.
- If `.github/copilot-instructions.md` exists, only the `<!-- EG:BEGIN -->` … `<!-- EG:END -->` block is appended.
- Adds `.eg-work/` to `.gitignore`.
- To update the template, run `./install.sh /path/to/project --update`. Only EG-owned files are overwritten; the profile and custom packs are left untouched.

### New project (manual installation)

1. Copy `.github/` from this repository to the project root. If `.github/copilot-instructions.md` already exists, append only the EG block.
2. Add `.eg-work/` to `.gitignore`.

### After installation

1. Open the project folder as the **workspace root** in VS Code.
2. In Chat, **select the `elephant` agent**.
3. Run `/eg-setup` to fill in the profile (`.github/eg/profile.md`).

When using the Local harness, the Run Subagent tool must be enabled.

## Usage

**Always select the `elephant` agent first**, then run a skill. Skills use the tools of the currently selected agent.

| Skill | What it does |
|---|---|
| `/eg-setup` | Scans the repository, drafts a profile, and saves it after your confirmation. |
| `/eg-brainstorm <idea>` | Goldfish agents representing different perspectives offer ideas, and elephant synthesizes them. |
| `/eg-prd <idea>` | Proceeds through codebase exploration, gap questions, research, PRD drafting, and goldfish readiness checks. |
| `/eg-new-feature <feature>` | Creates a design doc, runs a goldfish design review, implements, reviews, and tests. No code is written until the design passes. |
| `/eg-fix-bug <bug>` | Creates an issue doc, compares independent goldfish diagnoses, adds a failing test, fixes the bug, then reviews and tests. |
| `/eg-precommit-review [focus]` | Runs deterministic gates and iterates on goldfish reviews. |

- To use a non-default pack, put its name first. Example: `/eg-new-feature infra add a staging bucket`
- The first word is treated as a pack only if it exactly matches an existing pack name. Otherwise, the entire input is treated as the task description.
- In the Copilot harness, a consent prompt may appear when running goldfish that use the web (brainstorming or PRD research).
- No commits are made.

## Structure

```text
.github/
├── copilot-instructions.md     # EG block
├── agents/
│   ├── elephant.agent.md
│   └── goldfish-<pack>-<lens>.agent.md
├── skills/eg-*/SKILL.md
└── eg/
    ├── protocol.md             # Core rules shared by skills
    ├── profile.md              # Project profile (project-owned)
    └── packs/<pack>.md         # Pack manifest
```

| EG-owned (overwritten by `--update`) | Project-owned (left untouched) |
|---|---|
| `eg/protocol.md`, `eg/packs/general.md`, `agents/elephant.agent.md`, `agents/goldfish-general-*`, `skills/eg-*`, EG block | `eg/profile.md`, custom packs and goldfish |

## Packs

A pack specifies which goldfish to use at each stage (a point in the workflow where goldfish is called).

```markdown
# EG Pack: general
description: General software development
max-rounds: prd=3, design=3, review=5

| stage | lens | goldfish | use |
|---|---|---|---|
| design | critic | goldfish-general-critic | required |
```

- **stage**: One of `brainstorm`, `prd-grounding`, `prd-research`, `prd`, `design`, `review`, or `diagnosis`. This list is fixed and cannot be changed by a pack.
- **use**:

  | Value | Meaning |
  |---|---|
  | `required` | Runs every round; its verdict can block the gate. |
  | `info` | Runs only in the first round and is informational only. |
  | `pool` | Selected and run together with the user. |
  | `off` | Removes the inherited row. |

### Creating a pack (general variant)

Extend the general pack instead of editing it directly. Direct edits will be overwritten during updates.

1. Create `.github/eg/packs/myteam.md`.

   ```markdown
   # EG Pack: myteam
   description: General plus a stricter security critic
   extends: general

   | stage | lens | goldfish | use |
   |---|---|---|---|
   | design | critic | goldfish-myteam-critic | required |
   | design | security | goldfish-myteam-security | required |
   | design | comprehension | - | off |
   ```

2. Create the goldfish agents you need, such as `.github/agents/goldfish-myteam-critic.agent.md`. You can start by copying `goldfish-general-critic.agent.md`.
3. Change `default-pack` in the profile, or specify the pack name as the first word when running a skill. Example: `/eg-new-feature myteam ...`

**Inheritance rules**
- The same `(stage, lens)` replaces the inherited row.
- A new `(stage, lens)` is added.
- `off` removes the row.
- Rows not mentioned are inherited unchanged.
- Inheritance is limited to three levels.

### Rules for writing goldfish agents

- In the frontmatter, include `tools: ['read', 'search']` and `user-invocable: false`. Add `'web'` only when web access is needed.
- Make the first step read `.github/copilot-instructions.md` and `.github/eg/profile.md`. The Copilot harness does not automatically pass instruction files to goldfish.
- The last line must be one of the following:
  - `EG-VERDICT: PASS` or `EG-VERDICT: REVISE` (gate stage)
  - `EG-DONE` (all other stages)

## License

The goldfish prompts and skill workflows are based on Vladyslav Shvedov’s elephant-goldfish (MIT). The full original license is available at [LICENSE.elephant-goldfish](LICENSE.elephant-goldfish).
