# Wave Execution Rules

## 目的

Wave 実行。`/spec go-project` の Phase B で、ROADMAP.md の DAG に基づいて Feature Agent を並列起動し、イベント駆動で全 Feature を完了させる。

## 入力

- ROADMAP.md（Feature 依存関係テーブル + DAG）
- project-guidelines-summary（プロジェクト規約サマリ）
- 各 Feature の specs/（requirements.md, design.md, test-spec.md, tasks.md）
- project-state.json

## 出力

- 全 Feature の実装完了
- project-state.json の最終状態

## イベント駆動スケジューリング

Wave 完了を待たず、**依存解決済みの Feature を即起動**する:

```
Algorithm: Event-Driven Scheduling
1. DAG から依存なし Feature を抽出 → 即起動
2. Feature 完了通知を受信
3. project-state.json を更新
4. 新たに依存解決済みとなった Feature を抽出
5. 並列度上限以内なら即起動
6. 全 Feature 完了まで 2〜5 を繰り返す
```

### 並列度制御

| パラメータ | デフォルト | 説明 |
|-----------|-----------|------|
| max_parallel | 3 | 同時実行 Feature Agent の上限 |

- 実行中 Feature 数 >= max_parallel → キューに追加、完了待ち
- max_parallel はプロジェクト規模・マシンリソースに応じて調整可能

## Feature Agent 起動手順

### 1. Feature 初期化

```bash
bash ~/.claude/skills/spec/scripts/init-feature.sh <issue> <feature>
```

### 2. project-state.json 更新

Feature のステータスを `in_progress` に更新:

```json
{
  "features": {
    "user-auth": {
      "status": "in_progress",
      "started_at": "2024-01-01T00:00:00Z",
      "agent_id": null,
      "depends_on": ["shared-models"],
      "retry_count": 0
    }
  }
}
```

### 3. Agent 起動

```
Agent(isolation="worktree", run_in_background=true)
```

- **worktree 分離**: 各 Feature Agent は独立した worktree で作業
- **バックグラウンド実行**: PM Agent は完了通知を待ちつつ他の Feature を起動可能

## Feature Agent に渡すプロンプト構成

Feature Agent 起動時に以下の情報を渡す:

1. **project-guidelines-summary**: プロジェクト全体の規約・技術スタック
2. **Feature specs**: 当該 Feature の requirements.md, design.md, test-spec.md, tasks.md
3. **依存先 design.md**: 依存する Feature の design.md（API 仕様・型定義の参照用）
4. **実行指示**: `/spec go` を実行し、tasks.md に従って Phase 1〜7 を完了せよ

```markdown
プロンプト構成:
  ## プロジェクト規約
  {project-guidelines-summary の内容}

  ## Feature: {feature-name}
  {specs/ 配下の全成果物}

  ## 依存先 API 仕様
  {依存 Feature の design.md から API セクションを抽出}

  ## 指示
  `/spec go` を実行し、全 Phase を完了してください。
  完了後、ssot-updates.md に SSOT 更新差分を記載してください。
```

## 完了監視と次 Feature 起動

1. **バックグラウンド通知受信**: Feature Agent の完了通知を受け取る
2. **結果確認**: 成功 / 失敗を判定
3. **project-state.json 更新**: ステータスを `completed` or `failed` に変更
4. **Audit Agent 起動**: 完了した Feature に対して Audit を実行（→ audit.md ルール参照）
5. **次 Feature 起動判定**: 新たに依存解決済みとなった Feature があれば起動

## 失敗時のハンドリング

| リトライ回数 | 対応 |
|-------------|------|
| 1〜3 回目 | Feature Agent を再起動（前回のエラーログを渡す） |
| 3 回失敗 | エスカレーション（ユーザーに報告、手動介入を要求） |

### リトライ時の追加情報

```markdown
## 前回の失敗情報
- エラー内容: {error_message}
- 失敗した Phase: {phase}
- 失敗したタスク: {task_id}
- リトライ回数: {retry_count}/3

前回の失敗を踏まえて、別のアプローチで実装してください。
```

### project-state.json 状態遷移

```
pending → in_progress → completed
                      → failed → in_progress (retry)
                               → escalated (3回失敗)
```

| 状態 | 説明 |
|------|------|
| pending | 依存未解決 or キュー待ち |
| in_progress | Feature Agent 実行中 |
| completed | 実装 + Audit 完了 |
| failed | 実装失敗（リトライ対象） |
| escalated | 3 回失敗、手動介入待ち |

## Audit Agent 起動タイミング

**個別 Feature 完了ごと**に Audit Agent を起動する（→ audit.md ルール参照）:

- Feature Agent 完了 → 即座に Audit Agent を起動
- Audit FAIL → Feature Agent を修正指示付きで再起動
- Audit PASS → Feature を `completed` に確定

## Merge フロー

全 Feature 完了後（または Wave 単位で）、統合を実施:

1. **トポロジカルソート順** で Merge（依存先から順に）
2. コンフリクト解決戦略は integration.md ルールに従う
3. Merge 後の統合テスト実行

## Phase C 統合フロー

全 Feature が `completed` になった後:

1. **全テスト実行**: 統合ブランチで全テストスイートを実行
2. **SSOT 統合**: 各 Feature の ssot-updates.md を集約し、プロジェクトドキュメントを更新
3. **統合 PR 作成**: integration-pr.md テンプレートを使用
4. **worktree クリーンアップ**: 全 Feature の worktree を削除

## 成功条件

- 全 Feature: `completed` ステータス
- 全 Feature: Audit PASS
- 統合テスト: 全パス
- SSOT: 統合済み
- PR: 作成済み

## 停止条件

| 条件 | 対応 |
|------|------|
| Feature が 3 回失敗してエスカレーション | 停止、ユーザー確認 |
| 統合テストが修正不可能な失敗 | 停止、影響報告 |
| コンフリクトが semantic で自動解決不可 | 停止、PM 判断 or エスカレーション |

## チェックリスト

- [ ] project-state.json が初期化されている
- [ ] 全 Feature の依存関係が DAG として定義済み
- [ ] max_parallel が設定されている
- [ ] 依存なし Feature から起動されている
- [ ] 各 Feature Agent に必要な情報が渡されている
- [ ] 完了通知の監視ループが動作している
- [ ] 失敗時のリトライカウントが管理されている
- [ ] Audit が各 Feature 完了ごとに実行されている
- [ ] Merge がトポロジカルソート順で実行されている
- [ ] Phase C 統合フローが完了している
