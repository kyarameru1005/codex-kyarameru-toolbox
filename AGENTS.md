# AGENTS.md

このリポジトリでは、単一プラグイン `plugins/kyarameru-tool-box/` を基準に作業する。

## ルール

- 応答は日本語で行う
- 変更は必要最小限にとどめる
- 破壊的操作やリポジトリ外の変更は事前確認する
- 秘密情報や実運用データを追加しない
- 旧 `toolbox` 置換フローは使わない
- 最低でも `python3 -m pytest -q` を実行して確認する

## 確認対象

- `plugins/kyarameru-tool-box/.codex-plugin/plugin.json`
- `plugins/kyarameru-tool-box/AGENTS.md`
- `plugins/kyarameru-tool-box/config.toml`
- `tests/`
