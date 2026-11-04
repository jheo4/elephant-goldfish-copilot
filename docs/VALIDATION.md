# EG Behavior Validation (Phase 4)

This runbook verifies that installed EG behaves as intended in the harness. Record both Local and Copilot results for each item. When validating a new harness, run [harness-probe](../harness-probe/README.md) first, then proceed with this document.

## Preparation

1. Prepare a validation project named `eg-sandbox`. It is a small shopping cart library like the one below.
   - `src/cart.js`, `test/cart.test.js`
   - `npm test`, `npm run lint`
   - In the baseline state, both tests pass.
2. Install EG with `install.sh`.
3. The sandbox has two packs for inheritance validation.
   - `.github/eg/packs/strict.md`: `extends: general`
   - `.github/eg/packs/strict2.md`: `extends: strict`
4. Two bugs are seeded in the sandbox. The existing tests do not catch them.
   - `total()` ignores the quantity (qty).
   - The comment says "discount for 10000 or more," but the code uses `>`.
5. In VS Code, open **`eg-sandbox/` as the workspace root**. Start each item in a **new chat**, select the **`elephant` agent**, and run it.
6. Reset the sandbox after each item.

   ```sh
   git checkout -- . && git clean -fd -e .eg-work
   ```

   Profiles created by V0 are lost when you reset. Profiles you committed remain.

## Items

### V0. Setup and visibility

- **Task:** Check the agent picker and the `/` skills list.
- **Pass criteria:**
  - `elephant` appears in the picker.
  - `goldfish-*` does not appear.
  - All 6 skills (`eg-setup`, `eg-brainstorm`, `eg-prd`, `eg-new-feature`, `eg-fix-bug`, `eg-precommit-review`) are listed.

### V5. Blocking automatic skill invocation (probe Q8b)

**Task:** In a new chat, send the following without a slash.

```text
Review my pending changes before I commit.
```

**Pass criteria:** The `eg-precommit-review` skill is not loaded. There is no goldfish call either.

### V1. elephant command execution and eg-setup

**Task:**

```text
/eg-setup
```

**Pass criteria:**
- A profile draft is produced that includes:
  - `lint: npm run lint`
  - `test: npm test`
  - A Project docs entry pointing to `README.md`
- No files are written before approval.
- When asked whether to try running a command once, if approved, elephant **actually runs the command** and reports the result (2 passing tests). This is the key part of V1.

Commit the profile for subsequent items.

```sh
git add -A && git commit -m "eg profile"
```

### V3. Inheritance merge

**Task:**

```text
/eg-new-feature strict2 add a clearCart(cart) function that empties the cart
```

**Pass criteria:** The configuration printed when the `design` stage starts should be as follows.
- **design configuration:**
  - Required goldfish:
    - `goldfish-general-critic/critic(required)`
    - `goldfish-general-readiness/readiness(required)`
    - `goldfish-general-prd-readiness/prd-check(info)`
  - comprehension must be **absent**.
- **Maximum design rounds:** 2
- **review stage:** The message `no goldfish (turned off by pack)` appears, and only the deterministic gate runs.
- **Saved document:** A merged table appears at the top.

### V7. Full eg-new-feature flow

**Task:**

```text
/eg-new-feature add applyCoupon(cart, percent) that applies a percentage discount on top of the existing bulk discount
```

**Pass criteria:**
- **Design phase:**
  - The design document is created at `.eg-work/<date-feature-slug>/design.md`.
  - In design round 1, comprehension, critic, and readiness are called.
  - From round 2 onward, only critic and readiness are called.
  - The input passed to goldfish contains no conversation history or intent. Expand the call input to check.
- **No-code gate:**
  - `src/` is unchanged until design passes.
  - If you send `just write the code` midway, elephant refuses and asks for the override phrase.
- **After implementation:**
  - Tests are added after implementation.
  - Review rounds run, and `review-round1.diff` is created in the same work folder (deleted on exit).
  - The final report includes all of the following: pack used, round count, verdict, original rebuttal, and gate results.

### V2. Reviewer reads the diff file

Check this together during the V7 review stage or V8b.

**Pass criteria:**
- Reviewer findings start with `file:line`.
- The input contains only `DIFF: <work folder>/review-round<N>.diff`; it does not contain the diff body.

### V8b. eg-fix-bug (compare stage)

**Task:**

```text
/eg-fix-bug adding the same item with qty 3 at 500 cents shows a total of 500 instead of 1500
```

**Pass criteria:**
- **Diagnosis (compare stage):**
  - elephant's hypothesis is written first in `problem.md` in the work folder.
  - The diagnostician input contains only `SYMPTOM` and `REPRO`, with no hypothesis or suspected location.
  - The matching or mismatching comparison result is recorded.
- **Fix and review:**
  - A failing test is added before the fix.
  - That test passes after the fix.
  - The review passes.
- If goldfish or elephant finds the discount boundary (`>` vs `>=`), record it as **extra credit**. It is not required.

### V6. Parallel calls and web approval

**Task:**

```text
/eg-brainstorm a feature that makes the cart library useful for subscription billing
```

For the Frame questions, answer breadth 5, web on.

**Pass criteria:**
- Invoke ideator with 3–5 lenses. Record whether the calls are **parallel** or sequential.
- elephant gives advance notice before the web approval dialog appears.
- The results include a CONCEPTS BRIEF labeled with lens names.

### V4. Handling a missing verdict line

**Task:** Temporarily change the instruction in the last line of the Output section of `.github/agents/goldfish-general-critic.agent.md` to `Last line: write "done".` Then run V3 again. **Restore the original when done.**

**Pass criteria:**
- elephant **calls critic once more**.
- If the verdict line is still missing after the retry, the original response is shown and the user is asked what to do.
- Treating it as PASS and continuing is a **failure**.

## Results Log

Record one of `Pass`, `Fail`, `Partial`, or `Unverified`, with brief evidence.

| ID | Local | Copilot |
|---|---|---|
| Date / Model | | |
| V0 Setup and visibility | | |
| V5 Blocking automatic invocation | | |
| V1 Command execution and eg-setup | | |
| V3 Inheritance merge | | |
| V7 Full new-feature flow | | |
| V2 Diff file review | | |
| V8b fix-bug compare | | |
| V6 Parallel calls and web approval | | |
| V4 Missing verdict line | | |
| V8 install.sh | Pass (2026-10-31, 5 script test scenarios) | N/A (unrelated to the harness) |
