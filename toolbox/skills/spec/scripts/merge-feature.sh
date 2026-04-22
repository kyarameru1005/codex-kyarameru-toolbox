#!/bin/bash
# Merge Feature - Feature ブランチを integration ブランチに merge する
# Usage: merge-feature.sh <integration_branch> <feature_branch> <feature_name>
#
# PM Agent から呼び出される。
# --no-ff merge を行い、コンフリクト時は merge --abort して exit 2 を返す。
#
# 例:
#   merge-feature.sh integration/ec-service worktree-bright-fox auth
#
# 出力:
#   stdout: merge コミットの SHA（成功時）
#   stderr: エラーメッセージ or コンフリクト情報
#   exit 0: 成功
#   exit 1: 一般エラー
#   exit 2: コンフリクト（自動解決不可）

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[MERGE]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[MERGE]${NC} $1" >&2; }
error() { echo -e "${RED}[MERGE]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <integration_branch> <feature_branch> <feature_name>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  integration_branch  Target integration branch (e.g., integration/ec-service)" >&2
    echo "  feature_branch      Feature branch to merge (e.g., worktree-bright-fox)" >&2
    echo "  feature_name        Feature name for commit message (e.g., auth)" >&2
    echo "" >&2
    echo "Exit codes:" >&2
    echo "  0  Success" >&2
    echo "  1  General error" >&2
    echo "  2  Conflict (auto-resolve failed)" >&2
    exit 1
fi

INTEGRATION_BRANCH="$1"
FEATURE_BRANCH="$2"
FEATURE_NAME="$3"

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
    error "Uncommitted changes detected. Commit or stash before merging."
    exit 1
fi

# integration ブランチの存在確認
if ! git rev-parse --verify "$INTEGRATION_BRANCH" &>/dev/null; then
    error "Integration branch not found: $INTEGRATION_BRANCH"
    exit 1
fi

# feature ブランチの存在確認
if ! git rev-parse --verify "$FEATURE_BRANCH" &>/dev/null; then
    error "Feature branch not found: $FEATURE_BRANCH"
    exit 1
fi

# ============================================================================
# 元のブランチを記録
# ============================================================================
ORIGINAL_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse HEAD)
info "Current branch: $ORIGINAL_BRANCH"

# 元のブランチに戻る関数
restore_branch() {
    if [[ "$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse HEAD)" != "$ORIGINAL_BRANCH" ]]; then
        git checkout "$ORIGINAL_BRANCH" &>/dev/null || true
    fi
}

# ============================================================================
# integration ブランチに checkout
# ============================================================================
info "Checking out integration branch: $INTEGRATION_BRANCH"
if ! git checkout "$INTEGRATION_BRANCH" &>/dev/null; then
    error "Failed to checkout integration branch: $INTEGRATION_BRANCH"
    exit 1
fi

# ============================================================================
# merge 実行
# ============================================================================
info "Merging $FEATURE_BRANCH into $INTEGRATION_BRANCH..."

# set -e を一時的に無効化して merge の結果を確認
set +e
git merge --no-ff "$FEATURE_BRANCH" -m "merge: integrate $FEATURE_NAME" 2>/dev/null
MERGE_EXIT=$?
set -e

if [[ $MERGE_EXIT -ne 0 ]]; then
    # コンフリクト検出
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null)

    if [[ -n "$CONFLICT_FILES" ]]; then
        error "Conflict detected while merging $FEATURE_BRANCH"
        error "Conflicting files:"
        echo "$CONFLICT_FILES" | while read -r file; do
            echo "  - $file" >&2
        done

        # merge を中止
        git merge --abort &>/dev/null || true
        restore_branch
        exit 2
    else
        # コンフリクト以外の merge エラー
        error "Merge failed with exit code: $MERGE_EXIT"
        git merge --abort &>/dev/null || true
        restore_branch
        exit 1
    fi
fi

# ============================================================================
# 成功: merge コミットの SHA を出力
# ============================================================================
MERGE_SHA=$(git rev-parse HEAD)
info "Merge successful: $MERGE_SHA"

# 元のブランチに戻る
restore_branch

# stdout に SHA を出力
echo "$MERGE_SHA"
exit 0
