# Backlog Phase Rules

## 目的

ROADMAP.md から Product Backlog を生成する。各アイテムに ID、Story Points、優先順位、依存関係を付与。

## 参照必須

- `~/.claude/skills/senior-architect/references/agile-architecture.md`（Product Backlog, Story Points）

## 成功条件

- ROADMAP.md の全機能が PBI（Product Backlog Item）として登録されている
- 各 PBI に一意の ID（PBI-NNN）が付与されている
- 各 PBI に Story Points（1/2/3/5/8/13）が付与されている
- v0.1 の PBI が優先順位順に並んでいる
- 依存関係が明示されている
- v0.1 の PBI が全て Ready ステータス
- specs/BACKLOG.md が作成されている

## 停止条件

| 条件 | 対応 |
|------|------|
| ROADMAP.md の機能定義が不十分 | 停止、ROADMAP 再確認 |
| Story Points が 13 超の PBI がある | 停止、分割を提案 |
| 循環依存がある | 停止、依存関係の整理 |

## Story Points 見積もり基準

| SP | 規模感 | 判断基準 |
|----|--------|---------|
| 1 | 数時間 | 不確実性なし、既知のパターン |
| 2 | 半日〜1日 | ほぼ既知、軽い調査のみ |
| 3 | 1〜2日 | 少し調査必要、設計判断あり |
| 5 | 2〜3日 | 不確実性あり、新技術要素 |
| 8 | 3〜5日 | 複雑、分割検討すべき |
| 13 | 1週間超 | 分割必須 |

## Good/Bad パターン

```markdown
Bad:
  - SP なし、全部「中くらい」
  - 優先順位なし、ROADMAP のまま
  - 依存関係の記載なし

Good:
  - PBI-001: user-auth (SP:5, Ready, 依存なし)
  - PBI-002: task-crud (SP:3, Ready, 依存: PBI-001)
  - PBI-003: team-invite (SP:8, Backlog, v0.2)
```

## チェックリスト

- [ ] ROADMAP.md の全機能が PBI として登録
- [ ] 各 PBI に一意の ID
- [ ] 各 PBI に Story Points（フィボナッチ）
- [ ] SP 13 超の PBI がない（分割済み）
- [ ] v0.1 の PBI が優先順位順
- [ ] 依存関係が明示
- [ ] バックログサマリが計算済み
