# Analyze ルール - 実験結果分析フレームワーク

## 分析プロセス

### Step 1: データ収集

実験結果のデータを収集:
- テスト実行結果（pass/fail/coverage）
- パフォーマンス計測（spec-verify-frontend/backend の結果）
- ユーザーメトリクス（Analytics API, 設定がある場合）
- コード品質メトリクス（lint, 型チェック, 複雑度）

### Step 2: Before/After 比較

必ず Before/After を定量的に比較:

```markdown
| メトリクス | Before | After | 変化 | 判定 |
|----------|--------|-------|------|------|
| テスト数 | 42 | 48 | +6 | ✅ |
| カバレッジ | 76% | 82% | +6% | ✅ |
| ビルド時間 | 12s | 13s | +1s | ⚠️ |
| バンドルサイズ | 245KB | 248KB | +3KB | ✅ |
```

### Step 3: 統計的有意性（ユーザーデータがある場合）

`math-proof` スキルを使って検証:

| サンプルサイズ | 判定 |
|-------------|------|
| N < 30 | `[INSUFFICIENT_DATA]` - 判断保留 |
| 30 ≤ N < 100 | 効果量が大きい場合のみ判断可能 |
| N ≥ 100 | 通常の統計検定が適用可能 |

検定方法:
- 比率の差: カイ二乗検定 or Fisher's exact test
- 平均値の差: t検定 or Mann-Whitney U
- p < 0.05 で有意と判断

### Step 4: 副作用チェック

改善したメトリクス以外に悪化がないか:
- パフォーマンス（レスポンスタイム, バンドルサイズ）
- アクセシビリティ（axe-core スコア）
- セキュリティ（新たな脆弱性の導入）
- テストカバレッジ（低下していないか）

### Step 5: Confidence スコア算出

| 要素 | 重み | 基準 |
|------|------|------|
| 統計的有意性 | 0.3 | p < 0.05 → 1.0, p < 0.1 → 0.5, else → 0.2 |
| 副作用なし | 0.2 | 副作用なし → 1.0, 軽微 → 0.5, あり → 0.0 |
| テスト全パス | 0.2 | 全パス → 1.0, 新テストのみ失敗 → 0.5, 既存失敗 → 0.0 |
| 効果量 | 0.2 | 大 → 1.0, 中 → 0.7, 小 → 0.3 |
| コード品質 | 0.1 | 改善 → 1.0, 維持 → 0.7, 悪化 → 0.3 |

**Confidence = Σ(要素 × 重み)**

### Step 6: 学びの抽出

実験から得られた知見を構造化:
- **仮説は正しかったか**: Yes/No/Partial
- **予想外の発見**: あれば記述
- **次に試すべきこと**: 派生仮説
- **今後避けるべきこと**: 失敗パターン

## 出力フォーマット

```markdown
# Analysis: {experiment-name}
Date: {date}

## サマリ
- 仮説: {hypothesis}
- 結果: {confirmed/rejected/inconclusive}
- Confidence: {score} ({high/medium/low})
- 推奨: {merge/continue/reject}

## Before/After 比較
| メトリクス | Before | After | 変化 |
|----------|--------|-------|------|
| ... | ... | ... | ... |

## 統計分析（該当する場合）
- サンプルサイズ: N = {n}
- 効果量: d = {d}
- p値: p = {p}
- 判定: {significant/not_significant/insufficient_data}

## 副作用チェック
- パフォーマンス: {OK/WARNING/ISSUE}
- アクセシビリティ: {OK/WARNING/ISSUE}
- セキュリティ: {OK/WARNING/ISSUE}

## Confidence スコア内訳
| 要素 | スコア | 重み | 寄与 |
|------|--------|------|------|
| ... | ... | ... | ... |
| **合計** | | | **{total}** |

## 学び
- 仮説正否: {yes/no/partial}
- 予想外の発見: {findings}
- 次に試すべき: {next_hypotheses}
- 避けるべき: {anti_patterns}
```
