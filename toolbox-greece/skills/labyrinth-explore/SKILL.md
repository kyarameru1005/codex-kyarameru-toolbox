---
name: labyrinth-explore
description: Use when the codebase, dependency flow, or impact area is unclear and you need structured exploration before design or implementation. Best for finding relevant files, entry points, and change boundaries.
---

# labyrinth-explore

Use this skill before editing when the correct files or flow are not yet clear.

## Focus

- entry points and call flow
- related files and ownership boundaries
- dependencies, config, and side effects
- direct and indirect impact of a change

## Workflow

1. Start from the user's target behavior or file.
2. Find the smallest relevant set of files.
3. Trace flow only as far as needed.
4. Separate confirmed facts from inference.

## Output

- short summary of the relevant area
- list of key files with reasons
- impact notes and likely risks before implementation
