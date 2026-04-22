# Integration Rules

## 目的

Feature 統合。全 Feature の Audit 完了後、integration ブランチで Merge・統合テスト・SSOT 統合・PR 作成を実行する。

## 入力

- 全 Feature の worktree（Audit PASS 済み）
- ROADMAP.md（DAG + トポロジカルソート順）
- project-state.json（全 Feature `completed`）
- 各 Feature の ssot-updates.md

## 出力

- integration ブランチ（全 Feature を Merge 済み）
- 統合テスト結果
- SSOT 統合済みドキュメント
- 統合 PR

## integration ブランチの作成・管理

### ブランチ命名

```
integrate/{project-slug}/v{milestone}
```

例: `integrate/task-app/v0.1`

### 作成手順

1. main（またはベースブランチ）から integration ブランチを作成
2. 全 Feature を Merge 順序に従って Merge
3. Merge 完了後に統合テスト実行

### 管理ルール

- integration ブランチへの直接コミットは**禁止**（Merge のみ）
- コンフリクト解決コミットは例外として許可
- integration ブランチの force push は**禁止**

## Merge 順序

**トポロジカルソート順**で Merge する。依存先を先に Merge することで、コンフリクトを最小化する。

```markdown
例: DAG
  shared-models → user-auth → notification
  shared-models → task-crud → notification

Merge 順序:
  1. shared-models
  2. user-auth（shared-models に依存）
  3. task-crud（shared-models に依存）
  4. notification（user-auth, task-crud に依存）
```

### 同一 Wave 内の順序

依存関係がない Feature（同一 Wave）は任意の順序で Merge 可能。ただしアルファベット順を推奨（再現性のため）。

## コンフリクト解決戦略

| タイプ | 判定基準 | 対応 |
|--------|---------|------|
| trivial | import 追加、空行差異、フォーマット差異 | 自動解決 |
| additive | 同一ファイルへの異なる箇所への追加 | 自動解決（両方採用） |
| semantic | 同一箇所の異なるロジック変更 | PM 判断 or エスカレーション |
| structural | ファイル構造・ディレクトリ構成の衝突 | エスカレーション |

### 自動解決の手順

1. `git merge --no-ff feature/{feature-name}` を実行
2. コンフリクト発生時、diff を分析
3. trivial / additive → 自動解決してコミット
4. semantic / structural → PM Agent が判断、不可能ならエスカレーション

### エスカレーション時の情報

```markdown
## Merge コンフリクト報告
- Feature: {feature-name}
- ファイル: {conflicted-files}
- コンフリクトタイプ: {trivial/additive/semantic/structural}
- 影響範囲: {description}
- 提案: {resolution-proposal}（ある場合）
```

## Merge 後の統合テスト

各 Feature の Merge 後に段階的にテストを実行:

### 段階的テスト

| タイミング | テスト範囲 |
|-----------|-----------|
| Feature Merge 直後 | 当該 Feature のユニットテスト |
| Wave 完了時 | Wave 内全 Feature のテスト |
| 全 Merge 完了後 | 全テストスイート（ユニット + 統合 + E2E） |

### テスト失敗時

1. 失敗原因を特定（Feature 単体の問題 or Feature 間の統合問題）
2. Feature 単体の問題 → 当該 Feature の worktree で修正 → 再 Merge
3. 統合問題 → integration ブランチ上で修正コミット

## SSOT 統合

各 Feature の ssot-updates.md を集約し、プロジェクトの SSOT ドキュメントを更新する。

### 手順

1. 全 Feature の ssot-updates.md を収集
2. 変更内容をカテゴリ別に整理（API 追加、DB スキーマ変更、設定追加 等）
3. 対象ドキュメントに反映:
   - 00_CONTEXT.md（アーキテクチャ概要の更新）
   - ROADMAP.md（完了 Feature のステータス更新）
   - その他プロジェクト固有のドキュメント
4. 反映漏れがないか ssot-updates.md と突合

### コンフリクト時

複数 Feature が同じドキュメントの同じセクションを更新している場合:
- **追記系**: 両方を反映（順序はトポロジカルソート順）
- **修正系**: 最新の Feature（DAG で下流）を優先

## 統合 PR 作成

integration-pr.md テンプレートを使用して PR を作成する。

### PR 構成

```markdown
## Summary
- {project-name} v{milestone} の統合 PR
- {n} Features を統合

## Features
| Feature | Status | Audit |
|---------|--------|-------|
| shared-models | Merged | PASS |
| user-auth | Merged | PASS (WARN: カバレッジ 75%) |
| task-crud | Merged | PASS |

## Test Results
- Unit: {pass}/{total} passed
- Integration: {pass}/{total} passed
- E2E: {pass}/{total} passed

## SSOT Updates
- {変更サマリ}

## Breaking Changes
- {ある場合のみ}
```

### PR 作成手順

1. integration-pr.md を生成
2. ユーザーにプレビューを表示
3. **ユーザー承認後** `gh pr create` を実行

## worktree クリーンアップ

統合 PR が作成された後（またはユーザー指示で）:

1. 全 Feature の worktree を削除
2. ローカルの Feature ブランチを削除（Merge 済みのもの）
3. project-state.json を `integrated` に更新

```bash
# worktree 削除
git worktree remove <worktree-path> --force

# Merge 済みブランチ削除
git branch -d feature/{feature-name}
```

## 成功条件

- 全 Feature がトポロジカルソート順で Merge 済み
- 全テストスイートがパス
- SSOT ドキュメントが更新済み
- 統合 PR が作成済み（ユーザー承認後）
- worktree がクリーンアップ済み

## 停止条件

| 条件 | 対応 |
|------|------|
| semantic/structural コンフリクトが解決不可 | 停止、エスカレーション |
| 統合テストが修正不可能な失敗 | 停止、影響範囲を報告 |
| SSOT 統合で矛盾が検出 | 停止、ユーザー確認 |

## チェックリスト

- [ ] integration ブランチが作成されている
- [ ] 全 Feature がトポロジカルソート順で Merge 済み
- [ ] コンフリクトがすべて解決済み
- [ ] 各 Feature Merge 後にユニットテスト実行
- [ ] 全テストスイート（ユニット + 統合 + E2E）がパス
- [ ] 全 Feature の ssot-updates.md を集約済み
- [ ] SSOT ドキュメントが更新済み
- [ ] integration-pr.md が作成済み
- [ ] ユーザー承認後に PR を作成
- [ ] worktree がクリーンアップ済み
