#!/bin/bash
# Audit Merge Test - 一時ブランチで複数 Feature ブランチを merge しテストを実行
# Usage: audit-merge-test.sh <base_branch> <test_command> <lint_command> <feature_branch...>
#
# Audit Agent の Step 1（統合テスト）で使用。
# 一時ブランチ上で全 Feature ブランチを merge し、テスト・lint を実行する。
# 結果を JSON で stdout に出力し、一時ブランチは必ずクリーンアップする。
#
# 例:
#   audit-merge-test.sh integration/ec-service "npm test" "npm run lint" \
#     worktree-bright-fox worktree-swift-owl worktree-calm-bear
#
# 出力: JSON（stdout）

set -euo pipefail

# カラー出力（stderr のみ）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[AUDIT]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[AUDIT]${NC} $1" >&2; }
error() { echo -e "${RED}[AUDIT]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 4 ]]; then
    echo "Usage: $0 <base_branch> <test_command> <lint_command> <feature_branch...>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  base_branch      Base branch to merge into (e.g., integration/ec-service)" >&2
    echo "  test_command      Test command to run (e.g., \"npm test\")" >&2
    echo "  lint_command      Lint command to run (e.g., \"npm run lint\")" >&2
    echo "  feature_branch... Feature branches to merge (one or more)" >&2
    echo "" >&2
    echo "Output: JSON to stdout" >&2
    exit 1
fi

BASE_BRANCH="$1"
TEST_COMMAND="$2"
LINT_COMMAND="$3"
shift 3
FEATURE_BRANCHES=("$@")

# ============================================================================
# 事前チェック
# ============================================================================

# Git リポジトリ内か確認
if ! git rev-parse --git-dir &>/dev/null; then
    error "Not a git repository"
    exit 1
fi

# uncommitted changes があればエラー
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    error "Uncommitted changes detected. Commit or stash before running audit."
    exit 1
fi

# base ブランチの存在確認
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    error "Base branch not found: $BASE_BRANCH"
    exit 1
fi

# ============================================================================
# 状態保存
# ============================================================================
ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse HEAD)
TEMP_BRANCH="audit/merge-test-$(date +%s)"

info "Original branch: $ORIGINAL_BRANCH"
info "Temp branch: $TEMP_BRANCH"

# ============================================================================
# 結果格納用変数
# ============================================================================
MERGE_RESULT="success"
CONFLICTS_JSON="[]"
TEST_RESULT="skipped"
TEST_OUTPUT=""
LINT_RESULT="skipped"
LINT_OUTPUT=""

# ============================================================================
# クリーンアップ（trap）
# ============================================================================
cleanup() {
    info "Cleaning up..."

    # merge 中の場合は abort
    git merge --abort &>/dev/null || true

    # 元のブランチに戻る
    git checkout "$ORIGINAL_BRANCH" &>/dev/null || true

    # 一時ブランチを削除
    if git rev-parse --verify "$TEMP_BRANCH" &>/dev/null; then
        git branch -D "$TEMP_BRANCH" &>/dev/null || true
        info "Deleted temp branch: $TEMP_BRANCH"
    fi
}

trap cleanup EXIT INT TERM

# ============================================================================
# 一時ブランチ作成
# ============================================================================
info "Creating temp branch from $BASE_BRANCH..."
git checkout -b "$TEMP_BRANCH" "$BASE_BRANCH" &>/dev/null
if [[ $? -ne 0 ]]; then
    error "Failed to create temp branch from $BASE_BRANCH"
    exit 1
fi

# ============================================================================
# 各 Feature ブランチを順次 merge
# ============================================================================
CONFLICT_ENTRIES=()

