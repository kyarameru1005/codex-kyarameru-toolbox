---
name: spec-task-decomposer
description: spec plan Phase 10 で Agent サブエージェントから使用。design + arch-check + test-spec から tasks.md を自律生成する。
user-invocable: false
---

# spec-task-decomposer

spec plan の Phase 10 (tasks.md 生成) 専用スキル。Agent(general-purpose) サブエージェントとして呼び出される。

## 使用方法

spec オーケストレーターが以下のように呼び出す:

```
Agent(subagent_type="general-purpose", prompt="""
~/.claude/skills/spec-task-decomposer/CLAUDE.md を読んで指示に従え。

入力:
- specs/features/{issue}-{feature}/design.md
- specs/features/{issue}-{feature}/arch-check.md
- specs/features/{issue}-{feature}/test-spec.md

出力:
- specs/features/{issue}-{feature}/tasks.md
""")
```
