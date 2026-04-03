---
name: ci-failure-triage-worker
description: PRのCI失敗を切り分け、失敗ジョブと再現コマンドを素早く提示する。
---

# ci-failure-triage-worker

目的: PRのCI失敗を短時間で切り分け、再現コマンドと次アクションを提示する。

## 推奨トリガー

- "CIが落ちた" "チェックが赤い" とき
- PRの失敗要因を先に整理してから修正に入るとき

## 入力テンプレート

- 対象PR: `<number>` または `current`
- 範囲: `checks` / `failed-only` / `all`
- 出力形式: 箇条書き（失敗ジョブ、原因候補、再現コマンド）

## 実行手順

1. `gh pr checks <pr>` で失敗ジョブを特定する。
2. 失敗ジョブごとにログURLを収集する。
3. ローカル再現コマンド候補を生成する。
4. 修正優先順位（影響範囲が広い順）を提示する。

## 主要コマンド

```bash
bash toolbox/skills/ci-failure-triage-worker/scripts/triage-pr-ci.sh <pr-number>
gh pr checks <pr-number>
```

## 出力

- チェック一覧（pass/fail）
- 失敗ジョブのURL
- 再現コマンド候補
- 次アクション（修正順）
