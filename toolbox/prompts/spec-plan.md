---
name: spec-plan
description: 仕様駆動開発の計画フェーズ。引数なしで起動し、対話で要件を確認する。
---

# /spec-plan: 仕様計画コマンド

まず以下をユーザーに聞く:

> 何を実装・調査したいですか？（例: "認証機能を追加したい" / "コードベースと仕様の差異を調べたい"）

ユーザーの回答を受け取ってから以下のフローを実行する。

## 処理フロー

### Step 1: 要件の理解

ユーザーの入力を解析し、以下を把握する:
- 何を作りたいのか / 何を調査したいのか
- 既存コードベースとの関係
- 期待する成果物

不明点があればユーザーに質問する。

### Step 2: コードベース調査

`specs/features/` ディレクトリや関連ファイルを確認し、現状を把握する:

```bash
ls specs/ 2>/dev/null || echo "specs/ ディレクトリなし"
ls specs/features/ 2>/dev/null || echo "features/ なし"
```

### Step 3: Feature 名の決定

ユーザー入力から Feature 名を決定する（スネークケース、例: `my-feature`）。
既存の Feature がある場合はそれを使用する。

### Step 4: Feature ディレクトリの準備

```bash
FEATURE_NAME="<Step 3 で決定した名前>"
FEATURE_DIR="specs/features/${FEATURE_NAME}"
mkdir -p "$FEATURE_DIR"
```

### Step 5: requirements.md の生成

ユーザーの入力をもとに `specs/features/$FEATURE_NAME/requirements.md` を生成する。
以下の項目を含める:
- ## 概要
- ## 受入条件（AC-1, AC-2, ...）
- ## 変更対象ファイル
- ## 依存関係

### Step 6: タスク登録

`~/.codex/scripts/task-manager.sh` があればタスクを登録する:

```bash
TASK_MGR="$HOME/.codex/scripts/task-manager.sh"
if [ -f "$TASK_MGR" ]; then
  bash "$TASK_MGR" create "${FEATURE_NAME}-phase1" "Phase 1: テスト作成（RED）" ""
  bash "$TASK_MGR" create "${FEATURE_NAME}-phase2" "Phase 2: 実装" ""
  bash "$TASK_MGR" create "${FEATURE_NAME}-phase7" "Phase 7: 最終検証" ""
  bash "$TASK_MGR" list
fi
```

### Step 7: 完了報告

```
=== /spec-plan 完了 ===
Feature: $FEATURE_NAME
次: /spec-go で実装開始
```
