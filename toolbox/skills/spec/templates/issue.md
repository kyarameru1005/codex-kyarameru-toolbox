# {{FEATURE_NAME}}

**Issue**: #{{ISSUE_NUMBER}}
**種別**: {{ISSUE_TYPE}}
**ラベル**: {{ISSUE_LABELS}}
**優先度**: Must / Should / Could

---

## 背景 / Background

<!-- 機能が必要な背景・バグの状況を記述 -->

---

## 目的 / Goal

**ユーザーストーリー**:
> [役割]として、[機能]したい。なぜなら[価値/目的]だから。

---

## 受入条件 / Acceptance Criteria

| ID | 条件 | 優先度 |
|----|------|--------|
| ACC-{{ISSUE_NUMBER}}-001 | [受入条件1] | Must |
| ACC-{{ISSUE_NUMBER}}-002 | [受入条件2] | Should |
| ACC-{{ISSUE_NUMBER}}-003 | [受入条件3] | Could |

### 詳細（Given-When-Then）

**ACC-{{ISSUE_NUMBER}}-001**: [条件名]
```gherkin
Given [前提条件]
When [アクション]
Then [期待結果]
```

---

## スコープ / Scope

### In Scope（対象）
- 対象機能
- 対象コンポーネント

### Out of Scope（非対象）
- 今回対象外の事項

---

## 非機能要件 / NFR Summary

| カテゴリ | 要件 | 優先度 |
|----------|------|--------|
| 性能 | [要件] | Must/Should |
| セキュリティ | [要件] | Must/Should |

詳細: [requirements.md](./requirements.md) 参照

---

## リスク / Risks

| リスク | 影響度 | 軽減策 |
|--------|--------|--------|
| [リスク] | 高/中/低 | [軽減策] |

**Type 1 決定（不可逆）**:
- [ ] あり → ADR 作成済み: [ADR-xxx](./adr.md)
- [ ] なし

---

## 関連 / Related

| 項目 | 内容 |
|------|------|
| UC | {{UC_IDS}} |
| Requirements | [requirements.md](./requirements.md) |
| Design | [design.md](./design.md) |
| Tasks | [tasks.md](./tasks.md) |
| ブランチ | {{BRANCH_NAME}} |

---

## 工数見積 / Estimation

| Phase | 見積 |
|-------|------|
| 合計 | [サイズ] |

詳細: [tasks.md](./tasks.md) 参照
