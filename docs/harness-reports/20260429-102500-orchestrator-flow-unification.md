# 結論

- オーケストレーション最小完成プランに沿って、標準導線を1本化し、READMEと仕様の記述を一致させた。

# 実施内容

- `README.md` の Orchestrator 節を更新し、標準コマンドを1系統に固定した。
- 必須入力を `task-id / owner / command / max-retries` として明示した。
- 状態遷移（`queued -> running -> checkpointed(optional) -> passed/failed`）と再試行時の `upsert queued(retries+1) -> running` を明文化した。
- 品質ゲート順序を `policy-check -> harness --quick -> (必要時) pytest` に統一して追記した。
- 標準ハンドオフ順を `prechecker/researcher -> worker -> reviewer -> reporter` に固定し、調査不要の例外条件を追記した。
- 実行完了時の `docs/harness-reports/` への記録必須化と、PR本文の必須記載（目的/主な変更点/検証結果）を追記した。

# 課題

- `scripts/report-validate-apply.sh --quick` 実行時に、既存のレポート生成処理で `結論: [ERROR] empty input is not allowed` が大量出力される事象を確認した。
- 本件は既存実装由来であり、今回スコープ（導線一本化）では未修正。

# 次アクション

- 上記事象を別タスク化し、`toolbox/skills/harness-report-writer/scripts/write-report.sh` の入力検証とテンプレート生成処理を調査する。

# 検証

- 正常系: `bash toolbox/skills/orchestrator-worker/scripts/run-task.sh --task-id T-ORCH-PASS --owner harness-worker --command "true" --max-retries 0 --state-file toolbox/harness/output/orch-pass-state.json`
  - `passed` まで遷移を確認。
- 異常系: `bash toolbox/skills/orchestrator-worker/scripts/run-task.sh --task-id T-ORCH-FAIL --owner harness-worker --command "false" --max-retries 1 --retry-backoff-sec 0 --state-file toolbox/harness/output/orch-fail-state.json`
  - `failed` 記録と `retries: 1` を確認。
- 導線整合: `bash scripts/policy-check.sh` と `bash scripts/harness.sh --quick` の成功を確認。
