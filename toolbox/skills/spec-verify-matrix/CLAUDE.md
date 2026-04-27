# Verification Matrix Generator ルール

## 生成手順

### Step 1: 入力分析

以下のファイルを読み込み、検証対象を抽出する:

1. `requirements.md` → ユースケース、受入条件、非機能要件
2. `design.md` → API エンドポイント、データモデル、コンポーネント構成
3. `test-spec.md` → 既存テストケース（重複回避用）
4. `specs/templates/config.yaml` → project_type 判定

### Step 2: 共通ヒューリスティクス適用

`heuristics/` 配下のファイルを参照し、各機能・入力・API に体系的に当てはめる:

1. **sfdipot.md** の7軸を各機能に適用
2. **data-attacks.md** のパターンを全入力フィールドに適用
3. **operations.md** の操作ヒューリスティクスを適用

### Step 3: 専用ヒューリスティクス適用

project_type に応じて追加:

- **frontend / fullstack**: `ui-heuristics.md` を適用
- **backend / fullstack**: `api-heuristics.md` を適用
- **library / cli**: データ型攻撃 + 操作ヒューリスティクスのみ

### Step 4: verification-matrix.md 生成

以下の構造で出力:

```markdown
# Verification Matrix: {feature-name}
Generated: {date}
Project Type: {type}
Source: requirements.md + design.md

## 1. Function（機能検証）
### 正常系
- [ ] {ユースケースから導出}
### 異常系
- [ ] {受入条件の否定条件から導出}
### 境界値
- [ ] {データモデルの制約から導出}

## 2. Data（データ攻撃）
- [ ] {data-attacks.md の各パターンを入力フィールドに適用}

## 3. Interface（インターフェース検証）
- [ ] {API エンドポイント × BINMEN/VADER}

## 4. Platform（環境検証）
- [ ] {project_type に応じた環境テスト}

## 5. Operations（運用条件）
- [ ] {同時接続、リソース枯渇、割り込み}

## 6. Time（時間関連）
- [ ] {タイムアウト、日付境界、長時間稼働}

## 7. Security（セキュリティ）
- [ ] {api-heuristics.md のセキュリティ項目}

## 8. Accessibility（アクセシビリティ）[Frontend のみ]
- [ ] {ui-heuristics.md のA11y項目}

## 9. Cross-Browser / Responsive [Frontend のみ]
- [ ] {ui-heuristics.md の環境項目}
```

### 重複回避ルール

- test-spec.md に既にカバーされているテストケースは `[COVERED]` マークを付ける
- verification-matrix.md は test-spec.md を**補完**するもの（代替ではない）
- ユニットテストでカバー済みの項目も含めるが、手動/実機検証が必要な項目に `[MANUAL]` マークを付ける

### 項目数の目安

| カテゴリ | 目安 |
|---------|------|
| Function（正常系） | ユースケース数 × 1-3 |
| Function（異常系） | ユースケース数 × 2-5 |
| Function（境界値） | 入力フィールド数 × 2-3 |
| Data攻撃 | 入力フィールド数 × 3-5 |
| Interface | エンドポイント数 × 4-6 |
| Operations | 3-8 |
| Time | 2-5 |
| Security | 5-15 |
| Accessibility | 8-15 (Frontend) |
| Cross-Browser | 3-8 (Frontend) |
