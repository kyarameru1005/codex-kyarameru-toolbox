# /spec research スキル ルール

## コア原則: 既存スキルのオーケストレーション

このスキルは新規ロジックを実装しない。
既存の spec, paper-analysis, xlsx, mcp-worker 等を**組み合わせて**研究ループを回す。

## 必須: 計測基盤の前提

研究ループを開始する前に、プロジェクトに以下が存在することを確認:

| 前提条件 | 確認方法 |
|---------|---------|
| アナリティクス設定 | `specs/templates/config.yaml` に analytics セクション |
| イベントログ | アプリコード内にログ/イベント送信コード |
| メトリクス定義 | `research/metrics.md` or config.yaml |

**計測基盤がない場合**: `/spec research init` で最低限のセットアップを案内。

## フェーズ別ルール

### observe: データ収集時のルール

- **データソースは config.yaml で定義**されたものだけを使う
- 取得したデータは `research/observations.md` に**追記**（上書きしない）
- 前回の observations との差分を明示する
- 異常値（前週比 ±20% 以上）は `[ANOMALY]` マークを付ける

### hypothesize: 仮説生成時のルール

- `rules/hypothesize.md` のフレームワークに従う
- 各仮説に **ICE スコア**（Impact × Confidence × Ease, 各1-10）を付ける
- 仮説は `research/hypotheses.md` に追記
- 既に実験済みの仮説は `[TESTED]` マークを付ける
- 1回の実行で生成する仮説は最大 5 件

### experiment: 実験設計時のルール

- **実験 = /spec の feature として扱う**
  - `experiment.yaml` → `requirements.md` に変換
  - `/spec plan` で設計 → `/spec go` で実装
  - ブランチ名: `exp/{name}`（`feat/` ではなく `exp/`）
  - コミットメッセージ: `exp:{name}_Phase{N}_{summary}`
- 1回の実行で実施する実験は最大 1 件（最高 ICE スコアのもの）
- feature flag を使い、既存コードを壊さない

### analyze: 分析時のルール

- `rules/analyze.md` のフレームワークに従う
- 統計的有意性が判断できない場合は `[INSUFFICIENT_DATA]` マークを付ける
- Before/After 比較を必ず含める
- 分析結果を `research/experiments/{name}/analysis.md` に書き出し
- 結果を `research/experiment-journal.md` に追記

### decide: 意思決定時のルール

- `rules/decide.md` の閾値に従う
- confidence ≥ 0.8 → 自動承認候補（PR マージ推奨）
- 0.5 ≤ confidence < 0.8 → `decision-queue.json` に追加
- confidence < 0.5 → 実験継続 or 棄却
- **価格変更、UX の大幅変更、データスキーマ変更**は confidence に関わらず必ず人間判断

### digest: レポート生成時のルール

- `templates/morning-digest.md` のフォーマットに従う
- **30秒で読めるサマリ**を最上部に配置
- 判断が必要な項目を明確に分離
- `mcp-worker` で Slack 通知（設定がある場合）

## Experiment Journal 自動更新

全実験の完了時に `research/experiment-journal.md` に追記:

```markdown
## EXP-{date}-{seq}: {name}
- 仮説: {hypothesis}
- 根拠: {evidence}
- 変更内容: {changes}
- 影響ファイル: {files}
- 結果: {result}
- 学び: {learnings}
- ステータス: {status}
```

## Code Tour 自動生成

実験コードの PR 作成時に `research/experiments/{name}/code-tour.json` を自動生成:

```json
{
  "title": "実験: {name}",
  "description": "{1行説明}",
  "steps": [
    { "file": "path/to/file.ts", "line": 42, "description": "変更理由" }
  ]
}
```

## Weekly Architecture Review（/spec retro 拡張）

週次で自動チェック:
- 残存 feature flag のリスト
- 実験用分岐ロジックの棚卸し
- テストカバレッジの変動
- 未マージの実験 PR

## 停止条件

| 条件 | 対応 |
|------|------|
| 計測基盤がない | 停止、セットアップを案内 |
| データが統計的に不十分 | 分析スキップ、データ蓄積を待つ |
| 人間判断が必要な変更 | decision-queue に追加して停止 |
| セキュリティリスク | 即時停止 |

## 継続条件

- メトリクスに異常がない → observe のみ実行して終了
- 仮説が ICE < 3 しかない → スキップ
- 実験結果が有意でない → journal に記録して次の仮説へ
