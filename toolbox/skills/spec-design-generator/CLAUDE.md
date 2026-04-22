# spec-design-generator ルール

## 目的

requirements.md + コードベース調査結果から、実装可能なレベルの design.md を自律生成する。

## 実行手順

### 1. 入力読み込み

以下を全て読む:
- `specs/features/{feature_dir}/requirements.md` — UC + 受入条件 + NFR
- コードベース調査結果（プロンプトに含まれる or Explore で追加調査）
- `~/.claude/skills/spec/rules/design.md` — 設計ルール
- `~/.claude/skills/spec/templates/design.md` — テンプレート

### 2. 参照すべき知識

以下の参照ファイルを必要に応じて読む:
- `~/.claude/skills/senior-architect/references/design-principles.md` — SOLID, DRY, KISS, YAGNI
- `~/.claude/skills/senior-architect/references/architecture-patterns.md` — Monolith/Modular/Microservices 選定
- `~/.claude/skills/senior-architect/references/tech-stack-guide.md` — 2025-2026 技術ベンチマーク
- `~/.claude/skills/senior-architect/references/documentation-guide.md` — C4 Model, ADR フォーマット
- `~/.claude/skills/spec/templates/diagram-guidelines.md` — 図の種類・ツール選択

### 3. 設計書生成

`specs/features/{feature_dir}/design.md` のテンプレートを以下の順序で埋める:

#### §1. 概要
- 目的とスコープを requirements.md から抽出

#### §2. アーキテクチャ（C4 Model）
- **2.1 Context (Level 1)**: PlantUML with C4 stdlib — システム境界と外部アクター
- **2.2 Container (Level 2)**: PlantUML with C4 stdlib — コンテナ構成
- **2.3 Component (Level 3)**: Mermaid Flowchart — コンポーネント設計
- **2.4 ER 図**: Mermaid — エンティティ関連

#### §3. データベーススキーマ
- CREATE TABLE + カラム説明表 + インデックス設計

#### §4. API 仕様
- 各エンドポイント: メソッド、パス、リクエスト/レスポンス、エラーコード

#### §5. セキュリティ設計
- 認証・認可方式、データ保護、入力検証、監査ログ

#### §6. 設計決定
- Type 1（不可逆）決定 → **ADR 作成必須**
- Type 2（可逆）決定 → design.md 内に記録
- 各決定の選択肢と選定理由

#### §7. テスト戦略
- テスト可能性の考慮、テストケース概要

#### §8. 実装戦略
- ファイル構成（ディレクトリツリー）
- 依存ライブラリ（バージョン付き）

#### §9. 関連ドキュメント

### 4. ADR 生成（Type 1 決定時）

Type 1 決定がある場合、`~/.claude/skills/spec/templates/adr.md` を使って ADR を作成:
- Status: Proposed
- Context → Decision → Alternatives → Consequences → Risks

### 5. 品質ゲート

生成後に検証を実行:
```bash
bash ~/.claude/skills/spec/scripts/verify-artifact.sh "specs/features/{feature_dir}" "design.md" 800
```

**検証失敗時**: 内容を補完して再書き出し → 再検証。パスするまでループ。

### 6. 既存コードとの整合性

- 既存のレイヤー構造・命名規則・ディレクトリ構成に合わせる
- 既存パターンと矛盾する設計をしない
- 不明点は `WebSearch` / `WebFetch` で調査してから決定

## 停止条件（メインオーケストレーターに返す）

| 条件 | 対応 |
|------|------|
| セキュリティ設計が定義不可 | 停止、結果を返す |
| 既存アーキテクチャと非互換 | 停止、影響範囲を報告 |
| Type 1 決定が 3 つ以上 | 停止、分割を提案 |
| 要件不足で設計不可 | 停止、不足項目をリスト |

## 出力

サブエージェント終了時に以下を報告:
- 生成したファイル一覧
- Type 1 決定の有無と ADR 作成有無
- 停止条件に該当した場合はその内容
- verify-artifact.sh の結果
