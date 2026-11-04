---
name: eg-setup
description: EG setup. Scans the repository and fills .github/eg/profile.md after user confirmation.
argument-hint: "(no arguments)"
disable-model-invocation: true
---
# EG Setup

Fill or refresh the EG project profile. No goldfish run in this skill. Do not change any file other than `.github/eg/profile.md`, `.github/copilot-instructions.md`, and `.gitignore`, and only after the user confirms.

## 1. Check installation
Confirm these exist and report anything missing: `.github/eg/protocol.md`, `.github/eg/packs/general.md`, `.github/agents/elephant.agent.md`, and at least one `goldfish-*.agent.md`.

Confirm `.github/copilot-instructions.md` contains the block between `<!-- EG:BEGIN -->` and `<!-- EG:END -->`. If missing, offer to append it (copy it from the EG template README).

Confirm `.gitignore` contains `.eg-work/`. If missing, offer to add it.

## 2. Scan
Read `.github/eg/profile.md` if it exists. Then look for, without running anything:

- Project docs: `README*`, `CONTRIBUTING*`, `ARCHITECTURE*`, `AGENTS.md`, `CLAUDE.md`, `docs/`, ADR folders, and the rest of `.github/copilot-instructions.md` and `.github/instructions/`.
- Gate commands: `package.json` scripts, `Makefile`, `justfile`, `Taskfile`, `pyproject.toml`, `tox.ini`, `noxfile.py`, `Cargo.toml`, `go.mod`, `build.gradle`, `pom.xml`, and CI workflows under `.github/workflows/`. Prefer the commands CI actually runs.
- Runtime: dev server scripts and the URL or port they use.
- Base branch: from the git default branch or CI triggers.
- An existing docs folder suitable for `doc-path`.
- Packs: the files in `.github/eg/packs/`.

## 3. Draft
Show a draft of the full profile in this format:

```markdown
# EG Profile
status: configured

## EG settings
default-pack: <pack>
doc-path: <path>
base-branch: <branch>

## Project docs
- <path>: <what it covers, in a few words>

## Deterministic gates
lint: <command | not configured>
typecheck: <command | not configured>
test: <command | not configured>
e2e: <command | not configured>

## Runtime verification
dev-server: <command and URL | not configured>
```

Rules:
- List where facts live; do not copy project facts into the profile.
- Write gate commands exactly as they should be run. Use `not configured` when unsure, and say why.
- For a new project with nothing to find, keep `not configured` entries and set `status: configured` only if the user confirms.

## 4. Confirm and write
Ask the user to approve or correct each section. Write `.github/eg/profile.md` only after approval. Offer to run each gate command once to confirm it works; report the results.
