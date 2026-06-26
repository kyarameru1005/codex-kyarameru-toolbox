# agents

このディレクトリは、`norse-toolbox` の役割定義を置く場所です。現段階では `Odin`、`Heimdall`、`Mimir`、`Thor`、`Forseti`、`Tyr`、`Bragi` の agent 実装を持ちます。

## 役割一覧

- `Odin`: 目的、制約、完了条件を整理し、必要な役割と実行順を決める
- `Heimdall`: 関連コード、設定、影響範囲を調査する
- `Mimir`: 設計、責務分離、選択肢比較を整理する
- `Thor`: 実装を最小差分で進める
- `Forseti`: バグ、回帰、危険な仮定をレビューする
- `Tyr`: テストと検証結果を評価する
- `Bragi`: 変更内容と運用知識を文書化する

## 運用メモ

- 実作業の入口は常に `Odin`
- `agents/odin.toml` は read-only で、委譲判断だけを担当する
- `agents/heimdall.toml` は read-only で、関連コードと影響範囲の調査を担当する
- `agents/mimir.toml` は read-only で、設計整理と選択肢比較を担当する
- `agents/thor.toml` は workspace-write で、実装とローカル確認を担当する
- `agents/forseti.toml` は read-only で、バグ、回帰、危険な仮定とテスト不足の指摘を担当する
- `agents/tyr.toml` は workspace-write で、テスト追加、実行、結果評価を担当する
- `agents/bragi.toml` は read-only で、変更説明と運用知識の整理を担当する
- 役割ファイルを追加するときは README とテストを同時に更新する
