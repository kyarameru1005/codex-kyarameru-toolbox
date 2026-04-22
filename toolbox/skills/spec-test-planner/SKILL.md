---
name: spec-test-planner
description: spec plan Phase 9 で Agent サブエージェントから使用。requirements + design + arch-check から test-spec.md を自律生成する。
user-invocable: false
---

# spec-test-planner

spec plan の Phase 9 (test-spec.md 生成) 専用スキル。Agent(general-purpose) サブエージェントとして呼び出される。

## 使用方法

spec オーケストレーターが以下のように呼び出す:

```
Agent(subagent_type="general-purpose", prompt="""
~/.claude/skills/spec-test-planner/CLAUDE.md を読んで指示に従え。

入力:
- specs/features/{issue}-{feature}/requirements.md
- specs/features/{issue}-{feature}/design.md
- specs/features/{issue}-{feature}/arch-check.md

出力:
- specs/features/{issue}-{feature}/test-spec.md
""")
```
