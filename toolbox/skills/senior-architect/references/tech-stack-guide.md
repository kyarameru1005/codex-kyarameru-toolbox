# 技術スタック選定ガイド (2025-2026)

## Frontend Framework

### 比較表

| Framework | 性能 | エコシステム | 学習曲線 | 採用率 |
|-----------|------|--------------|----------|--------|
| React 19 | 良好 | 最大 | 中 | 44.7% |
| Vue 4 | 良好 | 大 | 低 | 17.6% |
| Svelte 5 | 最高 | 成長中 | 低 | 7.2% |
| Angular | 良好 | 大 | 高 | 18.2% |

### 選定基準

| 条件 | 推奨 |
|------|------|
| エンタープライズ、大規模チーム | React or Angular |
| 高速開発、小〜中規模 | Vue |
| 最高性能、バンドルサイズ重視 | Svelte |
| SSR/SSG、SEO重視 | Next.js (React) |

### 2025-2026 トレンド

- **Server Components**: React 19 で標準化、初期レンダリング 2.4s→0.8s
- **Svelte 5 Runes**: より効率的なリアクティビティ
- **収束傾向**: fine-grained reactivity, server-first rendering

---

## Backend Language/Framework

### 性能比較 (TechEmpower Round 23, 2025)

| 言語/Framework | 相対性能 | スループット |
|----------------|----------|--------------|
| Rust (Actix) | 19.1x | ~60,000 req/s |
| Go (Fiber) | 20.1x | ~40,000 req/s |
| Node.js (Express) | 4.7x | - |
| Python (Django) | 1.9x | - |

### 選定基準

| 条件 | 推奨 |
|------|------|
| 最高性能、メモリ効率 | Rust |
| クラウドネイティブ、並行処理 | Go |
| I/O重視、リアルタイム | Node.js |
| AI/ML、データパイプライン | Python |
| 既存Java資産活用 | Kotlin/Java |

### ハイブリッドスタック (2025トレンド)

- Python (オーケストレーション) + Rust (ホットパス)
- Go (API) + Rust (計算モジュール)

---

## Database

### 比較表

| DB | 種類 | 強み | 用途 |
|----|------|------|------|
| PostgreSQL | RDBMS | 汎用性、拡張性 | **デフォルト推奨** |
| MySQL | RDBMS | Web/CMS実績 | WordPress, LAMP |
| MongoDB | Document | スキーマ柔軟性 | カタログ、CMS |
| Redis | KV Store | 超低レイテンシ | キャッシュ、セッション |

### 選定基準

| 要件 | 推奨 |
|------|------|
| ACID必須、複雑なリレーション | PostgreSQL |
| 柔軟なスキーマ、高速開発 | MongoDB |
| 超高速アクセス、一時データ | Redis |
| 分析、OLAP | ClickHouse, BigQuery |

### Polyglot Persistence パターン

```
PostgreSQL: ユーザー、注文、取引
MongoDB: 商品カタログ、イベントログ
Redis: セッション、キャッシュ、レート制限
```

---

## Message Queue

### 比較表

| システム | スループット | レイテンシ | 管理 |
|----------|--------------|------------|------|
| Kafka | 10M+ msg/s | 2-5ms | 要運用 |
| RabbitMQ | 1M msg/s | 1-20ms | 要運用 |
| AWS SQS | 300K msg/s | 10-100ms | フルマネージド |

### 選定基準

| 条件 | 推奨 |
|------|------|
| 高スループット、イベントストリーミング | Kafka |
| 複雑なルーティング、RPC | RabbitMQ |
| フルマネージド、AWS統合 | SQS/SNS |

---

## API Design

### 比較表

| スタイル | 強み | 用途 |
|----------|------|------|
| REST | 互換性、標準化 | 公開API |
| GraphQL | 柔軟なクエリ | 複雑なUI |
| gRPC | 高性能、型安全 | マイクロサービス間 |
| tRPC | 型安全、DX | TypeScript monorepo |

### 選定基準

| 条件 | 推奨 |
|------|------|
| 公開API、多言語クライアント | REST |
| 複雑なUI、データ集約 | GraphQL |
| マイクロサービス間、低レイテンシ | gRPC |
| TypeScript全振り、内部API | tRPC |

---

## 認証/認可

### 2025 ベストプラクティス

| 方式 | 用途 |
|------|------|
| OAuth 2.0 + PKCE | Web/Mobile アプリ |
| Passkeys/WebAuthn | パスワードレス認証 |
| OIDC | SSO、ID連携 |
| Client Credentials | M2M通信 |

### 推奨アプローチ

- **IDaaS利用推奨**: Auth0, Cognito, Clerk
- 理由: セキュアな実装は複雑、専門知識必要
- 自前実装: 特別な理由がある場合のみ
