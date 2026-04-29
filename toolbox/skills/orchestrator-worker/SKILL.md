---
name: orchestrator-worker
description: 状態ファイル（tasks.json）を使って、再開可能なハーネス実行を管理する。
allowed-tools: Bash, Read, Write
user-invocable: true
---

# orchestrator-worker

## 目的

- repo ローカルの `.codex/state/orchestrator-state.json` を既定の正本として、タスク状態を管理する。
- 失敗時に再試行し、途中停止後も同一 `task-id` で再開できる実行方式を提供する。
- 状態更新ロジックをスキル配下へ同梱し、他リポジトリへ持ち込んでも再利用できるようにする。

## 推奨トリガー

- 長時間実行タスクを `queued/running/checkpointed/passed/failed` で管理したいとき。
- 品質ゲート実行を再試行付きで管理したいとき。
- 再開時に「前回どこまで進んだか」を state ファイルで確認したいとき。

## 実行コマンド

```bash
bash toolbox/skills/orchestrator-worker/scripts/run-task.sh \
  --task-id T-018 \
  --owner harness-worker \
  --command "bash scripts/report-validate-apply.sh --title harness-t018 --quick" \
  --max-retries 1 \
  --retry-backoff-sec 5
```

## 入力

- `--task-id`: タスク識別子（必須）
- `--owner`: 担当エージェント名（必須）
- `--command`: 実行コマンド（必須）
- `--max-retries`: 再試行回数（既定: `0`）
- `--retry-backoff-sec`: 再試行待機秒（既定: `3`）
- `--checkpoint-command`: チェックポイント保存用コマンド（任意）
- `--state-file`: 状態ファイルのパス（既定: `.codex/state/orchestrator-state.json`）

## 再利用条件

- `run-task.sh` は同じディレクトリにある `update-task-state.sh` を相対参照する。
- 既定の state file は repo ローカル `.codex/state/orchestrator-state.json` で、必要なら `--state-file` で切り替えられる。
- 利用側で必要なのは `bash` と `python3` のみで、repo 直下 `scripts/` への依存はない。

## 出力

- 状態更新:
  - 初回: `upsert(queued)`
  - 実行開始: `set-status(running)`
  - 中間保存: `set-status(checkpointed)`（`--checkpoint-command` 成功時）
  - 成功: `set-status(passed)`
  - 失敗: `set-status(failed)`（再試行時は `upsert(queued, retries=n)`）
- 標準出力:
  - 実行ステップログ
  - 失敗時の終了コードと再現コマンド
