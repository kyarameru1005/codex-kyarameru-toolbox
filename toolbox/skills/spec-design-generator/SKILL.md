---
name: spec-design-generator
description: spec plan Phase 7 で Agent サブエージェントから使用。requirements.md + コードベース調査結果から design.md を自律生成する。
user-invocable: false
---

# spec-design-generator

spec plan の Phase 7 (design.md 生成) 専用スキル。Agent(general-purpose) サブエージェントとして呼び出される。

## 使用方法

spec オーケストレーターが以下のように呼び出す:

```
Agent(subagent_type="general-purpose", prompt="""
~/.claude/skills/spec-design-generator/CLAUDE.md を読んで指示に従え。

入力:
- specs/features/{issue}-{feature}/requirements.md
- コードベース調査結果: {explore_results}

出力:
- specs/features/{issue}-{feature}/design.md
- specs/features/{issue}-{feature}/adr.md (Type 1 決定時)
""")
```
