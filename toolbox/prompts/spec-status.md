---
name: spec-status
description: /spec ワークフローの現在状態を確認する。
---

# /spec-status: ワークフロー状態確認コマンド

## 概要

`/spec-status` を実行すると、現在の仕様駆動開発ワークフローの状態を表示します。

## 環境変数の設定

```bash
TASK_MGR="$HOME/.codex/scripts/task-manager.sh"
SKILL_DIR="$HOME/.agents/skills/spec/scripts"

# 現在の feature ディレクトリを特定
FEATURE_DIR=""
for dir in specs/features/*/; do
  if [ -f "${dir}tasks.md" ]; then
    FEATURE_DIR="$dir"
    break
  fi
done
FEATURE_NAME=$(basename "$FEATURE_DIR")
```

## 処理フロー

### Step 1: task-manager.sh でタスク状況を表示

```bash
echo "=== タスク状況 ==="
if [ -f "$TASK_MGR" ]; then
  bash "$TASK_MGR" list
else
  echo "[WARN] task-manager.sh not found: $TASK_MGR"
  echo "  → F3 (task-manager) をインストールしてください: ./install.sh install --codex"
fi
```

### Step 2: specs/features/ の現在の Feature 状態を表示

```bash
echo ""
echo "=== Feature 状態 ==="
if [ -n "$FEATURE_DIR" ] && [ -d "$FEATURE_DIR" ]; then
  echo "Feature: $FEATURE_NAME"
  echo "Directory: $FEATURE_DIR"
  echo ""
  echo "ファイル一覧:"
  for f in requirements.md design.md tasks.md test-spec.md arch-check.md; do
    if [ -f "${FEATURE_DIR}${f}" ]; then
      echo "  [OK] $f"
    else
      echo "  [--] $f (未作成)"
    fi
  done
else
  echo "[INFO] 現在アクティブな feature が見つかりません"
  echo "  → /spec-plan <feature> <requirements> を実行してください"
fi
```

### Step 3: Phase 進捗のサマリ

```bash
echo ""
echo "=== Phase 進捗 ==="
if [ -f "${FEATURE_DIR}tasks.md" ]; then
  TOTAL=$(grep -c '^\- \[' "${FEATURE_DIR}tasks.md" 2>/dev/null || echo 0)
  DONE=$(grep -c '^\- \[x\]' "${FEATURE_DIR}tasks.md" 2>/dev/null || echo 0)
  IN_PROGRESS=$(grep -c '^\- \[.\] Phase' "${FEATURE_DIR}tasks.md" 2>/dev/null || echo 0)
  echo "完了: ${DONE} / ${TOTAL} タスク"
else
  echo "[INFO] tasks.md が見つかりません"
fi

echo ""
echo "=== project-state.json ==="
if [ -f "specs/project-state.json" ]; then
  cat specs/project-state.json
elif command -v jq &>/dev/null && [ -f "project-state.json" ]; then
  jq . project-state.json
fi
```

### Step 4: 利用可能なコマンドを表示

```bash
echo ""
echo "=== 利用可能なコマンド ==="
echo "  /spec-plan  <feature> <requirements>  : 計画フェーズを開始"
echo "  /spec-go                               : 自律実装ループを開始"
echo "  /spec-status                           : 現在の状態を確認（このコマンド）"
echo "  /spec-verify                           : テスト・検証を実行"
echo "  /spec-complete                         : 実装完了処理"
```
