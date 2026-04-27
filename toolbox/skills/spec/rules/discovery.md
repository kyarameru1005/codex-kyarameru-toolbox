# Discovery Phase Rules

## 目的

技術・リスク面の調査。アーキテクチャ概要、Sprint 0 決定事項、Pre-mortem によるリスク洗い出し。

## 参照必須

- `~/.claude/skills/senior-architect/references/agile-architecture.md`（Type 1/2, Walking Skeleton, Sprint 0, Pre-mortem）
- `~/.claude/skills/senior-architect/references/tech-stack-guide.md`（技術選定時）
- `~/.claude/skills/senior-architect/references/decision-checklist.md`（要件確認、技術選定チェックリスト）

## 成功条件

- Show the Solution（アーキテクチャ概要図）が描かれている
- 技術選定テーブルに主要レイヤーが記入済み（言語/FW/DB/インフラ/認証）
- 各技術選定に Type 1/Type 2 判定がある
- Pre-mortem で高リスク項目が3つ以上洗い出されている
- Sprint 0 決定事項の必須項目が埋まっている
- 非機能要件の方向性が定量的に確認済み

## 停止条件

| 条件 | 対応 |
|------|------|
| Type 1 決定で選択肢が2つ以上あり未決 | 停止、ユーザー確認。ADR 作成推奨 |
| 技術的実現可能性に重大な疑問 | 停止、PoC/Spike 提案 |
| 非機能要件が定量化できない | 停止、ベンチマーク調査提案 |

## 遷移条件 → roadmap

- アーキテクチャ概要図が完成
- Type 1 決定がリストアップされ、方針が確定（または ADR 作成済み）
- Pre-mortem のリスク軽減策が高リスク項目に対して定義済み
- Sprint 0 必須項目が確定

## Good/Bad パターン

```markdown
Bad:
  - 技術選定: 「React（流行っているから）」
  - リスク: 「特になし」
  - 非機能要件: 「速くする」

Good:
  - 技術選定: 「Next.js（SSR必要、チームに経験者あり、Type 2 決定）」
  - リスク: 「Supabase のリアルタイム機能が負荷に耐えるか不明（技術リスク・高・PoC で検証）」
  - 非機能要件: 「p95 < 200ms、同時接続 500、SLA 99.5%」
```

## チェックリスト

- [ ] アーキテクチャ概要図が描かれている
- [ ] 技術選定に Type 1/2 判定がある
- [ ] Type 1 決定の選択肢・推奨・根拠が記載
- [ ] Pre-mortem で高リスク項目 3つ以上
- [ ] 高リスク項目に軽減策あり
- [ ] Sprint 0 必須項目（言語/FW/DB/インフラ/認証/CI/規約）が確定
- [ ] 非機能要件が定量的
