# Repository Layout

このリポジトリは `toolbox/` を Codex 設定の原本として管理し、名前付きコピーと `~/.codex` への安全な適用を扱う。

## 主要ディレクトリ

- `toolbox/`: Codex 設定原本。`~/.codex` へ適用する候補をここで管理する。初期状態では `config.toml`, `AGENTS.md` と空の設定ディレクトリ群を置く。
- `toolbox-名前/`: `toolbox/` から作成した名前付きコピー。例: `toolbox-greece/`, `toolbox-japan/`。
- `scripts/`: 複製・適用・検証スクリプトを置く。
- `tests/`: スクリプトの単体テストを置く。
- `docs/`: 運用・設計・リポジトリ構造の正本文書を置く。

## 適用対象

`scripts/toolbox-manager.py apply` が `~/.codex` へ適用する対象は次に限定する。
空ディレクトリ保持用の `.gitkeep` は適用しない。

- `config.toml`
- `AGENTS.md`
- `skills/`
- `agents/`
- `hooks/`
- `prompts/`
- `plugins/`
- `mcp/`
- `memories/`

## 適用除外対象

認証情報、履歴、実行状態、DB、ログ、セッション、キャッシュは `~/.codex` へ適用しない。

- `auth.json`
- `history.jsonl`
- `session_index.jsonl`
- `installation_id`
- `*.sqlite*`
- `log/`
- `sessions/`
- `shell_snapshots/`
- `tmp/`
- `.tmp/`
- `cache/`
- `vendor_imports/`
- `models_cache.json`
- `.codex-global-state.json`

## マニフェスト

適用時は `~/.codex/.kyarameru-tool-box-manifest.json` に管理対象だけを記録する。
このマニフェストは `toolbox-manager.py status` の確認材料として使う。
