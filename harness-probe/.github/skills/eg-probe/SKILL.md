---
name: eg-probe
description: Probe skill. Reports how its argument arrived and reads a pack manifest.
argument-hint: "[pack-name] [free text]"
disable-model-invocation: true
---

This is a probe. Do not do anything beyond the steps below.

1. Report the raw text the user typed when invoking this skill, exactly as you received it, under the heading `RAW_ARGUMENT`. If you received nothing after the skill name, write `EMPTY`.
2. Take the first word of that text as the pack name. If there is none, use `pack-a`.
3. Read `packs/<pack name>.md` in the workspace. Report its `PACK-CANARY` value under `PACK_CANARY`, or `NOT_FOUND` if the file cannot be read.
4. Report which of these you can see right now, as a yes/no list: `agent` (subagent) tool, `edit` tool, `read` tool.
