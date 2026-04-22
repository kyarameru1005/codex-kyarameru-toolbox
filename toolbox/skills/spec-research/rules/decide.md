# Decide ルール - 意思決定フレームワーク

## 自動判断ルール

### Confidence による分岐

| Confidence | アクション | 人間の関与 |
|-----------|----------|-----------|
| ≥ 0.8 | PR にマージ推奨ラベル追加 | 不要（ただし digest で報告） |
| 0.5 - 0.79 | decision-queue.json に追加 | 必要（Slack 通知） |
| < 0.5 | 棄却 or 継続実験 | 不要（journal に記録） |

### 強制人間判断（Confidence に関わらず）

以下の変更は **必ず** decision-queue に入れる:

| カテゴリ | 例 |
|---------|---|
| 価格・課金 | 料金体系変更、無料枠変更 |
| データスキーマ | DB マイグレーション、API breaking change |
| UX 大幅変更 | ナビゲーション構造変更、主要フロー変更 |
| セキュリティ | 認証フロー変更、権限モデル変更 |
| 外部連携 | サードパーティ API 追加・変更 |
| 法的影響 | プライバシーポリシー、利用規約に影響 |

### 自動棄却条件

| 条件 | 判定 |
|------|------|
| 既存テスト破壊（修正不可） | 即棄却 |
| セキュリティ脆弱性導入 | 即棄却 |
| パフォーマンス 20% 以上悪化 | 即棄却 |
| バンドルサイズ 50% 以上増加 | 即棄却 |

## decision-queue.json フォーマット

```json
[
  {
    "id": "DQ-2026-03-16-001",
    "created_at": "2026-03-16T03:00:00Z",
    "experiment": "onboarding-short-text",
    "type": "ux_change",
    "confidence": 0.72,
    "summary": "オンボーディング step3 のテキストを短縮。completion +12%",
    "options": [
      { "label": "merge", "description": "PR #45 をマージ" },
      { "label": "reject", "description": "変更を棄却" },
      { "label": "extend", "description": "1週間追加データ収集" }
    ],
    "evidence": "research/experiments/onboarding-short-text/analysis.md",
    "pr_url": "https://github.com/...",
    "status": "pending",
    "decided_at": null,
    "decided_by": null,
    "decision": null
  }
]
```

## 人間の判断処理

人間が decision-queue.json を処理するフロー:

1. `/spec research decide --review` で未決事項を表示
2. 各項目に対して `merge` / `reject` / `extend` を選択
3. 選択結果を decision-queue.json に記録
4. `merge` → PR マージ実行
5. `reject` → PR クローズ + journal 更新
6. `extend` → 実験継続フラグ設定

## Slack 通知フォーマット

```
🔬 AI Research Lab - Decision Required

実験: onboarding-short-text
結果: completion +12%
Confidence: 0.72

選択肢:
  ✅ merge - PR #45 をマージ
  ❌ reject - 変更を棄却
  ⏳ extend - 1週間追加データ収集

詳細: research/experiments/onboarding-short-text/analysis.md
```
