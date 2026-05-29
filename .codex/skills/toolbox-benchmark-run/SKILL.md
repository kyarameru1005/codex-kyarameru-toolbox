---
name: toolbox-benchmark-run
description: toolbox-benchmark ディレクトリ内で toolbox のベンチマークを実行、結果保存、gpt-5.5 評価入力作成、評価結果保存まで進める。toolbox-greece などの品質確認、改善前後比較、サブエージェント疎通確認、Zeus のルーティング評価を行うときに使う。
---

# Toolbox Benchmark Run

`toolbox-benchmark/` 内でベンチマークを完結させるための進行スキル。
詳細なケース、評価観点、テンプレートは `toolbox-benchmark/` 配下のファイルを読む。

## 参照ファイル

- `toolbox-benchmark/README.md`: 保存ルールと基本フロー
- `toolbox-benchmark/items/cases.md`: 共通ベンチマーク項目
- `toolbox-benchmark/items/<toolbox>.md`: toolbox 固有の評価観点
- `toolbox-benchmark/results-template.md`: 実行結果テンプレート
- `toolbox-benchmark/evaluator-prompt.md`: gpt-5.5 評価用プロンプト

## 手順

1. `git status --short --branch` で作業状態を確認する。
2. 対象 toolbox と version を決める。例: `toolbox-greece`, `v0`。
3. `toolbox-benchmark/README.md` と対象の `items/*.md` を読む。
4. 実行する Case を選ぶ。指定がなければ Case 1 から順に進める。
5. 実行結果ファイルを `runs/<toolbox>/<version>/<case>.md` に作る。
6. `results-template.md` に沿って、日本語で結果を記録する。
7. gpt-5.5 評価に渡す入力を整理する。
8. 評価結果を受け取ったら `evaluations/<toolbox>/<version>/<case>.md` に日本語で保存する。
9. 最後に改善タスク、検証結果、未評価ケースを報告する。

## 保存先

```text
toolbox-benchmark/
  runs/<toolbox>/<version>/<case>.md
  evaluations/<toolbox>/<version>/<case>.md
```

同じ case を再実行する場合は `case-01-rerun-01.md` のように保存する。
1回分の総括は `summary.md` に保存する。

## gpt-5.5 評価入力

評価を依頼するときは、次をまとめて渡す。

- `evaluator-prompt.md`
- 該当 case の本文
- toolbox 固有の評価観点
- `runs/<toolbox>/<version>/<case>.md` の実行結果

評価結果は日本語で出力させる。

## 注意

- 秘密情報、実行ログ全文、セッション、個人環境に依存する絶対パスを保存しない。
- cwd 外の変更や破壊的操作を含むケースは、実行せず評価用の模擬ケースとして扱う。
- ベンチマーク自体の改善は `toolbox-benchmark/` 内に閉じる。
