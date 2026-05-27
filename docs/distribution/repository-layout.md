# Repository Layout

このリポジトリは `toolbox/` を初期状態へ戻すための Codex 設定原本として管理し、配布用 toolbox と `~/.codex` への安全な置換を扱う。

## 主要ディレクトリ

- `toolbox/`: 初期状態へ戻すための Codex 設定原本。`config.toml`, `AGENTS.md` と空の設定ディレクトリ群を置く。
- `toolbox-greece/`: 設定済み toolbox の第1号。ギリシャ神話モチーフのエージェントとスキルを含む配布サンプルとして扱う。
- `toolbox-名前/`: 今後追加する配布用 toolbox。例: `toolbox-japan/`, `toolbox-work/`。
- `scripts/`: 複製・置換・検証スクリプトを置く。
- `tests/`: スクリプトの単体テストを置く。
- `docs/distribution/`: 配布用の運用・設計・リポジトリ構造の正本文書を置く。
- `docs/private/`: 個人研究用のローカル文書を置く。Git では追跡しない。

## 置換対象

`scripts/toolbox-manager.py apply` が `~/.codex` で置き換える対象は次に限定する。
空ディレクトリ保持用の `.gitkeep` は置換しない。

- `config.toml`
- `AGENTS.md`
- `skills/`
- `agents/`
- `hooks/`
- `prompts/`
- `plugins/`
- `mcp/`
- `memories/`

## 置換除外対象

認証情報、履歴、実行状態、DB、ログ、セッション、キャッシュは `~/.codex` で置き換えない。

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

置換時は `~/.codex/.kyarameru-tool-box-manifest.json` に管理対象だけを記録する。
このマニフェストは `toolbox-manager.py status` の確認材料として使う。
