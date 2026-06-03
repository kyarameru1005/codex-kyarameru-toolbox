# kyarameru-tool-box

Codex の設定一式を toolbox として管理し、必要な toolbox だけを `~/.codex` へ安全に適用するためのリポジトリです。

認証情報、履歴、ログ、セッション、DB、キャッシュなどの実行時データは扱いません。
このリポジトリで配布するのは、再利用できる設定ファイルと設定ディレクトリだけです。

## Toolbox

- `toolbox/`: 初期状態へ戻すための最小 toolbox。
- `toolbox-greece/`: 設定済み toolbox 第1号。Zeus などの役割別エージェントと作業スキルを含みます。
- `toolbox-名前/`: 今後追加する配布用 toolbox。用途やテーマごとに増やします。

## まず使う

1. 現在の状態を確認します。

```bash
python3 scripts/toolbox-manager.py status
```

2. `toolbox-greece/` を適用した場合の変更内容を確認します。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --dry-run
```

3. 問題なければ、バックアップ付きで `~/.codex` へ適用します。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
```

4. 初期状態へ戻したい場合も、先に dry-run します。

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox --dry-run
python3 scripts/toolbox-manager.py apply --toolbox toolbox --safe
```

詳しい導入手順は [Getting Started](docs/distribution/getting-started.md) を参照してください。

## できること

- toolbox を `~/.codex` へ安全に適用する。
- 適用前に `--dry-run` で変更予定を確認する。
- `--safe` で既存設定をバックアップしてから置換する。
- `toolbox/` から新しい `toolbox-名前/` を作る。
- 適用済みの管理対象を `~/.codex/.kyarameru-tool-box-manifest.json` に記録する。
- Rust 製 `kytask` で、人間主導の作業計画と Codex 支援内容をローカル管理する。

## コマンド

### kytask

```bash
cargo install --path crates/kyarameru-task
kytask start "ハーネス改善" \
  --goal "ユーザー主導で作業計画を進められる状態にする" \
  --user-action "優先順位を決める" \
  --codex-action "選択肢と差分を用意する"
kytask plan
kytask note --kind decision "repo ローカル状態で管理する"
kytask check 1
kytask finish --verification "cargo test: passed"
```

`kytask` は、長い Codex 作業を再開しやすくするためのタスク管理コマンドです。
計画はユーザーを主軸にし、`user`, `codex`, `shared` の責務を分けて記録します。
デフォルトの保存先は `.git/info/kyarameru-task/state.json` で、Git の差分には出ません。

### status

```bash
python3 scripts/toolbox-manager.py status [--toolbox toolbox] [--codex-home ~/.codex]
```

指定した toolbox と `~/.codex` の管理対象を比較し、`current`, `different`, `missing` を表示します。

### apply

```bash
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --dry-run
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --safe
python3 scripts/toolbox-manager.py apply --toolbox toolbox-greece --force
```

指定した toolbox を `~/.codex` へ置換します。

- `--dry-run`: 変更予定だけを表示する。
- `--safe`: バックアップ付きで置換する。
- `--force`: バックアップなしで置換する。

通常は `--dry-run` のあとに `--safe` を使ってください。
`--force` はバックアップ不要と判断できる場合だけ使います。

### copy

```bash
python3 scripts/toolbox-manager.py copy [--source toolbox] [--name greece] [--dry-run]
```

`--source` で指定した toolbox を、`--name` で指定した `toolbox-名前/` へ複製します。
認証情報、履歴、DB、ログ、セッション、キャッシュなどの除外対象は複製しません。

## 置換対象

`apply` が `~/.codex` で置き換える対象は次に限定します。
空ディレクトリ保持用の `.gitkeep` は置換対象に含めません。

- `config.toml`
- `AGENTS.md`
- `skills/`
- `agents/`
- `hooks/`
- `prompts/`
- `plugins/`
- `mcp/`
- `memories/`

## 置換しないもの

次のファイルやディレクトリは `~/.codex` で置き換えません。

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

- `toolbox/`: 初期状態へ戻すための Codex 設定原本。
- `toolbox-greece/`: 配布用 toolbox 第1号。
- `crates/`: 配布用 Rust コマンド。
- `scripts/`: toolbox の複製、適用、確認を行うスクリプト。
- `tests/`: Python スクリプトの単体テスト。
- `docs/distribution/`: 配布用の運用文書。
- `docs/private/`: 個人研究用のローカル文書。Git では追跡しません。

詳細は [Repository Layout](docs/distribution/repository-layout.md) を参照してください。

## 開発と検証

開発依存は初回のみ入れます。

```bash
python3 -m pip install -e '.[dev]'
```

テストを実行します。

```bash
cargo test
python3 -m pytest -q
```

`AGENTS.md` チェック用スクリプトが存在する場合は次も実行します。

```bash
bash toolbox/skills/bootstrap-repository/scripts/check-agents-md.sh AGENTS.md
```

## 安全メモ

- 実運用の `~/.codex` へ適用する前に、必ず `--dry-run` で確認する。
- 既存の `~/.codex` を変更する場合は、原則 `--safe` を使う。
- 認証情報や履歴を toolbox に含めない。
- 個人研究用の文書は `docs/private/` に置き、配布対象にしない。
