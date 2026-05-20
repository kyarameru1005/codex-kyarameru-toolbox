# kyarameru-tool-box

`toolbox/` を Codex 設定の原本として管理するリポジトリです。
原本を `toolbox-greece/`, `toolbox-japan/` のような `toolbox-名前/` へ複製し、必要な toolbox だけを `~/.codex` へ安全に適用します。

このリポジトリで扱うのは設定ファイルと設定ディレクトリです。認証情報、履歴、DB、ログ、セッション、キャッシュは `~/.codex` へ適用しません。

初期構成として `toolbox/config.toml`, `toolbox/AGENTS.md` に加え、`skills/`, `plugins/`, `agents/`, `hooks/`, `prompts/`, `mcp/`, `memories/` を空ディレクトリとして含めます。
各ディレクトリの中身は初期状態では作成せず、必要になった項目だけ後から追加します。

## できること

- `toolbox/` を `toolbox-名前/` へ複製して用途別に管理する。
- `toolbox/` または `toolbox-名前/` を指定して `~/.codex` へ適用する。
- 適用前に `--dry-run` で変更予定と除外対象を確認する。
- `--safe` でバックアップ付き適用、`--force` でバックアップなし適用を選べる。
- 適用済みの管理対象を `~/.codex/.kyarameru-tool-box-manifest.json` に記録する。

## 前提

- Python 3.11+
- テスト実行時のみ pytest

## 基本フロー

1. 現在の状態を確認する。

```bash
python3 scripts/toolbox-manager.py status
```

2. 原本 `toolbox/` から名前付きコピーを作る。

```bash
python3 scripts/toolbox-manager.py copy --name greece
```

この例では `toolbox-greece/` を作ります。
`--name japan` なら `toolbox-japan/`、`--name staging` なら `toolbox-staging/` を作ります。
互換のため、`--name` を省略した場合は従来どおり次の空き番号 `toolboxN/` を作れます。

3. 適用前に dry-run で確認する。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --dry-run
```

4. 問題なければバックアップ付きで適用する。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
```

バックアップを取らずに適用する場合:

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --force
```

## コマンド

### copy

```bash
python3 scripts/toolbox-manager.py copy [--source toolbox] [--name greece] [--dry-run]
```

`--source` で指定した toolbox を、`--name` で指定した `toolbox-名前/` へそのまま複製します。
たとえば `--name greece` なら `toolbox-greece/` を作ります。
これはリポジトリ内のスナップショット作成なので、認証情報や履歴などが含まれていてもコピー対象から除外しません。
`copy` は既存の中身をそのまま複製します。初期状態の空ディレクトリもそのまま引き継ぎます。
`--name` を省略した場合は互換用に次の空き番号 `toolboxN/` を作ります。

### apply

```bash
python3 scripts/toolbox-manager.py apply [--toolbox toolbox] [--codex-home ~/.codex] [--dry-run]
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --force
```

指定した toolbox を `~/.codex` へ適用します。
既定の適用元は `toolbox/` です。

既存ファイルを上書きする場合:

- 対話実行では確認プロンプトを出す。
- `--safe`: 確認なしで上書きし、上書き前のファイルを `~/.codex/backup/<timestamp>/` へ退避する。
- `--force`: 確認なしで上書きし、バックアップは作らない。
- 互換用に `--yes --backup` と `--yes --no-backup` も使える。

### status

```bash
python3 scripts/toolbox-manager.py status [--toolbox toolbox] [--codex-home ~/.codex]
```

指定した toolbox と `~/.codex` の管理対象を比較し、`current`, `different`, `missing` を表示します。

## 適用対象

`apply` が `~/.codex` へ適用する対象は次に限定します。
空ディレクトリをリポジトリで保持するための `.gitkeep` は適用対象に含めません。

- `config.toml`
- `AGENTS.md`
- `skills/`
- `agents/`
- `hooks/`
- `prompts/`
- `plugins/`
- `mcp/`
- `memories/`

## 適用除外

次のファイルとディレクトリは `~/.codex` へ適用しません。

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

## リポジトリ構造

- `toolbox/`: Codex 設定原本。初期状態では `config.toml`, `AGENTS.md` と空の設定ディレクトリ群を置く。
- `toolbox-名前/`: `toolbox/` から作成した名前付きコピー。例: `toolbox-greece/`, `toolbox-japan/`。
- `scripts/`: 複製、適用、検証スクリプト。
- `tests/`: スクリプトの単体テスト。
- `docs/`: 運用文書。

詳細は `docs/repository-layout.md` を参照してください。

## テスト

初回のみ開発依存を入れます。

```bash
python3 -m pip install -e '.[dev]'
```

テストを実行します。

```bash
python3 -m pytest -q
```

`AGENTS.md` チェック用スクリプトが存在する場合は次も実行します。

```bash
bash toolbox/skills/bootstrap-repository/scripts/check-agents-md.sh AGENTS.md
```

## 安全メモ

- 実運用の `~/.codex` へ適用する前に、必ず `--dry-run` で差分を確認する。
- 認証情報や履歴を `~/.codex` へ反映したい場合でも、このスクリプトでは適用対象にしない。
- 既存の `~/.codex` を上書きする運用では、原則 `--safe` を使う。
- `--force` はバックアップ不要と判断できる場合だけ使う。
