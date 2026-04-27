# クラウドプラットフォーム比較 (2025-2026)

## マーケットシェア (Q3 2025)

| Provider | シェア |
|----------|--------|
| AWS | 29% |
| Azure | 20% |
| GCP | 13% |
| その他 | 38% |

---

## AWS (Amazon Web Services)

### 強み
- 最大のサービス数 (250+)
- 最大のグローバルフットプリント (37リージョン, 115+ AZ)
- 成熟したエコシステム

### いつ選ぶか
- 幅広いサービスが必要
- グローバル展開が重要
- 特定サービス (Lambda, S3, DynamoDB) が必須

### 代表的サービス
- Compute: EC2, Lambda, ECS/EKS
- Database: RDS, DynamoDB, Aurora
- Storage: S3, EBS
- ML: SageMaker

---

## Azure

### 強み
- Microsoft製品との統合 (Office 365, AD)
- ハイブリッドクラウド (Azure Arc)
- エンタープライズ向け機能

### いつ選ぶか
- Microsoft製品を多用している
- ハイブリッドクラウドが必要
- Windows Server環境
- 既存MSライセンスで40%割引 (Hybrid Benefit)

### 代表的サービス
- Compute: Virtual Machines, Functions, AKS
- Database: SQL Database, Cosmos DB
- Integration: Logic Apps, Service Bus

---

## GCP (Google Cloud Platform)

### 強み
- AI/ML リーダー (Vertex AI, Gemini)
- Kubernetes オリジン (GKE)
- BigQuery (データ分析)

### いつ選ぶか
- AI/ML ワークロードが中心
- データ分析・BI が重要
- Kubernetes ネイティブな開発

### 代表的サービス
- Compute: Compute Engine, Cloud Run, GKE
- AI/ML: Vertex AI, Gemini API
- Data: BigQuery, Cloud Spanner

---

## 比較表

| 観点 | AWS | Azure | GCP |
|------|-----|-------|-----|
| サービス数 | 最多 | 多い | 中程度 |
| グローバルリージョン | 最多 | 多い | 成長中 |
| AI/ML | 良好 | 良好 | 最強 |
| Kubernetes | EKS | AKS | GKE (最成熟) |
| ハイブリッド | Outposts | Arc (最強) | Anthos |
| 従量課金 | 秒単位 | 秒単位 | 秒単位 |
| 長期割引 | 最大72% | 最大72% | 最大70% |

---

## マルチクラウド戦略

### 2025 現状
- **87%** の企業が複数クラウドを利用
- 理由: ベンダーロックイン回避、ベストオブブリード

### 考慮事項
- 運用複雑性の増加
- スキルセットの分散
- ネットワーク/データ転送コスト

### 推奨アプローチ
1. **プライマリクラウド** を決める
2. **特定ワークロード** のみ別クラウド
3. **抽象化レイヤー** (Terraform, K8s) を活用

---

## コスト最適化

### 共通戦略
| 戦略 | 削減率 |
|------|--------|
| Reserved/Committed Use | 最大72% |
| Spot/Preemptible | 60-90% |
| 適切なサイジング | 20-40% |
| 自動スケーリング | 変動 |

### 注意点
- データ転送料金（エグレス）は要注意
- 隠れたコスト: NAT Gateway, Load Balancer
- FinOps プラクティスの導入推奨

---

## EU/日本向け考慮事項

### データレジデンシー
- **AWS**: 東京、大阪リージョン / EU Sovereign Cloud (2026〜)
- **Azure**: 東日本、西日本 / EU Data Boundary
- **GCP**: 東京、大阪 / Sovereign Controls for Europe

### コンプライアンス
- GDPR, 個人情報保護法対応
- データの越境移転制限
- 監査ログ要件
