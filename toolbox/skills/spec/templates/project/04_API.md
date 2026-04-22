# API設計規約 / API Design Guidelines

**最終更新日**: {{DATE}}

> **Note**: API仕様の詳細はOpenAPI (Swagger) で管理します。
> このドキュメントはOpenAPIでカバーできない共通規約を定義します。

---

## 1. OpenAPI仕様

| 項目 | 値 |
|:---|:---|
| 仕様ファイル | `docs/openapi.yaml` or `openapi.json` |
| バージョン | OpenAPI 3.0+ |
| ドキュメント | `/docs` or `/swagger` |

---

## 2. 共通規約 / Common Conventions

### 2.1 URL設計

```
/{api-version}/{resource-plural}
/{api-version}/{resource-plural}/{resource-id}
/{api-version}/{resource-plural}/{resource-id}/{sub-resource}
```

| 規約 | 例 |
|:---|:---|
| バージョンプレフィックス | `/v1/`, `/v2/` |
| リソース名は複数形 | `/users`, `/orders` |
| ケバブケース | `/user-profiles` |
| ネストは2階層まで | `/users/{id}/orders` |

### 2.2 HTTPメソッド

| メソッド | 用途 | 冪等性 |
|:---|:---|:---:|
| GET | 取得（一覧・詳細） | ○ |
| POST | 作成 | ✕ |
| PUT | 全体更新 | ○ |
| PATCH | 部分更新 | ○ |
| DELETE | 削除 | ○ |

### 2.3 ステータスコード

| コード | 用途 |
|:---|:---|
| 200 | 成功（GET, PUT, PATCH, DELETE） |
| 201 | 作成成功（POST） |
| 204 | 成功・レスポンスボディなし |
| 400 | リクエスト不正 |
| 401 | 認証エラー |
| 403 | 認可エラー |
| 404 | リソース未検出 |
| 409 | 競合（楽観的ロック失敗等） |
| 422 | バリデーションエラー |
| 500 | サーバーエラー |

---

## 3. レスポンス形式 / Response Format

### 3.1 成功レスポンス

```json
{
  "status": "success",
  "data": { ... }
}
```

### 3.2 一覧レスポンス（ページネーション）

```json
{
  "status": "success",
  "data": [ ... ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### 3.3 エラーレスポンス

```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": [
      { "field": "email", "message": "メール形式が不正です" }
    ]
  }
}
```

---

## 4. 認証・認可 / Authentication & Authorization

| 項目 | 方式 |
|:---|:---|
| 認証 | Bearer Token (JWT) / Cookie Session |
| ヘッダー | `Authorization: Bearer <token>` |
| リフレッシュ | `/auth/refresh` |

---

## 5. 命名規則 / Naming Conventions

| 対象 | 規則 | 例 |
|:---|:---|:---|
| URL | ケバブケース | `/user-profiles` |
| JSONフィールド | スネークケース | `user_id`, `created_at` |
| クエリパラメータ | スネークケース | `?page=1&per_page=20` |

---

## 6. OpenAPIで管理する項目

以下はOpenAPI仕様で詳細を管理：

- 各エンドポイントのリクエスト/レスポンス定義
- パスパラメータ、クエリパラメータの詳細
- スキーマ定義（モデル）
- 認証スコープ
- サンプルリクエスト/レスポンス

---

**更新履歴**:
- {{DATE}}: 初版作成
