# Toolbox Benchmark

Codex toolbox の品質を確認するためのベンチマーク置き場です。

ここには、toolbox ごとの評価観点、手動テストケース、結果記録テンプレート、評価プロンプト、実行結果を置きます。
認証情報、実行ログ全文、セッション、個人環境に依存する出力は置きません。

## 想定する用途

- toolbox の疎通確認
- サブエージェントの役割分担確認
- オーケストレーションの判断品質確認
- モデル設定や推論レベルの比較
- 改善前後の結果比較

## 運用ルール

- 同じケースを同じ条件で実行し、改善前後を比較する。
- 実行結果は `runs/<toolbox>/<version>/` に保存し、評価結果は `evaluations/<toolbox>/<version>/` に保存する。
- 結果と評価は日本語で記録する。
- 採点は `evaluator-prompt.md` を使い、必要に応じて `gpt-5.5` に評価させる。
- 失敗した結果も残し、次の改善点が分かるようにする。
- 秘密情報、実行ログ全文、個人環境の絶対パスは記録しない。

## 保存ルール

同じ toolbox を何度も評価できるように、toolbox 名とバージョンで結果を分けます。

```text
toolbox-benchmark/
  runs/
    toolbox-greece/
      v0/
        case-01.md
  evaluations/
    toolbox-greece/
      v0/
        case-01.md
```

- `<toolbox>` は `toolbox-greece` のようなディレクトリ名に合わせる。
- `<version>` は `v0`, `v1`, `v2` のように短く付ける。
- 同じバージョンで再実行する場合は `case-01-rerun-01.md` のように分ける。
- 1回分の総括を残す場合は `summary.md` を置く。

## 基本フロー

1. `items/cases.md` からケースを選ぶ。
2. 対象 toolbox にケースの入力を投げる。
3. 出力を `results-template.md` に沿って `runs/<toolbox>/<version>/<case>.md` に保存する。
4. `evaluator-prompt.md` と `runs/` の結果を `gpt-5.5` に渡して評価させる。
5. 評価結果を `evaluations/<toolbox>/<version>/<case>.md` に保存する。
6. 改善点を次の toolbox 修正タスクへ戻す。

## 採点

各ケースは 0 から 3 点で評価します。

- 0: 目的を満たしていない
- 1: 一部は使えるが、重要な不足がある
- 2: 実用できるが、改善余地がある
- 3: 期待どおりで、そのまま次の作業に使える

## 想定するファイル

- `README.md`: このディレクトリの目的と運用ルール
- `items/`: ベンチマーク項目
- `items/cases.md`: 共通のベンチマーク用タスクケース
- `items/toolbox-greece.md`: `toolbox-greece` 向けの評価観点
- `results-template.md`: 結果記録テンプレート
- `evaluator-prompt.md`: `gpt-5.5` に評価させるためのプロンプト
- `runs/<toolbox>/<version>/`: ベンチマーク実行結果
- `evaluations/<toolbox>/<version>/`: `gpt-5.5` などによる評価結果
