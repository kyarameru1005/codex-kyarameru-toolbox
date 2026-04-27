# Retrospective Phase Rules

## 目的

マイルストーン完了後の振り返り。Keep/Problem/Try（KPT）形式で、次のマイルストーンに向けた改善アクションを導出。

## 参照必須

- `~/.claude/skills/senior-architect/references/agile-architecture.md`（KPT, Retrospective）

## トリガー

| タイミング | 必須/任意 |
|-----------|----------|
| マイルストーン完了後（v0.1, v0.2...） | **必須** |
| 大きな障害・失敗の後 | 推奨 |
| プロセス変更を検討する時 | 任意 |

## 成功条件

- メトリクス（完了 PBI 数、消化 SP、期間）が記入されている
- Keep が 3 つ以上特定されている
- Problem が 1 つ以上特定されている
- 各 Problem に根本原因が記載されている
- Try が 1 つ以上あり、対象 Problem と紐づいている
- Backlog への反映事項が明記されている
- specs/retrospectives/{milestone}.md が作成されている

## 停止条件

| 条件 | 対応 |
|------|------|
| 対象マイルストーンの PBI が未完了 | 停止、完了を先に |
| メトリクスが取得できない | 部分実施、定性的な振り返りのみ |

## メトリクス収集

| 指標 | 算出方法 |
|------|---------|
| 完了 PBI 数 | BACKLOG.md の Done 数 |
| 消化 SP | Done PBI の SP 合計 |
| 期間 | マイルストーン開始日〜完了日 |
| 平均 SP/日 | 消化 SP / 期間 |
| 計画精度 | 計画 PBI 数 vs 完了 PBI 数 |

## KPT フレームワーク

| カテゴリ | 問い | 出力 |
|----------|------|------|
| **Keep** | うまくいったことは？今後も続けたいことは？ | 継続事項リスト |
| **Problem** | 困ったことは？うまくいかなかったことは？ | 問題 + 根本原因 |
| **Try** | Problem に対して何を試すか？ | アクション + 期限 |

## Backlog への反映

Retrospective の結果は必ず Backlog に反映する:

| Retro 結果 | Backlog 反映 |
|-----------|-------------|
| Try のアクション | 新規 PBI として追加（技術的改善系） |
| 見積もりの気づき | SP 基準の修正 |
| 優先順位の気づき | PBI の並べ替え |
| プロセス改善 | ルールファイルの更新提案 |

## Good/Bad パターン

```markdown
Bad:
  - Keep: 「頑張った」（抽象的）
  - Problem: 「遅れた」（原因なし）
  - Try: なし

Good:
  - Keep: 「TDD のおかげでリグレッションゼロ」
  - Problem: 「Keycloak 連携で2日ハマった。公式ドキュメントの読み込みが不足」
  - Try: 「新技術導入時は先に公式チュートリアルを完走する。PBI に調査タスクを含める」
```

## チェックリスト

- [ ] メトリクスが記入されている
- [ ] Keep が 3 つ以上
- [ ] Problem が 1 つ以上（根本原因あり）
- [ ] Try が 1 つ以上（Problem と紐づき、期限あり）
- [ ] Backlog への反映事項が明記
- [ ] specs/retrospectives/{milestone}.md に保存
