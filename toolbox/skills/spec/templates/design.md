# {{FEATURE_NAME}} - 設計書

**基準文書**: `specs/features/{{FEATURE_SLUG}}/requirements.md`
**作成日**: {{DATE}}
**図ガイドライン**: [diagram-guidelines.md](./diagram-guidelines.md)

---

## 1. 概要

**目的**: [目的を記述]

**スコープ**:
- [スコープ1]
- [スコープ2]

---

## 2. アーキテクチャ（C4 Model）

<!--
図ツール選択:
- クラウドアイコンが必要 → PlantUML + stdlib（AWS/Azure/GCP）
- GitHub表示優先 → Mermaid
- 簡易構成 → ASCII
詳細: diagram-guidelines.md 参照
-->

### 2.1 Context（Level 1）- システム境界

<!-- PlantUML推奨: クラウドベンダーアイコン使用時 -->
```plantuml
@startuml Context
!include <C4/C4_Context>
' クラウドアイコン例: !include <awslib/AWSCommon>

Person(user, "ユーザー", "システム利用者")
System(system, "本システム", "この機能が影響する範囲")
System_Ext(ext_api, "外部API", "連携システム")
System_Ext(auth, "認証プロバイダ", "認証サービス")

Rel(user, system, "利用")
Rel(system, ext_api, "API連携")
Rel(system, auth, "認証")
@enduml
```

**外部連携**:
| 外部システム | 連携方式 | 目的 |
|--------------|----------|------|
| [システム名] | REST API | [目的] |

---

### 2.2 Container（Level 2）- コンテナ構成

<!-- クラウドベンダー別アイコン: diagram-guidelines.md §3 参照 -->
```plantuml
@startuml Container
!include <C4/C4_Container>
' AWS例: !include <awslib/Compute/Lambda>
' Azure例: !include <azure/Compute/AzureFunction>

System_Boundary(system, "本システム") {
  Container(frontend, "Frontend", "React/Next.js", "ユーザーインターフェース")
  Container(backend, "Backend", "Go/Node.js", "ビジネスロジック")
  ContainerDb(db, "Database", "PostgreSQL", "データ永続化")
  Container(cache, "Cache", "Redis", "セッション/キャッシュ")
}

Rel(frontend, backend, "API呼び出し", "HTTPS")
Rel(backend, db, "読み書き", "TCP")
Rel(backend, cache, "キャッシュ", "TCP")
@enduml
```

| コンテナ | 技術 | 責務 |
|----------|------|------|
| Frontend | [技術] | [責務] |
| Backend | [技術] | [責務] |
| Database | [技術] | [責務] |

---

### 2.3 Component（Level 3）- コンポーネント設計

**レイヤー構造**:

```mermaid
graph TD
    subgraph Presentation["Presentation Layer (Handler/Controller)"]
        P1["リクエスト/レスポンス処理"]
        P2["入力検証"]
    end
    subgraph Application["Application Layer (Service/UseCase)"]
        A1["ビジネスロジック"]
        A2["トランザクション制御"]
    end
    subgraph Domain["Domain Layer (Entity/Value Object)"]
        D1["ドメインモデル"]
        D2["ドメインルール"]
    end
    subgraph Infrastructure["Infrastructure Layer (Repository/Gateway)"]
        I1["データアクセス"]
        I2["外部システム連携"]
    end
    Presentation --> Application --> Domain --> Infrastructure
```

| レイヤー | ファイル | 責務 |
|----------|----------|------|
| Presentation | `[path]` | [責務] |
| Application | `[path]` | [責務] |
| Domain | `[path]` | [責務] |
| Infrastructure | `[path]` | [責務] |

---

### 2.4 ER 図

<!-- Mermaid推奨: GitHub対応、シンプルな記法 -->
```mermaid
erDiagram
    ENTITY_A ||--o{ ENTITY_B : "1:N"
    ENTITY_A {
        uuid id PK
        string name
        timestamp created_at
    }
    ENTITY_B {
        uuid id PK
        uuid entity_a_id FK
        string value
        timestamp created_at
    }
```

---

## 3. データベーススキーマ

### 3.1 [テーブル名]

```sql
CREATE TABLE xxx (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- カラム定義
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- インデックス
CREATE INDEX idx_xxx_yyy ON xxx(yyy);

-- 外部キー制約
ALTER TABLE xxx ADD CONSTRAINT fk_xxx_yyy
    FOREIGN KEY (yyy_id) REFERENCES yyy(id);
```

**カラム説明**:
| カラム | 型 | NULL | 説明 |
|--------|-----|------|------|
| id | UUID | NO | 主キー |
| ... | ... | ... | ... |

---

## 4. API 仕様

### 4.1 POST /api/v1/xxx

**概要**: [API の目的]

**認証**: 必要 / 不要

**リクエスト**:
```json
{
  "field": "value"
}
```

**レスポンス (201 Created)**:
```json
{
  "status": "success",
  "data": {
    "id": "..."
  }
}
```

**エラーレスポンス**:
| ステータス | エラーコード | 説明 |
|------------|--------------|------|
| 400 | INVALID_INPUT | 入力値不正 |
| 401 | UNAUTHORIZED | 認証エラー |
| 403 | FORBIDDEN | 権限エラー |
| 404 | NOT_FOUND | リソース未検出 |

---

## 5. セキュリティ設計

### 5.1 認証・認可

| 項目 | 設計 |
|------|------|
| 認証方式 | JWT / Session / OAuth 2.0 |
| 認可方式 | RBAC / ABAC |
| セッション管理 | [詳細] |

### 5.2 データ保護

| 項目 | 対応 |
|------|------|
| 転送中の暗号化 | TLS 1.3 |
| 保存時の暗号化 | AES-256 |
| 機密データ | [マスキング/ハッシュ化対象] |

### 5.3 入力検証

| 入力項目 | 検証内容 |
|----------|----------|
| [フィールド名] | [検証ルール] |

### 5.4 監査ログ

| イベント | ログ内容 |
|----------|----------|
| [イベント] | [記録項目] |

---

## 6. 設計決定（Type 1/Type 2）

### Type 1 決定（不可逆 - ADR 必須）

| 決定事項 | 選択 | 理由 | ADR |
|----------|------|------|-----|
| [決定事項] | [選択内容] | [理由] | [ADR-xxx](./adr.md) |

### Type 2 決定（可逆 - 変更容易）

| 決定事項 | 選択 | 理由 |
|----------|------|------|
| [決定事項] | [選択内容] | [理由] |

---

## 7. テスト戦略

### 7.1 テスト可能性の考慮

| レイヤー | テスト方法 | モック対象 |
|----------|------------|------------|
| Presentation | Integration Test | Service層 |
| Application | Unit Test | Repository |
| Domain | Unit Test | なし |
| Infrastructure | Integration Test | 実DB/外部API |

### 7.2 テストケース概要

| 観点 | テスト内容 |
|------|------------|
| 正常系 | [内容] |
| 異常系 | [内容] |
| 境界値 | [内容] |

---

## 8. 実装戦略

### 8.1 ファイル構成

```
[プロジェクトのディレクトリ構造]
```

### 8.2 依存関係

| ライブラリ | バージョン | 用途 |
|------------|------------|------|
| [名前] | [バージョン] | [用途] |

---

## 9. 関連ドキュメント

- [requirements.md](./requirements.md) - 要件定義書
- [arch-check.md](./arch-check.md) - アーキテクチャチェック
- [adr.md](./adr.md) - 設計決定記録
- [tasks.md](./tasks.md) - タスク一覧
- [diagram-guidelines.md](../diagram-guidelines.md) - 図の選択・生成ガイドライン
