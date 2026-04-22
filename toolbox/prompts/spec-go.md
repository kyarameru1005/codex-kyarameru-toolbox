---
name: spec-go
description: 仕様駆動開発の自律実装ループ。Phase 1-7 を停止なく実行する。
---

# /spec-go: 自律実装ループコマンド

## 概要

`/spec-go` を実行すると、現在のワークスペースにある Feature の仕様に従い、
Phase 1 から Phase 7 まで自律的に実装を進めます。

## 環境変数の設定

```bash
SKILL_DIR="$HOME/.agents/skills/spec/scripts"
TASK_MGR="$HOME/.codex/scripts/task-manager.sh"
HOOK_RUNNER="$HOME/.codex/hooks/hook-runner.sh"
CONFIG_FILE="specs/templates/config.yaml"
[ -f "$CONFIG_FILE" ] || CONFIG_FILE="$HOME/.agents/skills/spec/templates/config.yaml"

# 現在の feature ディレクトリを特定（tasks.md が存在するもの）
FEATURE_DIR=""
for dir in specs/features/*/; do
  if [ -f "${dir}tasks.md" ]; then
    FEATURE_DIR="$dir"
    break
  fi
done
FEATURE_NAME=$(basename "$FEATURE_DIR")
```

## 前提確認

```bash
echo "=== /spec-go 前提確認 ==="

# Feature ディレクトリの確認
if [ -z "$FEATURE_DIR" ] || [ ! -d "$FEATURE_DIR" ]; then
  echo "[ERROR] specs/features/ に tasks.md を持つ feature が見つかりません"
  echo "  → /spec-plan <feature> <requirements> を先に実行してください"
  exit 1
fi
echo "[OK] Feature: $FEATURE_NAME ($FEATURE_DIR)"

# tasks.md の確認
if [ ! -f "${FEATURE_DIR}tasks.md" ]; then
  echo "[ERROR] tasks.md not found: ${FEATURE_DIR}tasks.md"
  exit 1
fi
echo "[OK] tasks.md found"

# task-manager.sh の確認（任意）
if [ -f "$TASK_MGR" ]; then
  echo "[OK] task-manager.sh found: $TASK_MGR"
  bash "$TASK_MGR" list
else
  echo "[WARN] task-manager.sh not found - フォールバックモードで実行"
fi
```

## Phase ループ（Phase 1 から 7 まで順番に実行）

### Phase 1: 検証スクリプト作成（RED）

```bash
PHASE=1
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: 検証スクリプト作成（RED）"
echo "========================================"

# hook: pre
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"

# task-manager で in_progress に更新
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

# 実装: tests/test-$FEATURE_NAME.sh を作成する
TEST_FILE="tests/test-${FEATURE_NAME}.sh"
echo "[実装] $TEST_FILE を作成"
# → テストスクリプトを作成（実装対象ファイルの存在・内容を検証する）
# → 作成後に実行して RED 状態を確認

# 検証
if [ -f "$TEST_FILE" ]; then
  bash "$TEST_FILE" 2>&1 | tail -5 || true
  echo "[OK] Phase ${PHASE} テストスクリプト作成完了"
else
  echo "[ERROR] $TEST_FILE が作成されていません"
  echo "  → テストファイルを作成して再試行してください"
  exit 1
fi

# task-manager で completed に更新
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed

# hook: post
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 2: コア実装

```bash
PHASE=2
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: コア実装"
echo "========================================"

# hook: pre
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"

# task-manager で in_progress に更新
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

# tasks.md から Phase 2 の実装タスクを読み取り実行
# design.md のファイル構成・データフローに従って実装する
echo "[実装] Phase 2 コア実装を開始"
# → design.md を読み込む
DESIGN_FILE="${FEATURE_DIR}design.md"
[ -f "$DESIGN_FILE" ] && echo "[INFO] design.md を参照: $DESIGN_FILE"

# 検証: テスト実行
TEST_FILE="tests/test-${FEATURE_NAME}.sh"
if [ -f "$TEST_FILE" ]; then
  set +e
  bash "$TEST_FILE" 2>&1
  TEST_EXIT=$?
  set -e
  if [ "$TEST_EXIT" -ne 0 ]; then
    echo "[WARN] テスト失敗 - 修正して再試行します"
    # エラー修正ループ（最大3回）
  fi
