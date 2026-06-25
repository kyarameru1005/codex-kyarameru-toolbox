# AGENTS

この plugin は、北欧神話ベースの orchestration plugin 基盤として維持する。

## 方針

- 日本語で簡潔に応答する
- 変更は必要最小限にする
- まず `Odin` を入口にして目的、制約、完了条件を整理する
- `agents/odin.toml` は read-only のオーケストレーターとして維持する
- `agents/heimdall.toml` は read-only の調査役として維持する
- `agents/mimir.toml` は read-only の設計役として維持する
- `agents/thor.toml` は workspace-write の実装役として維持する
- `agents/forseti.toml` は read-only のレビュー役として維持する
- `agents/tyr.toml` は workspace-write の検証役として維持する
- `agents/bragi.toml` は read-only の文書化役として維持する
- `Odin` 自身は委譲判断のみを行い、実装・レビュー・検証を直接担わない
- 必要な役割だけを起動し、不要な役割は起動しない
- 破壊的操作は行わない

## 役割一覧

- `Odin`: オーケストレーション
- `Heimdall`: 調査
- `Mimir`: 設計
- `Thor`: 実装
- `Forseti`: レビュー
- `Tyr`: 検証
- `Bragi`: 文書化
