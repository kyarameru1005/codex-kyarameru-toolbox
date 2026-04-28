# Repository Layout

この文書は、リポジトリ内の主要ディレクトリの責務と Git 管理方針を定義する。

## 管理対象

- `scripts/`: インストール、検証、PR作成などの運用スクリプト。
- `docs/`: 仕様、研究計画、運用メモ、PRテンプレート、ハーネスレポート。
- `toolbox/skills/`: `~/.codex/skills` へ配備するスキル本体。
- `toolbox/agents/`: `~/.codex/agents` へ配備するエージェント定義。
- `toolbox/hooks/`: `~/.codex/hooks` へ配備するフック。
- `toolbox/prompts/`: `~/.codex/prompts` へ配備するプロンプト。
- `toolbox/harness/`: ハーネス設定、状態台帳、必要な空ディレクトリ維持ファイル。

## Git 管理しないもの

以下は生成物、外部取得キャッシュ、またはローカル実行時の作業資材として扱い、Git 管理しない。

- `toolbox/cache/`
- `toolbox/plugins/cache/`
- `toolbox/vendor_imports/`
- `toolbox/log/`
- `toolbox/sessions/`
- `toolbox/sqlite/`
- `toolbox/tmp/`
- `*.egg-info/`

`toolbox/harness/output/` は実行出力を置くが、空ディレクトリ維持のため `.gitkeep` のみ管理する。

## 変更時の確認

- 配備対象を増やした場合は `scripts/install.py` と `tests/test_install.py` を更新する。
- 必須ファイルや必須ディレクトリを増やした場合は `scripts/policy-check.sh` を更新する。
- ignore 対象を増やした場合は、必要に応じて追跡済みファイルを `git rm --cached` で外す。
