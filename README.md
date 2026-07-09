# kyarameru-tool-box

このリポジトリは、`norse-toolbox` を配布するための Codex plugin リポジトリです。

## 現在の構成

- `plugins/norse-toolbox/`: 現在の配布対象 plugin
- `tests/`: プラグイン構成の確認

## 入口

- プラグイン定義: [`plugins/norse-toolbox/.codex-plugin/plugin.json`](plugins/norse-toolbox/.codex-plugin/plugin.json)
- リポジトリ方針: [`AGENTS.md`](AGENTS.md)

## 進め方

1. まず `plugins/norse-toolbox/` を編集する
2. 必要なら `agents/`、`skills/`、`.agents/plugins/marketplace.json` を更新する
3. 変更後は `python3 -m pytest -q` で確認する

## GitHub から追加する

1. marketplace 追加:
   `codex plugin marketplace add kyarameru1005/kyarameru-tool-box --sparse .agents/plugins`
2. plugin 追加:
   `codex plugin add norse-toolbox@kyarameru-codex`

リポジトリ配布の入口は [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json) です。
