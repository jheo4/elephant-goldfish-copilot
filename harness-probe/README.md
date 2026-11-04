# EG Harness Compatibility Probe

This folder is an experimental kit for checking how agent harnesses in VS Code (Local, Copilot, Claude, Codex, Cloud, etc.) support the capabilities required by the elephant/goldfish (EG) workflow.

When testing a new harness, follow this document from top to bottom. The [decision table](#5-move-the-results-into-the-eg-design) at the end turns the results into EG design decisions. Record experiment results by adding a column to [Results log](#6-results-log).

## 1. What We Check

| ID | Question | Why It Matters for EG |
|---|---|---|
| Q1 | Can elephant call goldfish by name? | Select pack-specific goldfish by name |
| Q2 | Is elephant's `agents` allowlist enforced? | Determines whether the elephant file must be edited when adding a pack |
| Q3a | Does goldfish receive the body of its own agent file? | Determines where to put goldfish role rules |
| Q3b | Does goldfish automatically receive `.github/copilot-instructions.md`? | Determines whether the project profile reaches goldfish |
| Q3c | Does the body rule "read the instruction file first" work? | Alternative when Q3b is no |
| Q3d | Does goldfish also read and follow other documents (such as `docs/`) referenced by the instruction file? | Determines whether the profile can be an index pointing to existing README and docs |
| Q4 | Does `tools: ['read', 'search']` actually block writes? | Read-only guarantee for goldfish |
| Q5 | Does goldfish avoid inheriting elephant's conversation context? | Core goldfish premise |
| Q6 | Can goldfish read the pack manifest file? | Determines whether pack definitions can be files |
| Q7 | Are skill arguments passed through verbatim? | Pack selection in the form `/eg-x <pack> <content>` |
| Q8a | Is a `user-invocable: false` goldfish hidden from the agent picker? | Expose only elephant to users |
| Q8b | Is a skill with `disable-model-invocation: true` prevented from being invoked automatically? | Start the workflow only through explicit invocation |
| Q9 | If goldfish has the `web` tool, can it fetch web pages, and does `web` leave write permissions unchanged? | Whether researcher/ideator goldfish can search the web |

## 2. Kit Contents

Use as-is; do not modify. Each file contains an embedded **behavior signal** that appears in the output.

| File | Role | Embedded Signal |
|---|---|---|
| `.github/copilot-instructions.md` | repo instructions | `BEHAVIOR-RULE-I`: **line 2** of goldfish response is `I-RULE-ACTIVE`. `PROJECT-DOCS`: tells goldfish to read `docs/general/probe-notes.md` |
| `docs/general/probe-notes.md` | Existing project document | `BEHAVIOR-RULE-D`: **line 3** of goldfish response is `D-RULE-ACTIVE` |
| `.github/agents/probe-elephant.agent.md` | Orchestrator, `agents: ['*']` | None |
| `.github/agents/probe-elephant-restricted.agent.md` | Orchestrator, `agents: ['probe-goldfish-a']` | None (Q2 only) |
| `.github/agents/probe-goldfish-a.agent.md` | Read-only goldfish, **no read rule** | `BEHAVIOR-RULE-A`: **line 1** is `A-RULE-ACTIVE` |
| `.github/agents/probe-goldfish-b.agent.md` | Read-only goldfish, **with read rule** | `BEHAVIOR-RULE-B`: **line 1** is `B-RULE-ACTIVE`, and read instruction files before the task |
| `.github/agents/probe-goldfish-w.agent.md` | Read + `web` goldfish | `BEHAVIOR-RULE-W`: **line 1** is `W-RULE-ACTIVE`, reports `WEB_ATTEMPT` |
| `.github/skills/eg-probe/SKILL.md` | Skill for explicit invocation only | Reports `RAW_ARGUMENT`, `PACK_CANARY` |
| `packs/pack-a.md` | Pack manifest example | `PACK-CANARY: CANARY-PACK-A-8842` |

Goldfish appends a `PROBE-REPORT` block at the end of its response. Use these principles to evaluate results:

- **Primary evidence is behavior signals** (line 1/2 text, actual tool calls, error messages).
- Reports of values such as `AGENT_CANARY` and `INSTRUCTION_CANARY` are **for reference only**. In practice, the model may answer `NONE` despite receiving the instructions, because it may not want to state its own instruction contents.

## 3. Preparation

1. Open **this `harness-probe/` folder as the workspace root** in VS Code. If you open a parent folder, `.github/` may not be recognized.
2. In the Chat view's **Session Target**, select the harness to test.
3. If the harness requires enabling a subagent tool separately, enable it. For example, in Local, select **Run Subagent** (`agent/runSubagent`) under **Configure Tools**.
4. Add the harness name, date, VS Code version, and model to the results log.

Procedure:

- Start a **new chat** for each experiment. Exception: T6 sends two messages in order within one chat.
- Paste prompts into the **chat input**. Pasting them into the open agent-file editor breaks the frontmatter and invalidates the result (this has happened).
- Record results **verbatim**; do not summarize them.
- If a response is truncated or lacks `PROBE-REPORT`, treat it as **invalid** because elephant summarized it, and run it again.
- Run T2 and T6 **twice** to account for model response variability.

## 4. Experiments

Unless otherwise specified, select `probe-elephant` in the agent picker.

### T0. Visibility Check (Q8a)

Open the agent picker. Type `/` to open the skill list as well.

- Pass: `probe-elephant` and `probe-elephant-restricted` are visible, while `probe-goldfish-a` and `probe-goldfish-b` are hidden. `eg-probe` is in the skill list.
- If the harness has no picker, record `n/a`.

### T1. Call by Name + Body Delivery (Q1, Q3a)

```text
Use the probe-goldfish-a subagent. Pass it exactly this task: "hello-T1". Report its complete output verbatim, with no omissions, including the PROBE-REPORT block.
```

- Q1 pass: `NAME: probe-goldfish-a`, and `INPUT_ECHO` contains `hello-T1`.
- Q3a pass: **line 1 is `A-RULE-ACTIVE`**.

### T2. Automatic Repo-Instruction Delivery (Q3b) - 2 Runs

Evaluate T1's output as-is. For the second run, repeat the T1 prompt in a new chat.

- Yes: for example, **line 2 is `I-RULE-ACTIVE`**. Since goldfish-a has no read rule, this signal can only come from automatic delivery.
- No: line 2 does not contain `I-RULE-ACTIVE`.

### T3. Read-Instruction-File-First Rule (Q3c)

```text
Use the probe-goldfish-b subagent. Pass it exactly this task: "hello-T3". Report its complete output verbatim, with no omissions, including the PROBE-REPORT block.
```

- Pass: a tool call reading `.github/copilot-instructions.md` is visible, and **line 1 is `B-RULE-ACTIVE`, line 2 is `I-RULE-ACTIVE`**.
- If T2 is no but T3 passes, the read rule causes the instructions to be applied (T2 is the control).

### T4. Allowlist Enforcement (Q2)

Switch to the **`probe-elephant-restricted`** agent.

```text
Use the probe-goldfish-b subagent. Pass it exactly this task: "hello-T4". Report its complete output verbatim, or the exact error.
```

- Enforced: the call is rejected. Record the exact error (Local example: `Requested agent 'probe-goldfish-b' is not allowed by the current agent.`).
- Ignored: a normal response with `NAME: probe-goldfish-b`.
- Note: if **another goldfish (a) responds instead** without a rejection, the result is invalid. Be sure to check `NAME`.

### T5. Read-Only (Q4)

```text
Use the probe-goldfish-a subagent. Task: "Create a file named probe-write-test.txt containing the word hi." Report its complete output verbatim.
```

- Pass: `WRITE_ATTEMPT: NO_TOOL` or `REFUSED`, and **the `harness-probe/probe-write-test.txt` file is not actually created**.
- File existence is the final evidence. If it was created, record a failure and delete the file.

### T6. Conversation Context Isolation (Q5) - 2 Runs

Send the following messages in order in one chat.

```text
Remember this: the secret word is PINEAPPLE-42. Just acknowledge.
```

```text
Use the probe-goldfish-a subagent. Pass it exactly this task: "hello-T6". Report its complete output verbatim, with no omissions, including the PROBE-REPORT block.
```

- Pass: `SECRET_WORD_SEEN: NONE`, and `PINEAPPLE-42` does not appear anywhere in the response.
- If metadata added by the harness (for example, `<current_datetime>`) appears in `INPUT_ECHO`, record it. This is not an isolation failure.

### T7. Read Pack File (Q6)

```text
Use the probe-goldfish-a subagent. Task: "Read packs/pack-a.md and quote the PACK-CANARY value." Report its complete output verbatim.
```

- Pass: a file-reading tool call is visible and `CANARY-PACK-A-8842` is quoted.

### T8. Skill Arguments (Q7)

Send each in a new chat.

```text
/eg-probe pack-a some free text
```

```text
/eg-probe
```

- Pass: the first gives `RAW_ARGUMENT: pack-a some free text`, `PACK_CANARY: CANARY-PACK-A-8842`. The second gives `RAW_ARGUMENT: EMPTY`, and the default pack is `CANARY-PACK-A-8842`.
- The reported `agent/edit/read` list is the **selected agent's** tools, not the skill's.

### T9. Block Automatic Skill Invocation (Q8b)

Send without `/` in a new chat.

```text
Please probe the pack setup.
```

- Pass: the `eg-probe` skill is not loaded (there is no skill-read tool call).

### T10. Follow Documents Referenced by Instructions (Q3d)

`PROJECT-DOCS` in `copilot-instructions.md` tells goldfish to read `docs/general/probe-notes.md`. Call each goldfish in a new chat.

```text
Use the probe-goldfish-b subagent. Pass it exactly this task: "hello-T10". Report its complete output verbatim, with no omissions, including its first three lines.
```

```text
Use the probe-goldfish-a subagent. Pass it exactly this task: "hello-T10". Report its complete output verbatim, with no omissions, including its first three lines.
```

- goldfish-b pass: tool calls reading both `copilot-instructions.md` and `docs/general/probe-notes.md` are visible, and **line 3 is `D-RULE-ACTIVE`**. This means the two-step reference from body → instruction file → project document works.
- goldfish-a: `D-RULE-ACTIVE` may appear only in harnesses where instructions are automatically delivered (for example, Q3b = yes). This checks the one-step reference from instruction → project document. It is normal for it not to appear in a harness where Q3b is no.
- After this rule is added, `D-RULE-ACTIVE` may also appear on line 3 in T1–T7. This does not affect the T1–T7 evaluations.

### T11. Goldfish Web Access (Q9)

Run each in a new chat. If a web-access approval dialog appears, allow access and record that it appeared.

```text
Use the probe-goldfish-w subagent. Pass it exactly this task: "Fetch https://example.com and report the page's main heading." Report its complete output verbatim.
```

```text
Use the probe-goldfish-w subagent. Pass it exactly this task: "Create a file named probe-write-test.txt containing the word hi." Report its complete output verbatim.
```

```text
Use the probe-goldfish-a subagent. Pass it exactly this task: "Fetch https://example.com and report the page's main heading." Report its complete output verbatim.
```

- goldfish-w run 1 pass: line 1 `W-RULE-ACTIVE`, `WEB_ATTEMPT: SUCCEEDED: Example Domain`, and `TOOLS` includes a fetch-type tool.
- goldfish-w run 2 pass: `WRITE_ATTEMPT: NO_TOOL`, and `probe-write-test.txt` is not created.
- goldfish-a (control): it should not be able to fetch the page because it has no web tool. If it can, that means `read`/`search` includes web access.

## 5. Move the Results into the EG Design

| Result | EG Design Decision |
|---|---|
| Q1 no | Pack-specific goldfish cannot be named. Exclude this harness from support or have elephant include the goldfish definition directly in the delegation prompt. |
| Q2 enforced | Set `agents: ['*']` on elephant. With a specific list, elephant must be edited every time a pack is added. |
| Q2 ignored | `agents` has no effect. Leaving `['*']` as-is is harmless. |
| Q3a yes | Put goldfish roles and evaluation rules in the goldfish agent-file body. |
| Q3a no | When delegating, elephant must include the goldfish definition file contents in the prompt. |
| Q3b yes | If the profile is in `copilot-instructions.md`, goldfish sees it too. The read rule is redundant but harmless. |
| Q3b no, Q3c yes | The top of the goldfish body must include a rule to "read instruction and profile files before the task." |
| Q3b no, Q3c no | Elephant includes the required profile contents directly in the delegation prompt. |
| Q3d yes | Make the profile an index pointing to the existing README and `docs/`. Do not copy project facts into `.github`. |
| Q3d no | Put the project document paths to read directly in the goldfish body, or have elephant summarize the needed information in a document during the skill step. |
| Q4 no | Read-only behavior cannot be structurally guaranteed. Do not use goldfish in this harness or explicitly document the risk. |
| Q5 no | Goldfish is not independent. This breaks a core EG premise, so exclude the harness from support. |
| Q6 yes | Keep pack manifests as files and have elephant and goldfish read them. |
| Q7 yes | Select a pack using the first word of the skill argument, and use the default pack if absent. |
| Q7 no | Get pack selection from conversation text or the profile default instead of an argument. |
| Q8a no | Goldfish is exposed in the picker. This is not a functional problem, but user guidance is needed. |
| Q8b no | The skill may run automatically. Add an explicit-invocation confirmation step to the skill body. |
| Q9 yes | Add `web` to researcher/ideator goldfish and require source citations. |
| Q9 no | Elephant does the web research directly, or limit goldfish research to the codebase and documents. |

Principles to follow across all harnesses:

- Only elephant asks the user questions. Subagents may not be able to use question tools.
- Evaluate goldfish passes using **behavior signals**, such as a designated final line.

## 6. Results Log

When testing a new harness, add a column. Use one of `Yes`, `No`, `Enforced`, `Ignored`, `Unverified`, `n/a`, with brief evidence.

| ID | Local | Copilot |
|---|---|---|
| Test date | 2026-10-31 | 2026-10-31 |
| Model | GPT-6 Luna | Unrecorded |
| Q1 Named call | Yes | Yes |
| Q2 Allowlist | Enforced (`not allowed by the current agent`) | Ignored (ran goldfish-b outside the list) |
| Q3a Body delivery | Yes (`A-RULE-ACTIVE`) | Yes (`A-RULE-ACTIVE`, `B-RULE-ACTIVE`) |
| Q3b Automatic instruction delivery | Yes (line 2 `I-RULE-ACTIVE`, 2 runs) | No (goldfish-a has no line 2 signal, 2 runs) |
| Q3c Read rule | Yes (harmless, redundant) | Yes (line 2 `I-RULE-ACTIVE` after reading the file) |
| Q3d Two-step reference | Yes (goldfish-b: lines 1–3 are B, I, D after reading both files. In T11, goldfish-a also followed the pointer in automatically delivered instructions and had D on line 3) | Yes (goldfish-b: lines 1–3 are B, I, D after reading both files. goldfish-a has only A on line 1, consistent with Q3b) |
| Q4 Read-only | Yes (`NO_TOOL`) | Yes (`NO_TOOL`) |
| Q5 Context isolation | Yes | Yes (input contained `<current_datetime>` metadata) |
| Q6 Read pack file | Yes | Yes |
| Q7 Skill arguments | Yes (empty argument `EMPTY`) | Yes (empty argument `EMPTY`) |
| Q8a Hide goldfish | Yes | Yes |
| Q8b Block automatic invocation | Unverified | Unverified |
| Q9 Goldfish web access | Yes (goldfish-w: confirmed `Example Domain` with `fetch_webpage`; writes are `NO_TOOL`. `web` also adds `github_repo`, `github_text_search`. goldfish-a could not fetch. No approval dialog) | Yes (goldfish-w: confirmed `Example Domain` with `web_fetch`; writes are `NO_TOOL`. goldfish-a could not fetch. **Web-access approval dialog appeared**) |

Notes:

- The results above for Q2 and Q3c were measured with an earlier version of the kit.
- In both harnesses, goldfish's `read` and `search` tools were reported as multiple read-type tool aliases. No write or terminal-execution tools were present.
- In Copilot, value reporting (`AGENT_CANARY`) varied between `NONE` and the actual value across runs of the same goldfish. Behavior signals were consistent.
- In Copilot T11, goldfish-a reported `SECRET_WORD_SEEN: secret word`, which was not in the input. Do not use values in report fields as evaluation evidence.

### Shared Design from the Two Harness Results

1. Put goldfish rules in the agent-file body.
2. Put a rule to read instruction and profile files at the top of the goldfish body. It is required in Copilot and harmless in Local.
3. Set `agents: ['*']` on elephant, and ensure safety with goldfish's `tools: ['read', 'search']`.
4. Select a pack using the first word of the skill argument, and use the default pack if absent.
5. Make the profile an index pointing to the existing README and `docs/` (Q3d). Do not copy project facts into `.github`.
6. Add `web` to `tools` only for goldfish that need web research (researcher, ideator) (Q9). `web` does not increase write permissions.
