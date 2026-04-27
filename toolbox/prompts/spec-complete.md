---
name: spec-complete
description: 実装完了処理。SSOT 更新 → ユーザー確認 → PR 作成。
---

# /spec-complete: 実装完了処理コマンド

## 概要

`/spec-complete` を実行すると、仕様駆動開発の完了処理を行います。
全 Phase の確認 → SSOT 更新 → git コミット案内 → PR 作成まで誘導します。

## 環境変数の設定

```bash
TASK_MGR="$HOME/.codex/scripts/task-manager.sh"

# 現在の feature ディレクトリを特定
FEATURE_DIR=""
for dir in specs/features/*/; do
  if [ -f "${dir}tasks.md" ]; then
    FEATURE_DIR="$dir"
    break
  fi
done
FEATURE_NAME=$(basename "$FEATURE_DIR")
BRANCH_NAME="feat:codex-${FEATURE_NAME}_Phase7_complete"
```

## 処理フロー

### Step 1: 全 Phase 完了確認

```bash
echo "=== 全 Phase 完了確認 ==="
if [ -f "$TASK_MGR" ]; then
  echo "[task-manager.sh list]"
  bash "$TASK_MGR" list
  echo ""
  # 未完了タスクがある場合は警告
  PENDING=$(bash "$TASK_MGR" list 2>/dev/null | grep -c 'pending\|in_progress' || echo 0)
  if [ "$PENDING" -gt 0 ]; then
    echo "[WARN] 未完了タスクが ${PENDING} 件あります"
    echo "  → /spec-go を実行して実装を完了させてください"
    echo "  → または手動で各タスクを確認してください"
  else
    echo "[OK] 全タスク完了"
  fi
else
  echo "[WARN] task-manager.sh not found"
  echo "  → tasks.md を手動で確認してください: ${FEATURE_DIR}tasks.md"
fi
```

### Step 2: 全テストが PASS していることを確認

```bash
echo ""
echo "=== 最終テスト確認 ==="
ALL_PASS=true
for test_file in tests/test-*.sh; do
  if [ -f "$test_file" ]; then
    set +e
    bash "$test_file" 2>&1 | tail -3
    EXIT_CODE=$?
    set -e
    if [ "$EXIT_CODE" -ne 0 ]; then
      echo "[FAIL] $test_file"
      ALL_PASS=false
    else
      echo "[PASS] $test_file"
    fi
  fi
done

if [ "$ALL_PASS" = false ]; then
  echo "[ERROR] 一部のテストが FAIL しています"
  echo "  → /spec-verify で詳細を確認して修正してください"
fi
```

### Step 3: project-state.json の status を "done" に更新

```bash
echo ""
echo "=== project-state.json 更新 ==="
STATE_FILE="specs/project-state.json"
if [ -f "$STATE_FILE" ]; then
  if command -v jq &>/dev/null; then
    # jq で status を "done" に更新
    jq --arg feature "$FEATURE_NAME" \
       '.features[$feature].status = "done" | .features[$feature].completed_at = now | todate' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "[OK] $STATE_FILE を更新: status=done"
  else
    echo "[INFO] jq not found - 手動で以下を実行してください:"
    echo "  vi $STATE_FILE"
    echo "  → features.$FEATURE_NAME.status を \"done\" に変更"
  fi
else
  echo "[INFO] $STATE_FILE not found - スキップ"
fi
```

### Step 4: git add + git commit の手順案内

```bash
echo ""
echo "=== git コミット手順 ==="
echo ""
echo "以下のコマンドでコミットしてください:"
echo ""
echo "  # 変更ファイルを確認"
echo "  git status"
echo ""
echo "  # ステージング"
echo "  git add .codex/prompts/ tests/ specs/"
echo ""
echo "  # コミット"
echo "  git commit -m \"feat:codex-${FEATURE_NAME}_Phase7_complete\""
echo ""
echo "  # プッシュ"
echo "  git push origin HEAD"
echo ""
echo "  # PR 作成（GitHub CLI）"
echo "  gh pr create \\"
echo "    --title \"feat: ${FEATURE_NAME} 実装完了\" \\"
echo "    --body \"仕様駆動開発 ${FEATURE_NAME} の全 Phase 実装完了\""
```

### Step 5: 完了確認メッセージ

```bash
echo ""
echo "========================================"
echo "=== /spec-complete 完了 ==="
echo "========================================"
echo "Feature: $FEATURE_NAME"
echo ""
echo "完了した処理:"
echo "  [OK] 全 Phase 完了確認"
echo "  [OK] 全テスト PASS 確認"
echo "  [OK] project-state.json 更新（status=done）"
echo "  [OK] git コミット手順案内"
echo ""
echo "残りの手順:"
echo "  1. git add + git commit でコミットする"
echo "  2. git push でリモートにプッシュする"
echo "  3. gh pr create で PR を作成する"
echo "========================================"
```
