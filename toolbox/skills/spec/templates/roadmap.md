# {{PROJECT_NAME}} - ROADMAP

**作成日**: {{DATE}}
**ステータス**: Draft | Approved

---

## Elevator Pitch

<!-- inception.md から転記 -->

---

## Impact Map

<!-- Goal → Actors → Impacts → Deliverables で機能を論理的に導出 -->

```
Goal: {{ビジネスゴール（SMART）}}
├── {{Actor 1}}
│   ├── {{Impact 1}} → {{Deliverable A}}, {{Deliverable B}}
│   └── {{Impact 2}} → {{Deliverable C}}
└── {{Actor 2}}
    └── {{Impact 3}} → {{Deliverable D}}
```

---

## マイルストーン

### v0.1 - MVP（Must）

| # | 機能名 | feature スラッグ | Impact との紐付き | 概要 |
|---|--------|-----------------|------------------|------|
| 1 | | | | |

**リリース目標**:
**成功基準**:
**Walking Skeleton 範囲**: <!-- discovery.md の Sprint 0 から -->

---

### v0.2（Should）

| # | 機能名 | feature スラッグ | Impact との紐付き | 概要 |
|---|--------|-----------------|------------------|------|
| 1 | | | | |

**リリース目標**:

---

### v0.3+（Could）

| # | 機能名 | feature スラッグ | Impact との紐付き | 概要 |
|---|--------|-----------------|------------------|------|
| 1 | | | | |

---

## Trade-off Sliders

<!-- inception.md から転記 -->

| 制約 | ランク (1-4) | 備考 |
|------|-------------|------|
| Scope | | |
| Time | | |
| Budget | | |
| Quality | | |

---

## リスクサマリ

<!-- discovery.md の Pre-mortem から高リスク項目を転記 -->

| リスク | 発生確率 | 影響度 | 軽減策 |
|--------|---------|--------|--------|
| | | | |

---

## 次のアクション

承認後、v0.1 の各機能を `/spec plan {feature}` で個別に仕様策定:

```bash
# 例:
/spec plan {feature-1} "{機能1の要件}"
/spec plan {feature-2} "{機能2の要件}"
```
