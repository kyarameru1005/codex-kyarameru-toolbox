# Harness Specification (v1)

この仕様は、ハーネスを「単発実行」ではなく「長時間運転できるオーケストレーション基盤」として定義する。

## 1. 目的

- ロングラン実行でも再現可能・再開可能・監査可能な運用を実現する。
- 品質ゲートを必須化し、生成物の品質を一定以上に保つ。

## 2. スコープ（v1）

- 単一リポジトリ内でのジョブ実行
- ジョブ状態管理
- 失敗時の再試行
- 品質ゲート（policy / quick / full）
- レポートとメトリクス出力

## 3. アーキテクチャ

- Planner: 実行計画（ジョブ定義）を決定
- Orchestrator: 状態遷移、再試行、タイムアウト、並列数制御
- Worker: 実処理（実装・検証・更新）を実行
- Quality Gate: 合否判定
- Reporter: レポートとメトリクスを記録

## 4. ジョブ状態遷移

状態は以下を使用する。

- `queued`: 実行待ち
- `running`: 実行中
- `checkpointed`: 中間保存完了（再開可能）
- `passed`: 品質ゲート含め成功
- `failed`: 再試行上限または致命的失敗

遷移ルール:

1. `queued -> running`
2. `running -> checkpointed`（任意。中断復旧用）
3. `running -> passed`（全ゲート成功）
4. `running -> failed`（再試行不可 or 上限超過）
5. `failed -> queued`（再試行可能な場合のみ）

## 5. 入出力契約

入力:

- `toolbox/harness/config/default.json`
- 必要に応じて `toolbox/harness/input/*`

出力:

- 実行ログ
- `docs/harness-reports/*.md`（定期レポート）
- `docs/harness-reports/metrics/*.jsonl`（メトリクス）

終了コード:

- `0`: 成功
- `1`: 品質ゲート失敗
- `2`: 入力不正/設定不備
- `>=10`: 実行環境エラー（依存不足など）

## 6. 品質ゲート

v1では以下を標準とする。

- `policy`: `bash scripts/policy-check.sh`
- `quick`: `bash scripts/harness.sh --quick`
- `full`: `python -m pytest -q` と `bash scripts/harness.sh`

`quick` モードでは `policy + quick` を必須、`full` は任意。
`full` モードでは `policy + quick + full` を必須。

## 7. 再試行・タイムアウト

- `max_retries`: ジョブ失敗時の再試行回数
- `timeout_sec`: ジョブ全体のタイムアウト
- `retry_backoff_sec`: 再試行待機秒数

再試行対象:

- 一時的な実行失敗（ネットワーク、ロック競合など）

非再試行対象:

- 入力不備
- 静的検証で確定的に失敗するケース

## 8. 並列制御

- `parallelism`: 同時実行ジョブ数
- v1は安全のため既定 `1`
- 将来は依存関係（DAG）を前提に並列化

## 8.1 ワーカー選択ルール（コスト最適化）

- `harness-worker-lite` を使う条件:
  - 変更ファイル数が `2` 以下
  - 予想差分が `150` 行以下
  - `pytest` 実行が不要
- 上記以外は `harness-worker` を使う。
- 影響範囲が広い、または不確実性が高いタスクは `harness-worker` を必須にする。

## 9. チェックポイント

最低限保持する情報:

- ジョブID
- 現在状態
- 最終成功ステップ
- 再試行回数
- 開始/更新時刻

保存先（v1）:

- `toolbox/harness/output/checkpoints/*.json`
- `toolbox/harness/state/tasks.json`（タスク台帳）

更新手段（v1）:

- `bash scripts/update-task-state.sh init`
- `bash scripts/update-task-state.sh upsert --task-id <id> --status <status> --owner <agent>`
- `bash scripts/update-task-state.sh set-status --task-id <id> --status <status>`

## 10. レポートとメトリクス

レポート:

- `docs/harness-reports/<timestamp>-<title>.md`
- `結論 / 実施内容 / 課題 / 次アクション / 検証`

メトリクス:

- `docs/harness-reports/metrics/<YYYY-MM>.jsonl`
- 最低項目: `timestamp, title, mode, status, duration_sec, report_path`

## 11. v1受け入れ基準

1. `scripts/report-validate-apply.sh` で、レポート作成から適用まで完了できる。
2. 成功/失敗時のメトリクスが必ず1件残る。
3. 失敗時に再現コマンドがログへ出力される。
4. 生成物と仕様に齟齬がない。

## 12. Orchestrator 実行フロー（task-state）

1. `upsert(queued)` でタスクを登録する。  
2. 実作業開始時に `set-status(running)` へ遷移する。  
3. 長時間タスクは区切りで `set-status(checkpointed)` を記録する。  
4. 品質ゲートを通過したら `set-status(passed)` にする。  
5. 失敗時は `set-status(failed)` にする。  
6. 再試行時は `upsert(... --retries <n+1>)` 後に `running` へ戻す。  

## 13. v1 参照実装（orchestrator-worker）

- スキル定義: `toolbox/skills/orchestrator-worker/SKILL.md`
- 実行スクリプト: `toolbox/skills/orchestrator-worker/scripts/run-task.sh`

標準実行例:

```bash
bash toolbox/skills/orchestrator-worker/scripts/run-task.sh \
  --task-id T-018 \
  --owner harness-worker \
  --command "bash scripts/report-validate-apply.sh --title harness-t018 --quick" \
  --max-retries 1 \
  --retry-backoff-sec 5
```

補足:

- `--checkpoint-command` を指定した場合、成功時に `checkpointed` を記録する。
- 同一 `task-id` が `passed` の場合は再実行せず終了する。
