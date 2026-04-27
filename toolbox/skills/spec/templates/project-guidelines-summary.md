# プロジェクトガイドライン（Feature Agent 用）

<!-- PM が SSOT から自動生成する軽量サマリ。Feature Agent のコンテキストに埋め込む -->

## 技術スタック

<!-- 00_CONTEXT.md から抜粋 -->

| 項目 | 選定 |
|------|------|
| 言語 | |
| フレームワーク | |
| DB | |
| テストFW | |
| CI/CD | |

## レイヤー構造

<!-- 05_ARCHITECTURE.md セクション2 から抜粋 -->

```
Presentation (Handler) → Application (Service) → Domain ← Infrastructure
```

- 依存の方向: 外側 → 内側（Domain は何にも依存しない）

## ディレクトリ構造

<!-- 05_ARCHITECTURE.md セクション3 から抜粋 -->

```
src/
├── domain/       # Entity, ValueObject, Repository interface
├── service/      # UseCase, Application Service
├── handler/      # HTTP Handler, Controller
├── infra/        # Repository impl, External API client
└── shared/       # 共通ユーティリティ
```

## API 設計方針

<!-- 04_API.md から抜粋 -->

| 項目 | 規約 |
|------|------|
| スタイル | |
| バージョニング | |
| レスポンス形式 | |
| エラー形式 | |
| 認証方式 | |

## 命名規則

<!-- 08_DEV_GUIDELINES.md セクション1 から抜粋 -->

| 対象 | 規約 | 例 |
|------|------|-----|
| ファイル名 | | |
| 変数名 | | |
| クラス/型名 | | |
| テストファイル | | |

## テストコマンド

<!-- config.yaml から抜粋 -->

```bash
# 全テスト実行
{{TEST_ALL_COMMAND}}

# lint
{{LINT_COMMAND}}

# 型チェック
{{TYPE_CHECK_COMMAND}}
```

## コミット規約

```
feat:{ISSUE}_Phase{N}_{サマリ}
```

## エラーハンドリング

<!-- 05_ARCHITECTURE.md セクション7 から抜粋 -->

| 項目 | 規約 |
|------|------|
| HTTPステータス | |
| エラーコード体系 | |
| ログレベル | |
