---
name: spec-verify-matrix
description: ヒューリスティクスベースの検証マトリクス自動生成。requirements.md + design.md からSFDIPOT・データ型攻撃・操作ヒューリスティクスを適用し、verification-matrix.md を生成する。
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
user-invocable: false
---

# Spec Verify Matrix - ヒューリスティクスベース検証マトリクス生成

## 概要

requirements.md + design.md + test-spec.md を入力とし、体系的なヒューリスティクスを適用して `verification-matrix.md` を自動生成する。

## 使用方法

`/spec go` の Phase 7 で自動呼び出しされる。

## 生成フロー

1. 入力ファイル読み込み（requirements.md, design.md, test-spec.md）
2. config.yaml から project_type を判定（frontend/backend/fullstack/library/cli）
3. 共通ヒューリスティクス適用（SFDIPOT + データ型攻撃 + 操作ヒューリスティクス）
4. project_type に応じた専用ヒューリスティクス追加
5. verification-matrix.md を出力

## 出力形式

チェックリスト形式の verification-matrix.md を feature ディレクトリに出力。
