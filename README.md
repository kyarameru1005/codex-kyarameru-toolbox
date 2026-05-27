# kyarameru-tool-box

`toolbox/` を初期状態へ戻すための原本として管理し、配布用に整えた `toolbox-名前/` を `~/.codex` へ安全に置換するリポジトリです。

このリポジトリで扱うのは設定ファイルと設定ディレクトリです。認証情報、履歴、DB、ログ、セッション、キャッシュは `~/.codex` へ置換しません。

初期状態の `toolbox/` には `toolbox/config.toml`, `toolbox/AGENTS.md` に加え、`skills/`, `plugins/`, `agents/`, `hooks/`, `prompts/`, `mcp/`, `memories/` を空ディレクトリとして含めます。
各ディレクトリの中身は初期状態では作成せず、必要になった項目だけ後から追加します。

## 配布方針

- `toolbox/`: 初期状態へ戻すための最小 toolbox。設定をリセットしたい場合に使う。
- `toolbox-greece/`: 設定済み toolbox の第1号。ギリシャ神話モチーフのエージェントとスキルを含む配布サンプルとして扱う。
- `toolbox-名前/`: 今後追加する配布用 toolbox。用途やテーマごとに増やしていく。

## できること

- 初期状態の `toolbox/` を `~/.codex` へ適用してリセットする。
- 配布用の `toolbox-名前/` を用途別に管理する。
- 指定した toolbox を `~/.codex` へ置換する。
- `--dry-run`、`--safe`、`--force` を使って置換の確認と制御を行う。
- 置換済みの管理対象を `~/.codex/.kyarameru-tool-box-manifest.json` に記録する。

## 前提

- Python 3.11+

## 基本フロー

1. 現在の状態を確認する。

```bash
python3 scripts/toolbox-manager.py status
```

2. 配布用 toolbox の置換内容を dry-run で確認する。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --dry-run
```

3. 問題なければバックアップ付きで置換する。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
```

4. 初期状態へ戻したい場合は `toolbox/` を dry-run してから適用する。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox --dry-run
python3 scripts/toolbox-manager.py apply --toolbox toolbox --safe
```

## コマンド

### copy

```bash
python3 scripts/toolbox-manager.py copy [--source toolbox] [--name greece] [--dry-run]
```

`--source` で指定した toolbox を、`--name` で指定した `toolbox-名前/` へ複製します。
`--name` を省略した場合は次の空き番号 `toolboxN/` を作ります。
既存の配布用 toolbox と同じ名前には上書きしません。
認証情報、履歴、DB、ログ、セッション、キャッシュなどの除外対象は複製しません。

### apply

```bash
python3 scripts/toolbox-manager.py apply [--toolbox toolbox] [--codex-home ~/.codex] [--dry-run]
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --force
```

指定した toolbox を `~/.codex` へ置換します。`AGENTS.md` を含む管理対象は既存の中身を消して再作成します。
- `--safe`: バックアップ付きで置換する。
- `--force`: バックアップなしで置換する。
- 対話実行では確認プロンプトを出す。
- 互換用に `--yes --backup` と `--yes --no-backup` も使える。

### status

```bash
python3 scripts/toolbox-manager.py status [--toolbox toolbox] [--codex-home ~/.codex]
```

指定した toolbox と `~/.codex` の管理対象を比較し、`current`, `different`, `missing` を表示します。

## 置換対象

`apply` が `~/.codex` で置き換える対象は次に限定します。
空ディレクトリをリポジトリで保持するための `.gitkeep` は置換対象に含めません。

- `config.toml`
- `AGENTS.md`
- `skills/`
- `agents/`
- `hooks/`
- `prompts/`
- `plugins/`
- `mcp/`
- `memories/`

## 置換除外

次のファイルとディレクトリは `~/.codex` で置き換えません。

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

- `toolbox/`: 初期状態へ戻すための Codex 設定原本。`config.toml`, `AGENTS.md` と空の設定ディレクトリ群を置く。
- `toolbox-greece/`: 設定済み toolbox の第1号。配布サンプルとして扱う。
- `toolbox-名前/`: 今後追加する配布用 toolbox。例: `toolbox-japan/`, `toolbox-work/`。
- `scripts/`: 複製、置換、検証スクリプト。
- `tests/`: スクリプトの単体テスト。
- `docs/distribution/`: 配布用の運用文書。
- `docs/private/`: 個人研究用のローカル文書。Git では追跡しない。

詳細は `docs/distribution/repository-layout.md` を参照してください。

## テスト

開発依存は初回のみ入れます。

```bash
python3 -m pip install -e '.[dev]'
```

```bash
python3 -m pytest -q
```

`AGENTS.md` チェック用スクリプトが存在する場合は次も実行します。

```bash
bash toolbox/skills/bootstrap-repository/scripts/check-agents-md.sh AGENTS.md
```

## 安全メモ

- `--dry-run` で差分を確認してから `~/.codex` を置換する。
- 認証情報や履歴は置換対象にしない。
- 既存の `~/.codex` は原則 `--safe`、バックアップ不要を明確に理解している場合だけ `--force` を使う。
- 初期状態へ戻す場合も、先に `apply --toolbox toolbox --dry-run` で確認する。
