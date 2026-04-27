# Feature Decomposition Rules

## 目的

Feature 分解。`/spec project` の Phase A で ROADMAP.md の機能リストを実装可能な Feature 単位に分解し、依存関係を DAG として定義する。

## 入力

- ROADMAP.md（機能リスト + マイルストーン）
- 00_CONTEXT.md（プロジェクト概要・技術スタック）
- 既存コードベース

## 出力

- ROADMAP.md の Feature 分解セクション更新（依存関係テーブル + DAG）

## Feature 粒度基準

| 基準 | 目安 | 判定 |
|------|------|------|
| コード量 | 200〜1000 行 | 推奨範囲 |
| PR サイズ | 1 Feature = 1 PR | 必須 |
| Phase 完結 | Phase 1〜7 で完結 | 必須 |
| レビュー時間 | 30分以内でレビュー可能 | 推奨 |

### 分割判定

- 1000 行超 → **必ず分割**（共有部分を独立 Feature に切り出す）
- 200 行未満 → 隣接 Feature との**統合を検討**
- Phase 1〜7 で完結しない → 設計を見直し、スコープを縮小

## 依存関係の判定基準

以下のいずれかに該当する場合、Feature 間に依存関係がある:

| 依存タイプ | 判定基準 | 例 |
|-----------|---------|-----|
| 共有 Entity | 同じドメインモデルを参照・変更 | User エンティティを認証と権限管理で共有 |
| API 呼び出し | Feature A の API を Feature B が呼び出す | 通知 Feature がユーザー API を呼び出す |
| DB テーブル共有 | 同じテーブルを読み書き | 注文と在庫が products テーブルを共有 |
| 型定義依存 | 共有型・インターフェースに依存 | 共通レスポンス型を複数 Feature で使用 |
| インフラ依存 | 共有インフラリソースに依存 | キャッシュ基盤を複数 Feature で使用 |

## 循環依存の検出と解決

### 検出

DAG 定義後にトポロジカルソートを実行。ソート不可能な場合、循環が存在する。

### 解決策

1. **共有部分を独立 Feature に切り出す** → 両方の Feature がその共有 Feature に依存する形に変更
2. **インターフェース分離** → 依存方向を一方向に統一（DIP 適用）
3. **Feature スコープ再定義** → 境界を引き直して循環を解消

```markdown
Bad:
  feature-a → feature-b → feature-a（循環）

Good:
  shared-models → feature-a
  shared-models → feature-b
```

## DAG 定義フォーマット

ROADMAP.md の依存関係テーブルに以下の形式で記載:

```markdown
## Feature 依存関係

| Feature | 依存先 | 推定規模 | Wave |
|---------|--------|---------|------|
| shared-models | - | S (200行) | 1 |
| user-auth | shared-models | M (500行) | 2 |
| task-crud | shared-models | M (600行) | 2 |
| notification | user-auth, task-crud | M (400行) | 3 |

### DAG

shared-models → user-auth → notification
shared-models → task-crud → notification
```

### 推定規模の目安

| サイズ | 行数 | 説明 |
|--------|------|------|
| XS | 〜200 行 | 型定義、設定ファイルのみ |
| S | 200〜400 行 | 単一モジュール |
| M | 400〜700 行 | 標準的な Feature |
| L | 700〜1000 行 | 大きめの Feature、分割検討 |

## Feature 命名規約

- **kebab-case**（例: `user-auth`, `task-crud`, `shared-models`）
- プロジェクト内で**一意**
- 機能を端的に表す（**2〜3 単語**）
- プレフィクスで種別を示す:
  - `shared-*`: 共有基盤（例: `shared-models`, `shared-utils`）
  - その他: 機能名をそのまま使用（例: `user-auth`, `notification`）

## バッチ確認フロー

Feature 数が **5 以上**の場合、以下のフローでまとめて確認する:

1. **クラスタリング**: 類似 Feature をドメイン別にグルーピング
2. **サマリ生成**: クラスタごとに Feature 一覧・依存関係・推定規模を要約
3. **まとめて Hearing**: クラスタ単位でユーザーに確認
   - 「この分割で問題ないか」
   - 「粒度は適切か（統合 or 分割すべきものはないか）」
   - 「依存関係の認識は正しいか」
4. **フィードバック反映**: 修正があれば DAG を更新

```markdown
Good バッチ確認:
  ## クラスタ 1: ユーザー管理（3 Features）
  - shared-models (XS) → user-auth (M) → user-profile (S)
  - この分割で進めてよいですか？

  ## クラスタ 2: タスク管理（4 Features）
  - task-crud (M) → task-assign (S) → task-search (S) → task-export (S)
  - task-search と task-export は統合すべきですか？
```

Feature 数が **4 以下**の場合は個別に確認して問題ない。

## 成功条件

- 全 Feature: 200〜1000 行の推定範囲内
- 全 Feature: Phase 1〜7 で完結
- 全 Feature: 1 PR サイズ
- 依存関係: DAG として定義（循環なし）
- Feature 命名: kebab-case で一意
- ROADMAP.md: 依存関係テーブルが更新済み

## 停止条件

| 条件 | 対応 |
|------|------|
| 循環依存が解消できない | 停止、設計見直しを提案 |
| 1000 行超の Feature が分割不可 | 停止、スコープ再検討 |
| 依存関係が不明確 | 停止、コードベース追加調査 |
| Feature 数が 15 以上 | 停止、マイルストーン分割を提案 |

## チェックリスト

- [ ] 全 Feature に kebab-case の一意な名前を付与
- [ ] 全 Feature の推定規模が 200〜1000 行
- [ ] 全 Feature が Phase 1〜7 で完結する設計
- [ ] 依存関係テーブルが ROADMAP.md に記載
- [ ] DAG にサイクルがない（トポロジカルソート可能）
- [ ] 共有部分が独立 Feature として切り出されている
- [ ] Wave が依存関係に基づいて割り当てられている
- [ ] Feature 数 5 以上の場合、バッチ確認を実施済み