for feature in "${FEATURE_BRANCHES[@]}"; do
    info "Merging feature: $feature"

    # feature ブランチの存在確認
    if ! git rev-parse --verify "$feature" &>/dev/null; then
        warn "Feature branch not found: $feature (skipping)"
        MERGE_RESULT="conflict"
        CONFLICT_ENTRIES+=("{\"feature\":\"$feature\",\"files\":[\"branch not found\"]}")
        continue
    fi

    # merge 実行
    set +e
    MERGE_OUTPUT=$(git merge --no-ff "$feature" -m "audit: merge $feature" 2>&1)
    MERGE_EXIT=$?
    set -e

    if [[ $MERGE_EXIT -ne 0 ]]; then
        # コンフリクトファイルを取得
        CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || echo "")

        if [[ -n "$CONFLICT_FILES" ]]; then
            warn "Conflict detected in: $feature"
            MERGE_RESULT="conflict"

            # JSON 配列用にファイルリストを整形
            FILES_JSON=$(echo "$CONFLICT_FILES" | jq -R -s 'split("\n") | map(select(length > 0))')
            CONFLICT_ENTRIES+=("{\"feature\":\"$feature\",\"files\":$FILES_JSON}")

            # merge を中止して次のブランチへ進むため、一時ブランチをリセット
            git merge --abort &>/dev/null || true
        else
            warn "Merge failed for: $feature (non-conflict error)"
            MERGE_RESULT="conflict"
            CONFLICT_ENTRIES+=("{\"feature\":\"$feature\",\"files\":[\"merge failed\"]}")
            git merge --abort &>/dev/null || true
        fi
    else
        info "Successfully merged: $feature"
    fi
done

# conflicts 配列を JSON に変換
if [[ ${#CONFLICT_ENTRIES[@]} -gt 0 ]]; then
    CONFLICTS_JSON=$(printf '%s\n' "${CONFLICT_ENTRIES[@]}" | jq -s '.')
else
    CONFLICTS_JSON="[]"
fi

# ============================================================================
# テスト・lint 実行（全 merge 成功時のみ）
# ============================================================================
if [[ "$MERGE_RESULT" == "success" ]]; then
    # テスト実行
    if [[ -n "$TEST_COMMAND" ]]; then
        info "Running tests: $TEST_COMMAND"
        set +e
        TEST_OUTPUT=$(eval "$TEST_COMMAND" 2>&1)
        TEST_EXIT=$?
        set -e

        if [[ $TEST_EXIT -eq 0 ]]; then
            TEST_RESULT="pass"
            info "Tests passed"
        else
            TEST_RESULT="fail"
            warn "Tests failed (exit: $TEST_EXIT)"
        fi
    fi

    # lint 実行
    if [[ -n "$LINT_COMMAND" ]]; then
        info "Running lint: $LINT_COMMAND"
        set +e
        LINT_OUTPUT=$(eval "$LINT_COMMAND" 2>&1)
        LINT_EXIT=$?
        set -e

        if [[ $LINT_EXIT -eq 0 ]]; then
            LINT_RESULT="pass"
            info "Lint passed"
        else
            LINT_RESULT="fail"
            warn "Lint failed (exit: $LINT_EXIT)"
        fi
    fi
else
    info "Skipping tests/lint due to merge conflicts"
fi

# ============================================================================
# 結果を JSON で stdout に出力
# ============================================================================

# テスト/lint 出力を JSON-safe にエスケープ
TEST_OUTPUT_ESCAPED=$(echo "$TEST_OUTPUT" | jq -R -s '.')
LINT_OUTPUT_ESCAPED=$(echo "$LINT_OUTPUT" | jq -R -s '.')

cat <<EOF
{
  "merge_result": "$MERGE_RESULT",
  "conflicts": $CONFLICTS_JSON,
  "test_result": "$TEST_RESULT",
  "test_output": $TEST_OUTPUT_ESCAPED,
  "lint_result": "$LINT_RESULT",
  "lint_output": $LINT_OUTPUT_ESCAPED
}
EOF

# cleanup は trap で自動実行される
info "Audit merge test completed"
