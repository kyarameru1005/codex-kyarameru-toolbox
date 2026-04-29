---
name: bootstrap-repository
description: 新規または既存リポジトリに、AI コーディングエージェントが使いやすい標準構造を導入するための初期構築・整備スキル
---

# bootstrap-repository

## 目的

この Skill の目的は、新規または既存リポジトリに対して、AI コーディングエージェントを使いやすい標準構造を導入することです。

新規リポジトリ作成時にも、既存リポジトリ整備時にも使います。

`AGENTS.md` に長い初期構築手順を書かず、初期構築・整備手順は Skill として分離します。

## 推奨トリガー

- 新規リポジトリ作成直後
- 既存リポジトリの構成整理
- `AGENTS.md` の整備
- `docs/` `ai_log/` `tests/` の作成・整理

## 出力

最小構成:

```text
repository-root/
├── AGENTS.md
├── README.md
├── docs/
│   ├── overview.md
│   ├── requirements.md
│   ├── architecture.md
│   └── understanding-check.md
├── ai_log/
│   └── README.md
├── tests/
│   └── README.md
└── .gitignore
```

追加候補の構成:

```text
repository-root/
├── scripts/
├── .github/
│   ├── workflows/
│   └── pull_request_template.md
└── .codex/
    └── config.toml
```

## Procedure

1. 既存ファイルとディレクトリを確認する。
2. 言語、フレームワーク、テストコマンドを確認する。
3. 既存ファイルを無断で上書きしない。
4. `AGENTS.md` は短く保つ。
5. 詳細な説明やテンプレートは `docs/` に分離する。
6. `ai_log/` は AI 作業ログや実験ログ用にする。
7. `tests/` は検証用の置き場にする。
8. 実行できない CI や推測のコマンドは作らない。
9. AI が変更を行う場合は、`main` に直接作業せず、必ず作業ブランチを分ける。
10. PR 作成や push を伴う仕上げ作業は、この Skill で続行せず、`git-pr-worker` を使う。

## Rules

- 最小変更を優先する。
- 依存関係を追加しない。
- `.env` や秘密情報を変更しない。
- フレームワーク固有のコマンドを推測で書かない。
- AI の実装・整理作業は、必ず専用ブランチで行う。
- PR 作成、commit、push、CI 確認は `git-pr-worker` に分離する。
- 研究プロジェクトでは、比較可能性・再現性・実力維持を重視する。

## Done when

- `SKILL.md` が作成されている。
- リポジトリ標準構造が説明されている。
- `AGENTS.md` と `docs/` の役割分担が説明されている。
- `ai_log/` と `tests/` の目的が説明されている。
- 作業後の報告形式がある。

## Report format

作業後は以下の形式で報告してください。

```md
## Summary

## Created files

## Updated files

## Skipped files

## Validation

## Human review points

## Next actions
```
