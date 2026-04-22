# テスト戦略 / Test Strategy

**最終更新日**: {{DATE}}

---

## 1. テストピラミッド / Test Pyramid

```
        /\
       /  \       E2E (少数・高コスト)
      /----\      ユーザーフロー全体の検証
     /      \
    /--------\    Integration (中程度)
   /          \   API・DB連携の検証
  /------------\
 /              \ Unit (多数・低コスト)
/----------------\ 関数・クラス単位の検証
```

| レベル | 割合目安 | 実行頻度 |
|:---|:---:|:---|
| Unit | 70% | 常時（pre-commit, CI） |
| Integration | 20% | CI |
| E2E | 10% | CI（main/developマージ時） |

---

## 2. テスト種別 / Test Types

### 2.1 ユニットテスト

| 項目 | 内容 |
|:---|:---|
| 対象 | 関数、クラス、モジュール |
| ツール | <!-- Jest, Vitest, pytest, go test 等 --> |
| 実行 | `task test:unit` or `npm run test:unit` |
| カバレッジ目標 | 80%以上 |

**テスト対象:**
- バリデーションロジック
- ビジネスロジック（サービス層）
- ユーティリティ関数
- 純粋関数

### 2.2 統合テスト

| 項目 | 内容 |
|:---|:---|
| 対象 | API、DB連携、外部サービス連携 |
| ツール | <!-- Supertest, httptest 等 --> |
| 実行 | `task test:integration` |
| 環境 | テスト用DB（Docker） |

**テスト対象:**
- APIエンドポイント
- DB CRUD操作
- 認証・認可フロー

### 2.3 E2Eテスト

| 項目 | 内容 |
|:---|:---|
| 対象 | ユーザーシナリオ全体 |
| ツール | <!-- Playwright, Cypress 等 --> |
| 実行 | `task test:e2e` |
| 環境 | ステージング相当 |

**テスト対象:**
- ユーザー登録〜ログインフロー
- 主要なビジネスフロー
- エラーシナリオ

---

## 3. テストディレクトリ構造 / Directory Structure

```
tests/
├── unit/               # ユニットテスト
│   ├── service/
│   ├── domain/
│   └── utils/
├── integration/        # 統合テスト
│   ├── api/
│   └── repository/
├── e2e/                # E2Eテスト
│   └── scenarios/
├── fixtures/           # テストデータ
├── helpers/            # テストヘルパー
└── setup.ts            # テストセットアップ
```

---

## 4. テスト命名規則 / Naming Conventions

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user when valid input is provided', () => {});
    it('should throw ValidationError when email is invalid', () => {});
    it('should throw ConflictError when email already exists', () => {});
  });
});
```

**形式:**
- `should {expected behavior} when {condition}`
- 日本語可: `正常系: ユーザーが作成されること`

---

## 5. テストデータ管理 / Test Data

### 5.1 フィクスチャ

```typescript
// tests/fixtures/users.ts
export const validUser = {
  email: 'test@example.com',
  name: 'Test User',
};

export const invalidUser = {
  email: 'invalid-email',
  name: '',
};
```

### 5.2 ファクトリ

```typescript
// tests/helpers/factories.ts
export const createUser = (overrides = {}) => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  ...overrides,
});
```

---

## 6. モック戦略 / Mocking Strategy

| 対象 | 方針 |
|:---|:---|
| 外部API | 常にモック |
| DB | Unit: モック, Integration: 実DB |
| 時刻 | 固定値を注入 |
| ランダム値 | シード固定 or モック |

---

## 7. CI/CD統合 / CI Integration

```yaml
# .github/workflows/test.yml (例)
test:
  steps:
    - run: task test:unit
    - run: task test:integration
    - run: task test:e2e  # mainマージ時のみ
```

| トリガー | 実行テスト |
|:---|:---|
| Push (feature/*) | Unit + Integration |
| PR | Unit + Integration |
| Merge to main | Unit + Integration + E2E |

---

## 8. カバレッジ / Coverage

| メトリクス | 目標 |
|:---|:---|
| Line Coverage | 80%以上 |
| Branch Coverage | 70%以上 |
| Function Coverage | 80%以上 |

**除外対象:**
- 生成コード
- 設定ファイル
- テストコード自体

---

## 9. テストコマンド / Commands

| コマンド | 説明 |
|:---|:---|
| `task test` | 全テスト実行 |
| `task test:unit` | ユニットテストのみ |
| `task test:integration` | 統合テストのみ |
| `task test:e2e` | E2Eテストのみ |
| `task test:coverage` | カバレッジレポート生成 |
| `task test:watch` | ウォッチモード |

---

**更新履歴**:
- {{DATE}}: 初版作成
