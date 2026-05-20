---
name: aegis-review
description: Use when reviewing code or config changes for bugs, regressions, risky assumptions, maintainability issues, or defensive concerns. Best for post-implementation review, risk-focused reading, and concise findings.
---

# aegis-review

Use this skill after implementation or when the user asks for a review.

## Focus

- bugs and behavioral regressions
- risky assumptions and unclear edge cases
- maintainability and readability risks
- security-adjacent concerns worth escalating

## Workflow

1. Read the changed files and nearby context.
2. Prioritize real defects over style comments.
3. Report only meaningful findings.
4. If no findings exist, say so explicitly and note residual risk or missing verification.

## Output

- findings first, ordered by severity
- file references when possible
- short note on testing gaps or open questions
