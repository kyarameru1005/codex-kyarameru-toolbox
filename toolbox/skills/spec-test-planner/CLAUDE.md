# spec-test-planner ルール

## 目的

requirements.md + design.md + arch-check.md から、TDD の基盤となるテスト仕様書 (test-spec.md) を自律生成する。

## 実行手順

### 1. 入力読み込み

以下を全て読む:
- `specs/features/{feature_dir}/requirements.md` — UC + 受入条件
- `specs/features/{feature_dir}/design.md` — API 設計、ドメインモデル、分岐条件
- `specs/features/{feature_dir}/arch-check.md` — パフォーマンス指摘、技術リスク
- `~/.claude/skills/spec/rules/test-spec.md` — テスト仕様ルール
- `~/.claude/skills/spec/templates/test-spec.md` — テンプレート

### 2. テスト設計手法

以下の手法を組み合わせてテストケースを導出する:

#### UC ベース導出（Must）
1. requirements.md の各 UC を読む
2. 基本フロー → **正常系テストケース**
3. 代替フロー・例外フロー → **異常系テストケース**
4. バリデーションエラー、認証エラー → **異常系テストケース**

#### 境界値分析（Should）
- 数値: 最小値、最大値、最小値-1、最大値+1、0、負数
- 文字列: 空文字、最大長、最大長+1、特殊文字
- コレクション: 空、1件、上限、上限+1
- 日付: 過去、現在、未来、境界日

#### 分岐網羅（Should）
- design.md の条件分岐を全て抽出
- 各条件の True/False パスをカバー
- 複合条件は組み合わせを網羅

#### パフォーマンステスト（arch-check 連動）
- arch-check.md でパフォーマンス指摘がある場合:
  - DB アクセス回数の検証（N+1 チェック）
  - レスポンスタイム要件の検証
  - 同時アクセス数の検証

### 3. テストケース記述

各テストケースに以下を含める:

```markdown
| ID | テストケース | 入力 | 期待値 | 種別 | 優先度 |
|----|------------|------|--------|------|--------|
| TC-001 | ユーザー登録_正常系 | email: "test@example.com", password: "Str0ng!Pass" | 201 Created, ユーザーID返却 | 統合 | Must |
```

- **ID**: TC-XXX 形式（連番）
- **入力値**: 具体的な値（"有効なメール" ではなく "test@example.com"）
- **期待値**: 具体的な値（ステータスコード、レスポンス内容）
- **種別**: 単体 / 統合 / E2E
- **優先度**: Must / Should / Could

### 4. 分岐網羅表

```markdown
| 分岐点 | 条件 | True パス | False パス | TC |
|--------|------|-----------|-----------|-----|
| UserService.create | email が未登録 | 新規作成 | 409 Conflict | TC-001, TC-005 |
```

### 5. テストファイル構成

design.md §8（実装戦略）のファイル構成から導出:

```markdown
| テストファイル | 対象モジュール | TC ID |
|-------------|-------------|-------|
| tests/unit/user.test.ts | domain/user.ts | TC-001, TC-002 |
| tests/integration/user-api.test.ts | handler/user.ts | TC-010, TC-011 |
```

### 6. 品質ゲート

```bash
bash ~/.claude/skills/spec/scripts/verify-artifact.sh "specs/features/{feature_dir}" "test-spec.md" 300
```

**検証失敗時**: 内容を補完して再書き出し → 再検証。パスするまでループ。

### 7. 自己チェック

生成後に以下を確認:
- [ ] requirements.md の全 UC に対応する TC が存在するか
- [ ] 各 UC に正常系・異常系・境界値がそろっているか
- [ ] 入力値と期待値が具体的か（抽象表現がないか）
- [ ] 分岐網羅表が design.md の条件分岐を全てカバーしているか
- [ ] テストファイル構成が design.md の実装戦略と整合しているか
- [ ] arch-check の指摘事項に対応するテストがあるか

## 停止条件（メインオーケストレーターに返す）

| 条件 | 対応 |
|------|------|
| requirements.md が存在しない | blocked |
| design.md が存在しない | blocked |
| UC 定義が見つからない | blocked |

## 出力

サブエージェント終了時に以下を報告:
- 生成したテストケース数（正常系/異常系/境界値の内訳）
- カバーした UC の一覧
- arch-check 指摘への対応状況
- verify-artifact.sh の結果
