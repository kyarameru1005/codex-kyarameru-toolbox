---
name: gauntlet-verify
description: Use when validating changes through tests, checks, or structured verification. Best for deciding what to run, interpreting results, and identifying missing evidence before completion.
---

# gauntlet-verify

Use this skill after implementation or when the user asks what should be verified.

## Focus

- the smallest high-value checks
- separating passed, failed, and unverified items
- interpreting failures without overclaiming
- identifying missing evidence before sign-off

## Workflow

1. Identify the checks that match the change.
2. Run or inspect the most relevant evidence.
3. Summarize outcomes as pass, fail, or unverified.
4. Call out the next useful check if coverage is incomplete.

## Output

- verification target
- commands or evidence used
- result summary
- remaining gaps