fi

# task-manager で completed に更新
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed

# hook: post
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 3: 追加実装

```bash
PHASE=3
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: 追加実装"
echo "========================================"

[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

echo "[実装] Phase 3 追加実装を開始"
# tasks.md の Phase 3 タスクを順番に実行

# 検証: テスト実行（失敗時は修正して再試行）
TEST_FILE="tests/test-${FEATURE_NAME}.sh"
if [ -f "$TEST_FILE" ]; then
  set +e
  bash "$TEST_FILE" 2>&1
  TEST_EXIT=$?
  set -e
  if [ "$TEST_EXIT" -ne 0 ]; then
    echo "[WARN] Phase ${PHASE} テスト失敗 - 実装を修正して再試行"
  fi
fi

[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 4: 補助機能

```bash
PHASE=4
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: 補助機能実装"
echo "========================================"

[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

echo "[実装] Phase 4 補助機能を実装"
# tasks.md の Phase 4 タスクを順番に実行

[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 5: 統合テスト（GREEN）

```bash
PHASE=5
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: 統合テスト（GREEN）"
echo "========================================"

[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

echo "[検証] 全テストを実行して GREEN 状態を確認"
TEST_FILE="tests/test-${FEATURE_NAME}.sh"
if [ -f "$TEST_FILE" ]; then
  set +e
  bash "$TEST_FILE" 2>&1
  TEST_EXIT=$?
  set -e
  if [ "$TEST_EXIT" -ne 0 ]; then
    echo "[ERROR] Phase 5 統合テスト失敗"
    echo "  → 失敗したテストを修正してから再実行してください"
    echo "  停止条件チェック:"
    echo "    - CRITICAL セキュリティ問題がある場合は停止"
    echo "    - 既存テストを破壊している場合は停止（修正不可な場合）"
    echo "    - 外部認証情報が不明な場合は停止してユーザーに確認"
    exit 1
  fi
  echo "[OK] 全テスト GREEN"
fi

[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 6: ドキュメント更新

```bash
PHASE=6
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: ドキュメント更新"
echo "========================================"

[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

echo "[実装] ドキュメントを更新"
# AGENTS.md にカスタムコマンド一覧を追加
# 各実装ファイルの冒頭コメントを整備

[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

### Phase 7: 最終検証とコミット

```bash
PHASE=7
TASK_ID="${FEATURE_NAME}-phase${PHASE}"
echo ""
echo "========================================"
echo "Phase ${PHASE}: 最終検証とコミット"
echo "========================================"

[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run pre \
  "$HOME/.codex/hooks/spec-pre-hook.sh" "Phase${PHASE}"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status in_progress

echo "[検証] 全テスト最終実行"
for test_file in tests/test-*.sh; do
  [ -f "$test_file" ] && bash "$test_file" 2>&1
done

echo "[完了] verification-matrix を確認"
# verification-matrix.md の全チェックポイントが PASS であることを確認

[ -f "$TASK_MGR" ] && bash "$TASK_MGR" update "$TASK_ID" status completed
[ -f "$HOOK_RUNNER" ] && bash "$HOOK_RUNNER" run post \
  "$HOME/.codex/hooks/spec-post-hook.sh" "Phase${PHASE}"
```

## 全 Phase 完了後の完了サマリ

```bash
echo ""
echo "========================================"
echo "=== /spec-go 完了サマリ ==="
echo "========================================"
echo "Feature: $FEATURE_NAME"
echo "完了 Phase: 1-7 (全7フェーズ)"
echo ""
echo "タスク状況:"
[ -f "$TASK_MGR" ] && bash "$TASK_MGR" list

echo ""
echo "次のステップ:"
echo "  /spec-complete を実行して PR を作成する"
echo "========================================"
```

## エラー時の対処方針

各 Phase でエラーが発生した場合:
1. エラーメッセージを確認する
2. 問題を修正する
3. 同じ Phase を再実行する（task-manager.sh update <id> status pending で戻す）
4. 停止条件に該当する場合はユーザーに報告して指示を待つ

### 停止条件

以下の場合は自律実行を停止し、ユーザーに確認する:
- CRITICAL セキュリティ問題（認証情報の露出、脆弱性の導入）
- 既存テストの破壊（修正不可能な場合）
- 外部サービスの認証情報が不明な場合
