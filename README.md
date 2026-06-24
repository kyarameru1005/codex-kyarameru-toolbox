# kyarameru-tool-box

このリポジトリは、単一の Codex プラグイン `kyarameru-tool-box` を配布するための土台です。
旧来の `toolbox` 複数管理と `~/.codex` 置換スクリプトは廃止し、プラグインを起点に再構成します。

## 現在の構成

- `plugins/kyarameru-tool-box/`: 配布するプラグイン本体
- `tests/`: プラグイン構成の確認

## 入口

- プラグイン定義: [`plugins/kyarameru-tool-box/.codex-plugin/plugin.json`](plugins/kyarameru-tool-box/.codex-plugin/plugin.json)
- リポジトリ方針: [`AGENTS.md`](AGENTS.md)

## 進め方

1. まず `plugins/kyarameru-tool-box/` を編集する
2. 必要なら `agents/` と `skills/` を追加する
3. 変更後は `python3 -m pytest -q` で確認する
