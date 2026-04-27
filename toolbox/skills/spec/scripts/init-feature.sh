#!/bin/bash
# Spec Init Feature - Feature ディレクトリ構造を作成
# Usage: init-feature.sh [issue] <feature>
#   issue:   Issue番号（省略時は gh issue create で自動作成）
#   feature: 機能名（スラッグ）
#
# 作成されるもの:
# - specs/features/{issue}-{feature}/ ディレクトリ
# - hearing.md, requirements.md, design.md, arch-check.md, test-spec.md, tasks.md (テンプレートから)
# (状態管理は specs/features/{issue}-{feature}/tasks.md で行う)

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [issue] <feature>" >&2
    echo "  issue:   Issue number (optional, auto-created if omitted)" >&2
    echo "  feature: Feature name slug (e.g., user-management)" >&2
    exit 1
fi

if [[ $# -eq 1 ]]; then
    ISSUE=""
    FEATURE="$1"
else
    ISSUE="$1"
    FEATURE="$2"
fi
DATE=$(date +%Y-%m-%d)

# ============================================================================
# gh CLI チェック & Issue 作成/番号確定
# ============================================================================
ensure_issue_number() {
    if [[ -n "$ISSUE" ]]; then
        info "Using existing Issue #${ISSUE}"
        return 0
    fi

    # gh CLI 確認
    if ! command -v gh &>/dev/null; then
        error "gh CLI not found. Install it or provide an issue number:"
        echo "  $0 <issue> ${FEATURE}" >&2
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        error "gh CLI not authenticated. Run: gh auth login"
        echo "  Or provide an issue number: $0 <issue> ${FEATURE}" >&2
        exit 1
    fi

    info "Creating lightweight Issue on GitHub..."
    local RESULT
    RESULT=$(gh issue create --title "feat: ${FEATURE}" --body "仕様策定中" 2>&1)

    # gh issue create は URL を返す (e.g., https://github.com/owner/repo/issues/123)
    ISSUE=$(echo "$RESULT" | grep -oP '/issues/\K[0-9]+' | tail -1)

    if [[ -z "$ISSUE" ]]; then
        error "Failed to create Issue: $RESULT"
        exit 1
    fi

    info "Created Issue #${ISSUE} (${RESULT})"
}

# 変数設定（Issue 番号確定後に呼び出し）
setup_variables() {
    FEATURE_DIR="specs/features/${ISSUE}-${FEATURE}"
    FEATURE_SLUG="${ISSUE}-${FEATURE}"
    BRANCH_NAME="feat/${ISSUE}-${FEATURE}"
}

# ============================================================================
# 1. プロジェクト初期化チェック
# ============================================================================
check_project_initialized() {
    info "Checking project initialization..."

    if [[ ! -d "specs" ]]; then
        error "Project not initialized!"
        error "Run the following first:"
        echo ""
        echo "  bash ~/.claude/skills/spec/scripts/init-project.sh"
        echo ""
        exit 1
    fi

    if [[ ! -f "specs/templates/config.yaml" ]]; then
        warn "  config.yaml not found, using defaults"
    fi

    info "  Project is initialized"
}

# ============================================================================
# 2. 既存 Feature チェック
# ============================================================================
check_existing_feature() {
    if [[ -d "$FEATURE_DIR" ]]; then
        error "Feature directory already exists: $FEATURE_DIR"
        error "To reset, delete the directory first:"
        echo ""
        echo "  rm -rf $FEATURE_DIR"
        echo ""
        exit 1
    fi
}

# ============================================================================
# 3. テンプレート解決関数
# ============================================================================
resolve_template() {
    local name="$1"
    local project_template="specs/templates/${name}"
    local fallback_template="${SKILL_DIR}/templates/${name}"

    if [[ -f "$project_template" ]]; then
        echo "$project_template"
    elif [[ -f "$fallback_template" ]]; then
        echo "$fallback_template"
    else
        echo ""
    fi
}

# ============================================================================
# 4. config.yaml 読み込み
# ============================================================================
load_config() {
    local CONFIG_FILE="specs/templates/config.yaml"

    # デフォルト値
    TEST_COMMAND_UNIT=""
    TEST_COMMAND_INTEGRATION=""
    TEST_COMMAND_E2E=""
    TEST_COMMAND_ALL=""
    TEST_COMMAND_LINT=""
    TEST_COMMAND_DEV=""

    if [[ -f "$CONFIG_FILE" ]]; then
        # 簡易的なYAML読み込み（yqがない環境用）
        TEST_COMMAND_UNIT=$(grep -E '^\s+unit:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*unit:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
        TEST_COMMAND_INTEGRATION=$(grep -E '^\s+integration:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*integration:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
        TEST_COMMAND_E2E=$(grep -E '^\s+e2e:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*e2e:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
        TEST_COMMAND_ALL=$(grep -E '^\s+all:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*all:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
        TEST_COMMAND_LINT=$(grep -E '^\s+lint:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*lint:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
        TEST_COMMAND_DEV=$(grep -E '^\s+dev:' "$CONFIG_FILE" 2>/dev/null | sed 's/.*dev:\s*"\?\([^"]*\)"\?/\1/' | tr -d '"' || echo "")
    fi
}

# ============================================================================
# 5. プレースホルダ置換関数
# ============================================================================
replace_placeholders() {
    local content="$1"

    # Feature 情報
    content="${content//\{\{FEATURE_NAME\}\}/${FEATURE}}"
    content="${content//\{\{FEATURE_SLUG\}\}/${FEATURE_SLUG}}"
    content="${content//\{\{ISSUE_NUMBER\}\}/${ISSUE}}"
    content="${content//\{\{BRANCH_NAME\}\}/${BRANCH_NAME}}"
    content="${content//\{\{DATE\}\}/${DATE}}"

    # テストコマンド
    content="${content//\{\{TEST_COMMAND_UNIT\}\}/${TEST_COMMAND_UNIT}}"
    content="${content//\{\{TEST_COMMAND_INTEGRATION\}\}/${TEST_COMMAND_INTEGRATION}}"
    content="${content//\{\{TEST_COMMAND_E2E\}\}/${TEST_COMMAND_E2E}}"
    content="${content//\{\{TEST_COMMAND_ALL\}\}/${TEST_COMMAND_ALL}}"
    content="${content//\{\{TEST_COMMAND_LINT\}\}/${TEST_COMMAND_LINT}}"
    content="${content//\{\{TEST_COMMAND_DEV\}\}/${TEST_COMMAND_DEV}}"

    echo "$content"
}

# ============================================================================
# 6. ディレクトリ作成
# ============================================================================
create_feature_directory() {
    info "Creating feature directory: $FEATURE_DIR"
    mkdir -p "$FEATURE_DIR"
}

# ============================================================================
# 7. テンプレートファイル作成
# ============================================================================
create_template_files() {
    info "Creating template files..."

    local TEMPLATES=(
        "hearing.md"
        "requirements.md"
        "design.md"
        "arch-check.md"
        "test-spec.md"
        "tasks.md"
    )

    for template_spec in "${TEMPLATES[@]}"; do
        # "source:dest" 形式をパース
        local template_name="${template_spec%%:*}"
        local output_name="${template_spec##*:}"
        if [[ "$template_spec" != *":"* ]]; then
            output_name="$template_name"
        fi

        local TEMPLATE=$(resolve_template "$template_name")
        local OUTPUT_FILE="${FEATURE_DIR}/${output_name}"

        if [[ -n "$TEMPLATE" ]]; then
            info "  Creating: $output_name"
            local CONTENT=$(cat "$TEMPLATE")
            CONTENT=$(replace_placeholders "$CONTENT")
            echo "$CONTENT" > "$OUTPUT_FILE"
        else
            warn "  Template not found: $template_name (creating empty file)"
            touch "$OUTPUT_FILE"
        fi
    done
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "=========================================="
    echo " Spec-Driven Development - Feature Init"
    echo "=========================================="
    echo ""

    check_project_initialized
    ensure_issue_number
    setup_variables

    echo ""
    echo "Feature: ${FEATURE}"
    echo "Issue:   #${ISSUE}"
    echo ""

    check_existing_feature
    load_config
    create_feature_directory
    create_template_files

    echo ""
    echo "=========================================="
    echo " Feature initialized successfully!"
    echo "=========================================="
    echo ""
    echo "Created:"
    echo "  ${FEATURE_DIR}/"
    echo "  ├── hearing.md        (ヒアリング)"
    echo "  ├── requirements.md   (要件定義)"
    echo "  ├── design.md         (設計書)"
    echo "  ├── arch-check.md     (設計レビュー)"
    echo "  ├── test-spec.md      (テスト仕様)"
    echo "  └── tasks.md          (タスク一覧)"
    echo ""
    echo "Next steps:"
    echo "  1. Create branch: git checkout -b ${BRANCH_NAME}"
    echo "  2. Run /spec requirements to define requirements"
    echo ""
}

main "$@"
