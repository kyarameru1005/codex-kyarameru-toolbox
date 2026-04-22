#!/bin/bash
# Spec Setup Hooks - Git hooks をセットアップ
# Usage: setup-hooks.sh
#
# 作成されるもの:
# - .github/hooks/commit-msg (コミットメッセージ検証)
# - git config core.hooksPath 設定

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================================
# 1. ディレクトリ作成
# ============================================================================
create_hooks_dir() {
    info "Creating .github/hooks directory..."
    mkdir -p .github/hooks
}

# ============================================================================
# 2. commit-msg フック作成
# ============================================================================
create_commit_msg_hook() {
    local HOOK_FILE=".github/hooks/commit-msg"

    if [[ -f "$HOOK_FILE" ]]; then
        warn "  $HOOK_FILE already exists, skipping"
        return
    fi

    info "Creating commit-msg hook..."

    cat > "$HOOK_FILE" << 'HOOK_EOF'
#!/bin/bash
# commit-msg hook: コミットメッセージのフォーマット検証
# Spec-Driven Development 用
#
# 形式:
#   <type>:<番号>_<サマリ>     (例: feat:123_ユーザー認証追加)
#   <type>:<番号>_Phase<N>_<サマリ>  (例: feat:123_Phase1_Domain層実装)
#   <type>:<サマリ>            (番号なしの場合)

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# 最初の行のみ検証（タイトル）
TITLE=$(echo "$COMMIT_MSG" | head -1)

# 許可されるtype
TYPES="feat|fix|refactor|perf|test|docs|chore|build|ci|revert"

# マージコミットはスキップ
if echo "$TITLE" | grep -qE "^Merge (pull request|branch)"; then
    exit 0
fi

# 基本形式チェック
# Pattern 1: <type>:<番号>_<サマリ> (例: feat:123_機能追加)
# Pattern 2: <type>:<番号>_Phase<N>_<サマリ> (例: feat:123_Phase1_Domain層)
# Pattern 3: <type>:<サマリ> (番号なし)
if ! echo "$TITLE" | grep -qE "^($TYPES):[0-9]+_.+$" && \
   ! echo "$TITLE" | grep -qE "^($TYPES):[^0-9:].+$"; then
    echo "=========================================="
    echo "コミットメッセージがテンプレートに従っていません"
    echo "=========================================="
    echo ""
    echo "現在のタイトル: $TITLE"
    echo ""
    echo "正しい形式:"
    echo "  <type>:<番号>_<サマリ>"
    echo "  <type>:<番号>_Phase<N>_<サマリ>  (Phase コミット)"
    echo "  <type>:<サマリ>                   (番号なし)"
    echo ""
    echo "type: feat|fix|refactor|perf|test|docs|chore|build|ci|revert"
    echo ""
    echo "例:"
    echo "  feat:123_ユーザー認証追加"
    echo "  feat:123_Phase1_Domain層実装"
    echo "  fix:45_バリデーションエラー修正"
    echo "  docs:README更新"
    echo "=========================================="
    exit 1
fi

# 禁止文字チェック（空白、括弧、句読点）
if echo "$TITLE" | grep -q ' ' || \
   echo "$TITLE" | grep -qE '\(' || echo "$TITLE" | grep -qE '\)' || \
   echo "$TITLE" | grep -qE '\[' || echo "$TITLE" | grep -qE '\]' || \
   echo "$TITLE" | grep -q '「' || echo "$TITLE" | grep -q '」' || \
   echo "$TITLE" | grep -q '（' || echo "$TITLE" | grep -q '）' || \
   echo "$TITLE" | grep -q '、' || echo "$TITLE" | grep -q '。'; then
    echo "=========================================="
    echo "コミットメッセージに禁止文字が含まれています"
    echo "=========================================="
    echo ""
    echo "現在のタイトル: $TITLE"
    echo ""
    echo "禁止文字:"
    echo "  - 空白・タブ"
    echo "  - 括弧: () [] 「」（）"
    echo "  - 句読点: 、。"
    echo "=========================================="
    exit 1
fi

# 本文禁止（タイトル1行のみ許可）
CONTENT_LINES=$(grep -c -v '^$' "$COMMIT_MSG_FILE" 2>/dev/null || echo "0")
if [ "$CONTENT_LINES" -gt 1 ]; then
    echo "=========================================="
    echo "コミットメッセージは1行のみにしてください"
    echo "=========================================="
    echo ""
    echo "本文や署名は禁止されています"
    echo "=========================================="
    exit 1
fi

exit 0
HOOK_EOF

    chmod +x "$HOOK_FILE"
    info "  Created $HOOK_FILE"
}

# ============================================================================
# 3. Git hooks パス設定
# ============================================================================
configure_git_hooks() {
    info "Configuring git hooks path..."

    local CURRENT_PATH=$(git config core.hooksPath 2>/dev/null || echo "")

    if [[ "$CURRENT_PATH" == ".github/hooks" ]]; then
        info "  Git hooks path already configured"
    else
        git config core.hooksPath .github/hooks
        info "  Set core.hooksPath to .github/hooks"
    fi
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "=========================================="
    echo " Spec-Driven Development - Hooks Setup"
    echo "=========================================="
    echo ""

    # Git リポジトリチェック
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not a git repository!"
        exit 1
    fi

    create_hooks_dir
    create_commit_msg_hook
    configure_git_hooks

    echo ""
    echo "=========================================="
    echo " Hooks setup completed!"
    echo "=========================================="
    echo ""
    echo "Commit message format:"
    echo "  <type>:<番号>_<サマリ>"
    echo "  <type>:<番号>_Phase<N>_<サマリ>"
    echo ""
    echo "Examples:"
    echo "  feat:123_ユーザー認証追加"
    echo "  feat:123_Phase1_Domain層実装"
    echo ""
}

main "$@"
