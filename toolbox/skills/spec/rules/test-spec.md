# test-spec フェーズルール

## 目的

requirements.md + design.md + arch-check.md から、実装前にテスト仕様書を作成する。
テストファースト開発（TDD）の基盤となるドキュメント。

## 必須

**testing-suite 系スキルを活用する**

以下のスキルを必要に応じて使用し、テスト計画の網羅性を高める:

| スキル | 用途 |
|--------|------|
| `testing-suite:generate-tests` | テストケースの体系的な生成 |
| `testing-suite:test-coverage` | カバレッジ分析と網羅性の確認 |
| `testing-suite:test-quality-analyzer` | テスト品質の評価と改善提案 |
| `testing-suite:e2e-setup` | E2E テスト計画の策定 |
| `testing-suite:setup-load-testing` | パフォーマンステスト計画（arch-check で指摘がある場合） |

## 入力ファイル

| ファイル | 必須 | 用途 |
|----------|------|------|
| requirements.md | 必須 | UC・受入条件からテストケース導出 |
| design.md | 必須 | API設計・ドメインモデルから分岐網羅導出 |
| arch-check.md | 必須 | パフォーマンス指摘・リスク項目のテスト化 |

## 出力

- `specs/features/<feature>/test-spec.md`

## 成功条件

1. `specs/features/<feature>/test-spec.md` が作成されている
2. requirements.md の全 UC に対応するテストケースが存在する
3. 各テストケースに以下が含まれる:
   - ID（TC-XXX 形式）
   - テストケース名（正常系/異常系/境界値を明示）
   - 入力値（具体的な値）
   - 期待値（具体的な値）
   - 種別（単体/統合/E2E）
   - 優先度（Must/Should/Could）
4. 分岐網羅表が含まれる
5. テストファイル構成が含まれる（design.md §8 の実装戦略から導出）
6. arch-check.md の指摘事項に対応するテストが存在する

## 停止条件

- requirements.md が存在しない → `blocked`
- design.md が存在しない → `blocked`
- UC 定義が見つからない → `blocked`

## テストケース導出ルール

### 正常系（Must）
- 各 UC の基本フロー（ハッピーパス）

### 異常系（Must）
- 各 UC の代替フロー・例外フロー
- バリデーションエラー
- 認証・認可エラー

### 境界値（Should）
- 数値: 最小値、最大値、最小値-1、最大値+1、0、負数
- 文字列: 空文字、最大長、最大長+1
- コレクション: 空、1件、上限
- 日付: 過去、現在、未来、境界日

### 分岐網羅（Should）
- design.md の条件分岐を網羅
- 各条件の True/False パスをカバー

### パフォーマンス・最適化テスト（arch-check 連動）
- arch-check.md でパフォーマンス指摘がある場合、対応するテストケースを追加
- DB アクセス回数の検証（N+1 チェック等）
- レスポンスタイム要件の検証

## 遷移条件 → tasks

- 全 UC に対応するテストケースが存在
- 分岐網羅表が完成
- テストファイル構成が確定
- arch-check 指摘事項のテスト化が完了

## Good パターン

- UC から機械的にテストケースを導出している
- 入力値と期待値が具体的（"有効なメールアドレス" ではなく "test@example.com"）
- 境界値テストが網羅的
- テストファイル構成が design.md の実装戦略と一致
- arch-check のパフォーマンス指摘がテストケースに反映されている

## Bad パターン

- テストケースが曖昧（"正しく動作する"）
- 正常系のみで異常系がない
- 境界値テストが欠落
- 実装の詳細に依存したテスト（ホワイトボックス過剰）
- arch-check の指摘を無視している
