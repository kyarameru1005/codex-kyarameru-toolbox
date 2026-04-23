---
name: harness-report-writer
description: ハーネス構築の定期進捗レポートを docs/harness-reports に標準形式で記録する
---

# harness-report-writer

目的: ハーネス構築作業の進捗と課題を定期記録し、判断履歴を追跡可能にする。

## 推奨トリガー

- ハーネス実装の区切りごとに進捗を残したいとき
- 失敗や詰まりを後で振り返れる形で残したいとき
- 次回の再開時に、直前状態を短時間で把握したいとき

## 入力テンプレート

- タイトル: `harness-weekly` など
- 実施内容: 箇条書き
- 課題: 箇条書き
- 次アクション: 箇条書き

## 実行手順

1. `scripts/write-report.sh` を実行する。
2. プロンプトに従って `結論 / 実施内容 / 課題 / 次アクション / 検証` を1項目ずつ入力する。
3. 必要なら追記して保存する。
4. PR本文に要約（目的 / 変更点 / 検証結果）を反映する。

## 主要コマンド

```bash
bash toolbox/skills/harness-report-writer/scripts/write-report.sh \
  --title harness-weekly
```

## 出力

- `docs/harness-reports/<timestamp>-<title>.md`
- 見出し: `結論` / `実施内容` / `課題` / `次アクション` / `検証`
