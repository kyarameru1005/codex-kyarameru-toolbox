# Observe ルール - メトリクス収集・異常検知

## データ収集フレームワーク

### 必須メトリクス（全プロジェクト共通）

| カテゴリ | メトリクス | 取得元 |
|---------|----------|--------|
| 開発速度 | Issue close rate, PR merge time | GitHub API |
| 品質 | Bug報告数, テストカバレッジ | GitHub Issues, CI |
| エンゲージメント | Star/Fork推移, Contributor数 | GitHub API |

### オプションメトリクス（config.yaml で有効化）

| カテゴリ | メトリクス | 取得元 |
|---------|----------|--------|
| ユーザー行動 | DAU, MAU, セッション時間 | Analytics API |
| コンバージョン | 登録率, 購入率, 離脱率 | Analytics API |
| パフォーマンス | LCP, FID, CLS | Web Vitals |
| エラー | エラー率, クラッシュ率 | Error tracking |
| フィードバック | NPS, CSAT, レビュー | Survey/App Store |

## 異常検出ルール

### 自動検出

| 条件 | マーク | アクション |
|------|--------|----------|
| 前週比 ±20% 以上 | `[ANOMALY]` | hypothesize の入力に優先投入 |
| 前月比 ±50% 以上 | `[CRITICAL]` | 即座に digest で通知 |
| 3日連続で悪化トレンド | `[TREND]` | hypothesize の入力に投入 |
| 新規エラータイプ出現 | `[NEW_ERROR]` | Code Fix Agent に直接投入 |

### 出力フォーマット

```markdown
# Observations - {date}

## サマリ
- 前回観察: {prev_date}
- 異常検知: {count} 件
- 全体トレンド: {improving/stable/declining}

## メトリクス

### 開発速度
| メトリクス | 今週 | 前週 | 変化 | マーク |
|----------|------|------|------|--------|
| Issue close rate | 85% | 72% | +18% | |
| PR merge time | 2.3h | 4.1h | -44% | [ANOMALY] |

### ユーザー行動（設定がある場合）
...

## 異常詳細
### [ANOMALY] PR merge time -44%
- 原因候補: 小さいPRが増えた / レビュー速度向上
- 推奨: hypothesize で仮説化
```

## データ収集の注意

- API レートリミットに注意。GitHub は 5000 req/hr
- 大量データの取得は避ける。直近 7 日分で十分
- 認証情報はコードに含めない。環境変数 or mcp-worker 経由
- データ取得に失敗した場合は `[UNAVAILABLE]` マークを付けてスキップ
