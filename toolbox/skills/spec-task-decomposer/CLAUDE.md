# spec-task-decomposer ルール

## 目的

design.md + arch-check.md + test-spec.md から、実装フェーズで迷わない粒度にタスクを分解し、TDD に沿った実行順序の tasks.md を自律生成する。

## 実行手順

### 1. 入力読み込み

以下を全て読む:
- `specs/features/{feature_dir}/design.md` — 実装戦略、ファイル構成、API 設計
- `specs/features/{feature_dir}/arch-check.md` — 推奨アクション、最適化項目
- `specs/features/{feature_dir}/test-spec.md` — テストファイル構成、テストケース一覧
- `specs/features/{feature_dir}/requirements.md` — UC 一覧（タスクとの紐付け用）
- `~/.claude/skills/spec/rules/tasks.md` — タスクルール
- `~/.claude/skills/spec/templates/tasks.md` — テンプレート

### 2. タスク分解方式の選定

| 方式 | 条件 | Phase 構成 |
|------|------|-----------|
| **Walking Skeleton** | 不確実性が高い / 新規プロジェクト | Phase 0 + Phase 1-7 |
| **Layer-by-Layer** | 既存パターン確立済み | Phase 1-7 のみ |

### 3. Phase 構成（TDD 対応）

#### Phase 0: Walking Skeleton（任意）
- 最小限の E2E 実装（全レイヤーを薄く貫通）
- 方式判定で Walking Skeleton を選択した場合のみ

#### Phase 1: テストコード作成（RED）
- **test-spec.md のテストファイル構成から直接導出**
- 各テストファイルごとに 1 タスク（大きければ分割）
- 全テスト FAIL を確認するタスクを最後に配置

#### Phase 2: ドメイン層（GREEN）
- design.md §8 のファイル構成から Entity, Value Object, Domain Event を導出

#### Phase 3: サービス層（GREEN）
- Use Case / Application Service の実装

#### Phase 4: ハンドラ層（GREEN）
- API Handler / Controller の実装

#### Phase 5: その他実装（GREEN）
- インフラ層（Repository 実装、外部 API クライアント等）
- arch-check.md の必須アクション（パフォーマンス最適化等）

#### Phase 6: ドキュメント更新
- SSOT 更新（03_USE_CASES.md, 04_API.md 等）

#### Phase 7: 最終検証（REFACTOR）
- 全テスト通過確認
- arch-check の推奨アクション反映確認
- リファクタリング

### 4. タスク粒度

| サイズ | 目安 | 判定 |
|--------|------|------|
| XS | 〜30分 | 理想 |
| S | 〜1時間 | 推奨 |
| M | 〜2時間 | 許容 |
| L | 〜4時間 | 分割検討 |
| XL | 4時間〜 | **必ず分割** |

### 5. タスク記述フォーマット

```markdown
- [ ] TASK-{issue}-{連番}: {動詞}{目的語}（{サイズ}）
  - 目的: {何を達成するか}
  - 含める: {具体的な実装内容}
  - 含めない: {スコープ外}
  - _Requirements: {UC-XXX}_
  - _依存: {TASK-XXX}_
  - _コミット: feat:{issue}_Phase{N}_{サマリ}_
```

### 6. 依存関係チェック

- Mermaid で依存関係グラフを生成
- **循環依存がないことを確認**（検出したら設計見直しを報告）

### 7. リスクマーク

各タスクにリスクレベルを付与:
- ⚠️ Type 1 決定に関連
- 🔴 技術リスク（未経験技術、複雑なロジック）
- 🟡 外部依存（外部 API、サードパーティライブラリ）
- 🟢 低リスク

### 8. 品質ゲート

```bash
bash ~/.claude/skills/spec/scripts/verify-artifact.sh "specs/features/{feature_dir}" "tasks.md" 500
```

**検証失敗時**: 内容を補完して再書き出し → 再検証。パスするまでループ。

### 9. 自己チェック

- [ ] 全タスクに TASK-XXX-YYY 形式の ID あり
- [ ] 全タスクにサイズ（XS〜L）あり
- [ ] XL タスクなし
- [ ] 依存関係に循環なし
- [ ] Phase 1〜7 全てにタスクあり
- [ ] Phase 1 に test-spec.md 由来のテストタスクあり
- [ ] Phase 2-5 の各タスクにテスト実行が明記
- [ ] arch-check の必須アクションが対応タスクに含まれている
- [ ] 各タスクに requirements.md の UC への紐付けあり

## 停止条件（メインオーケストレーターに返す）

| 条件 | 対応 |
|------|------|
| XL タスクが分割不可 | blocked |
| 依存関係が循環 | blocked、設計見直し提案 |
| design.md に情報不足 | blocked、不足項目リスト |
| test-spec.md に情報不足 | blocked、不足項目リスト |

## 出力

サブエージェント終了時に以下を報告:
- Phase 別タスク数
- 総工数見積（XS〜L の合計）
- 依存関係に問題があれば報告
- arch-check 必須アクションの対応状況
- verify-artifact.sh の結果
