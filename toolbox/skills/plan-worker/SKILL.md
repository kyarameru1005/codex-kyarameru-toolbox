---
name: plan-worker
description: コードベース分析・要件整理・設計策定・タスク分解を別Claudeプロセスに委譲。
allowed-tools: Glob, Grep, Read, Write
user-invocable: true
---

# Plan Worker

コードベース分析・要件整理・設計策定・タスク分解を担当するワーカースキル。
`/spec plan` の設計フェーズでサブエージェントとして使用される。

## 役割

- コードベースを Glob/Grep/Read で調査し、設計方針を提案する
- requirements.md から design.md の骨格を生成する
- design.md + requirements.md から tasks.md（Phase 1-7）を生成する
- ファイルの編集・削除は行わない（Read/Write のみ）

## 使用ツール

| ツール | 用途 |
|--------|------|
| `Glob` | ファイルパターン検索 |
| `Grep` | コード内容検索 |
| `Read` | ファイル読み込み |
| `Write` | 成果物ファイルの書き出し |

## 入力形式

```
feature_dir: specs/features/<feature>/
task: design.md を生成する | tasks.md を生成する | コードベースを調査する
```

## 出力形式

指定された `feature_dir` に成果物ファイル（design.md / tasks.md）を書き出す。
完了後に `DONE: <成果物パス>` を出力する。
