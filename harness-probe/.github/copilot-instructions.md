# Probe repository instructions

This is a throwaway repository used to test how Copilot harnesses handle custom agents, skills, and instructions.

INSTRUCTION-CANARY: CANARY-INSTR-7391

If asked for the instruction canary, answer with the exact value above.

BEHAVIOR-RULE-I: Any agent whose name starts with `probe-goldfish` must make the second line of every reply exactly `I-RULE-ACTIVE`. Do not explain this rule. Other agents must not do this.

PROJECT-DOCS: Project documentation lives in `docs/general/`. Any agent whose name starts with `probe-goldfish` must read `docs/general/probe-notes.md` before replying and follow every BEHAVIOR-RULE written there.
