# Agents Overview

## Purpose
このリポジトリは `toolbox/` を初期状態へ戻すための Codex 設定原本として管理し、`toolbox-greece/`, `toolbox-japan/` のような配布用 toolbox を安全に `~/.codex` へ置換できる状態を維持することを目的とする。

## Working Scope
- `toolbox/` は初期状態へ戻すための設定原本として扱う。
- `toolbox/` の初期中身は `config.toml`, `AGENTS.md` と空の設定ディレクトリ群とし、各ディレクトリの実ファイルは必要になるまで作成しない。
- `toolbox-greece/` は設定済み toolbox の第1号として扱う。
- `toolbox-名前/` は今後追加する配布用 toolbox として扱う。
- `scripts/` と `tests/` は設定の複製・置換・検証を支えるコードとして扱う。
- 実運用データは置換対象に含めない前提で扱う。

## Related Docs
- リポジトリ構造: `docs/distribution/repository-layout.md`
- 作業手順: `docs/distribution/agents/workflow.md`
- 編集と安全ルール: `docs/distribution/agents/rules.md`
- コマンドと検証: `docs/distribution/agents/validation.md`
