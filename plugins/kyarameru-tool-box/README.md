# kyarameru-tool-box

このプラグインは、Norse 系の役割名で Codex の役割分担を最小構成から組み立てるための出発点です。

## 構成

- `AGENTS.md`: このプラグイン内での作業規範
- `config.toml`: Codex の基本設定
- `agents/`: 役割別サブエージェント
- `skills/`: 再利用する作業スキル

## 初期方針

- `Odin` が全体判断を行う
- `Heimdall` が調査する
- `Mimir` が設計する
- `Thor` が実装する
- `Forseti` がレビューする
- `Tyr` が検証する

対応する `skills/` も同じ北欧名で揃える。

必要なものだけを足し、不要な分岐は増やさない。
