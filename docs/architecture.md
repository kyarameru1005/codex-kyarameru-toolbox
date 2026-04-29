# Architecture

このリポジトリは、配備資材と運用文書を分けて管理する。

## 主要レイヤ

- `toolbox/`: `~/.codex` へ配備する実体。
- `scripts/`: インストール、検証、PR 補助の運用スクリプト。
- `tests/`: Python ベースの自動検証。
- `docs/`: 運用・研究・仕様の文書群。

## 役割分担

- `AGENTS.md` は判断基準と禁止事項だけを持つ。
- 詳細手順、背景説明、構造説明は `docs/` に分離する。
- `README.md` は実行者向けの入口に留め、長い方針説明は `docs/` へ委譲する。

## 既存文書との対応

- 構造説明: `docs/repository-layout.md`
- 研究計画: `docs/research.md`
- ハーネス仕様: `docs/harness-spec.md`
- PR テンプレート: `docs/pr-template.md`
- 作業台帳: `docs/task-list.md`

この分離により、運用ルール、実行手順、背景資料の責務を混同しない。
