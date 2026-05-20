# Agents Overview

## Purpose
このリポジトリは `toolbox/` を Codex 設定の原本として管理し、必要に応じて `toolbox-greece/`, `toolbox-japan/` のような検証用コピーを作成しつつ、安全に `~/.codex` へ適用できる状態を維持することを目的とする。

## Working Scope
- `toolbox/` は設定原本として扱う。
- `toolbox/` の初期中身は `config.toml`, `AGENTS.md` と空の設定ディレクトリ群とし、各ディレクトリの実ファイルは必要になるまで作成しない。
- `toolbox-名前/` は原本から複製した検証用コピーとして扱う。
- `scripts/` と `tests/` は設定の複製・適用・検証を支えるコードとして扱う。
- 実運用データは適用対象に含めない前提で扱う。

## Related Docs
- リポジトリ構造: `docs/repository-layout.md`
- 作業手順: `docs/agents/workflow.md`
- 編集と安全ルール: `docs/agents/rules.md`
- コマンドと検証: `docs/agents/validation.md`
