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
- [ ] `T-002` [medium] `docs/task-list.md` の定期更新ルールを README に追記（運用漏れ防止）
- [x] `T-003` [high] `update` 実行時に旧配備物（stale managed path）をクリーンアップする
- [x] `T-004` [high] README の同梱内容を実装実態に合わせて修正する
- [x] `T-005` [high] `plan-worker` / `mcp-worker` の SKILL 定義を具体化する
- [x] `T-006` [medium] `check_agents_md.sh` のテストを追加する
- [x] `T-007` [medium] `update` 削除系のテストを追加する
- [x] `T-008` [medium] AGENTS 重複管理の方針を README へ明記する
- [x] `T-009` [high] スキル作成時の検証スキル（`skill-validation-worker`）を追加する
- [x] `T-010` [medium] `README.md` にタスク台帳運用とスキル検証手順を追記する
- [x] `T-011` [medium] `policy-check` / テストに新スキル検証のチェックを追加する

## メモ

- 2026-03-26: 本日の作業はここで終了。次回は `T-001` から再開する。
- 2026-04-03: 優先度順（高→中）で `T-003` 〜 `T-008` を実施。
- 2026-04-03: 全体整理として `T-009` 〜 `T-011` を実施。
