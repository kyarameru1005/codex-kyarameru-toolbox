# pr-quality-gate-worker

目的: PR本文と差分の最低品質ゲートを事前に検証し、レビュー差し戻しを減らす。

## 推奨トリガー

- PR作成直前
- レビュー前のセルフチェック

## 入力テンプレート

- 対象: `body-file` または `pr-number`
- 必須要件: `目的` / `主な変更点` / `検証結果`
- 任意要件: 実行コマンド記載、失敗ケース記載

## 実行手順

1. PR本文の必須セクション有無をチェックする。
2. 検証結果にコマンド記載があるかを確認する。
3. 欠落があれば修正例を返す。

## 主要コマンド

```bash
bash toolbox/skills/pr-quality-gate-worker/scripts/check-pr-quality.sh --body-file docs/pr-template.md
bash toolbox/skills/pr-quality-gate-worker/scripts/check-pr-quality.sh --pr 12
```

## 出力

- 判定（pass/fail）
- 欠落項目
- 修正提案
