# Task List

このファイルは、このリポジトリで管理する作業タスクの正本。

## 運用ルール

- 新規タスク追加時にこの一覧へ記録する。
- 未着手は `- [ ]`、完了は `- [x]` を使う。
- 進行中は行末に `(doing)` を付ける。
- 完了時は必要なら行末に補足メモを残す。
- 優先度は `high` / `medium` / `low` を使う。

## タスク一覧

- [x] `T-001` [high] リポジトリ横断台帳 `~/.codex/repo-task-index.md` へ本リポジトリを登録（`docs/task-list.md` へのリンクを記載）
- [x] `T-002` [medium] `docs/task-list.md` の定期更新ルールを README に追記（運用漏れ防止）
- [x] `T-003` [high] `update` 実行時に旧配備物（stale managed path）をクリーンアップする
- [x] `T-004` [high] README の同梱内容を実装実態に合わせて修正する
- [x] `T-005` [high] `plan-worker` / `mcp-worker` の SKILL 定義を具体化する
- [x] `T-006` [medium] `check_agents_md.sh` のテストを追加する
- [x] `T-007` [medium] `update` 削除系のテストを追加する
- [x] `T-008` [medium] AGENTS 重複管理の方針を README へ明記する
- [x] `T-009` [high] スキル作成時の検証スキル（`skill-validation-worker`）を追加する
- [x] `T-010` [medium] `README.md` にタスク台帳運用とスキル検証手順を追記する
- [x] `T-011` [medium] `policy-check` / テストに新スキル検証のチェックを追加する
- [x] `T-012` [high] 修正作業フロー（ブランチ分離→検証→PR）をスクリプト化する
- [x] `T-013` [medium] 作業フローを README に追記し、実行可能性をテストで担保する
- [x] `T-014` [high] `ci-failure-triage-worker` を追加する
- [x] `T-015` [high] `pr-quality-gate-worker` を追加する
- [x] `T-016` [high] 新規スキルの `SKILL.md` を雛形（frontmatter）準拠に修正する
- [x] `T-017` [medium] `check-skill.sh` に frontmatter 必須チェックを追加する
- [x] `T-018` [high] ロングラン運用向けの `orchestrator-worker` を追加し、状態ファイルベースで再開可能な実行方式を設計する
- [ ] `T-019` [high] 文脈圧縮用の `context-reducer-worker` とトークン予算運用ルールを追加し、README に利用方針を追記する
- [x] `T-020` [low] `toolbox/AGENTS.md` から不要な「適用手順」セクションを削除する
- [x] `T-021` [medium] 比較検証用に `~/.codex` をデフォルト状態へ戻すスクリプトを追加し、README に手順を追記する
- [x] `T-022` [medium] 公式ドキュメントに基づく最小初期状態 `codex-initial-state` を追加し、復元スクリプト既定値を切り替える

## メモ

- 2026-03-26: 本日の作業はここで終了。次回は `T-001` から再開する。
- 2026-04-03: 優先度順（高→中）で `T-003` 〜 `T-008` を実施。
- 2026-04-03: 全体整理として `T-009` 〜 `T-011` を実施。
- 2026-04-03: 標準作業フローの実行スクリプト（`start-branch.sh`, `finish-pr.sh`）を追加。
- 2026-04-03: `ci-failure-triage-worker` と `pr-quality-gate-worker` を追加。
- 2026-04-03: スキル雛形崩れの修正（frontmatter統一 + 検証強化）を実施。
- 2026-04-10: Discord で作業進捗を扱う機能は時期尚早のため、通知スクリプトと関連ワークフローを削除。
- 2026-04-14: ロングラン orchestration と token 削減の検討を新規タスク `T-018` `T-019` として追加。
- 2026-04-14: `T-002` として README に台帳の定期更新ルールを追記。
- 2026-04-15: `T-020` として `toolbox/AGENTS.md` の不要な適用手順セクションを削除。
- 2026-04-22: `T-021` として `scripts/restore-codex-default.sh` を追加し、README に比較検証用の復元手順を追記。
- 2026-04-22: `T-022` として `codex-initial-state`（最小構成）を追加し、`restore-codex-default.sh` の既定復元元を切り替え。
- 2026-04-24: `T-018` として `orchestrator-worker`（state ベース再開・再試行）を追加し、README/仕様へ運用手順を追記。
