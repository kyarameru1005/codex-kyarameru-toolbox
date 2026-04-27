# Inception Phase Rules

## 目的

プロジェクトのビジョン・戦略を固める。Inception Deck + Lean Canvas で「何を作るか」「何を作らないか」を合意。

## 参照必須

- `~/.claude/skills/senior-architect/references/agile-architecture.md`（Inception Deck, Lean Canvas）
- `~/.claude/skills/senior-architect/references/decision-checklist.md`（要件確認チェックリスト）

## 成功条件

- Elevator Pitch が1文で書けている
- NOT List で「作らないもの」が3つ以上定義されている
- Trade-off Sliders で4制約のランクが確定している（同順位なし）
- Lean Canvas の Problem / Customer Segments / UVP が記入済み
- Key Metrics（成功指標）が定量的に定義されている

## 停止条件

| 条件 | 対応 |
|------|------|
| プロジェクト目的が不明確 | 追加ヒアリング提案 |
| NOT List が空（スコープ未定義） | 停止、ユーザー確認 |
| Trade-off Sliders で全て同ランク | 停止、優先順位決定を依頼 |

## 遷移条件 → discovery

- Elevator Pitch が完成
- NOT List に In Scope / Out of Scope が各1つ以上
- Trade-off Sliders が確定
- Lean Canvas の Problem / UVP が記入済み

## Good/Bad パターン

```markdown
Bad:
  - Elevator Pitch: 「便利なツール」
  - NOT List: 空
  - Trade-off: 「全部大事」

Good:
  - Elevator Pitch: 「リモートチーム向けのTaskFlowは、プロジェクト管理ツールです。非同期コミュニケーション統合があり、Trelloとは違い、チャットからワンクリックでタスク化できます。」
  - NOT List: Out of Scope: 「モバイルアプリ」「多言語対応」「課金機能」
  - Trade-off: Time=1, Budget=2, Scope=3, Quality=4
```

## チェックリスト

- [ ] Why Are We Here が1-3文で明確
- [ ] Elevator Pitch が定型文で完成
- [ ] Product Box の売り文句が3つ
- [ ] NOT List に Out of Scope が3つ以上
- [ ] Neighbors（関係者）がリストアップ済み
- [ ] Trade-off Sliders が1-4で確定
- [ ] Lean Canvas の Problem / Customer / UVP が記入済み
- [ ] Key Metrics が定量的
