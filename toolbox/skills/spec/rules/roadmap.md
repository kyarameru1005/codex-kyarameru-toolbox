# Roadmap Phase Rules

## 目的

inception.md + discovery.md の結果をもとに、Impact Mapping で機能を論理的に導出し、マイルストーン形式の ROADMAP を策定。各機能に `/spec plan` で使用する feature スラッグを付与。

## 参照必須

- `~/.claude/skills/senior-architect/references/agile-architecture.md`（Impact Mapping）

## 成功条件

- Impact Map（Goal → Actors → Impacts → Deliverables）が作成されている
- Goal が SMART（具体的・測定可能・達成可能・関連性・期限）
- 各 Deliverable が Impact に紐づいている（論拠がある）
- v0.1（MVP）に Must 機能がすべて含まれる
- 各機能に一意の feature スラッグが付与されている
- Trade-off Sliders が inception.md から転記されている
- リスクサマリが discovery.md から転記されている
- specs/ROADMAP.md が作成されている
- specs/00_CONTEXT.md が更新されている（存在する場合）

## 停止条件

| 条件 | 対応 |
|------|------|
| inception.md / discovery.md の情報が不十分 | 停止、前フェーズ再実行 |
| Must 機能間に矛盾がある | 停止、ユーザー確認 |
| Impact Map の Goal が SMART でない | 停止、Goal 再定義 |
| 技術的に実現困難な機能が含まれる | 停止、調査・代替案提示 |

## 遷移条件 → 承認 → 個別 /spec plan

- ROADMAP.md が作成済み
- ユーザーが ROADMAP を承認
- v0.1 機能リストが確定

## feature スラッグ命名規則

- kebab-case（例: `user-auth`, `task-management`）
- プロジェクト内で一意
- 機能を端的に表す（2-3 単語）

## Good/Bad パターン

```markdown
Bad:
  - Impact Map なし、機能リストだけ
  - v0.1: 機能A〜E（全部入り、論拠なし）
  - feature名: 「func1」「func2」

Good:
  - Impact Map: Goal(MAU 1000人) → 新規ユーザー → 簡単に始められる → social-login
  - v0.1 (MVP): social-login, task-crud（Must のみ、Impact 紐付きあり）
  - v0.2: team-invite, notification（Should）
  - feature名: 「social-login」「task-crud」「team-invite」
```

## チェックリスト

- [ ] Impact Map の Goal が SMART
- [ ] 各 Deliverable が Impact に紐づいている
- [ ] v0.1 に Must 機能がすべて含まれる
- [ ] v0.1 に Should/Could 機能が混入していない
- [ ] 各機能に feature スラッグが付与されている
- [ ] feature スラッグが kebab-case で一意
- [ ] Trade-off Sliders が転記されている
- [ ] リスクサマリが転記されている
- [ ] マイルストーン間の依存関係が考慮されている
- [ ] specs/ROADMAP.md が作成されている
- [ ] specs/00_CONTEXT.md が更新されている
