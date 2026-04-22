#!/bin/bash
# Spec Commit Phase - Phase コミットを作成（非対話モード）
# Usage: commit-phase.sh <feature_dir> <phase> <summary> [test_result]
#   feature_dir:  Feature ディレクトリパス (例: specs/features/123-user-auth)
#   phase:        Phase番号 (1-7)
#   summary:      サマリ（日本語、空白なし）
#   test_result:  テスト結果 (pass/fail/skipped) — 省略時は .tdd-state から読み取り
#
# 例: commit-phase.sh specs/features/123-user-auth 1 テストコード作成 fail
# → feat:123_Phase1_テストコード作成

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <feature_dir> <phase> <summary>" >&2
    echo "  feature_dir: Feature directory path (e.g., specs/features/123-user-auth)" >&2
    echo "  phase:       Phase number (1-7)" >&2
    echo "  summary:     Summary in Japanese (no spaces)" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 specs/features/123-user-auth 1 テストコード作成" >&2
    exit 1
fi

FEATURE_DIR="$1"
PHASE="$2"
SUMMARY="$3"
TEST_RESULT_ARG="${4:-}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# ============================================================================
# 1. Feature 情報を feature_dir から導出
# ============================================================================
load_status() {
    if [[ ! -d "$FEATURE_DIR" ]]; then
        error "Feature directory not found: $FEATURE_DIR"
        error "Run /spec new first to start a feature."
        exit 1
    fi

    local TASKS_FILE="${FEATURE_DIR}/tasks.md"
    if [[ ! -f "$TASKS_FILE" ]]; then
        error "tasks.md not found in: $FEATURE_DIR"
        exit 1
    fi

    # ディレクトリ名から issue と feature を導出
    local DIR_NAME
    DIR_NAME=$(basename "$FEATURE_DIR")
    ISSUE="${DIR_NAME%%-*}"
    FEATURE="${DIR_NAME#*-}"

    if [[ -z "$ISSUE" ]] || [[ -z "$FEATURE" ]]; then
        error "Cannot parse issue/feature from directory: $FEATURE_DIR"
        exit 1
    fi

    # tasks.md から完了済み Phase を数えて current_phase を算出
    CURRENT_PHASE=0
    for p in 1 2 3 4 5 6 7; do
        local IN_PHASE=false
        local ALL_DONE=true
        local HAS_TASKS=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*${p}: ]]; then
                IN_PHASE=true
                continue
            fi
            if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*[0-9]+: ]]; then
                break
            fi
            if [[ "$IN_PHASE" == true ]]; then
                if [[ "$line" =~ ^-[[:space:]]*\[x\] ]]; then
                    HAS_TASKS=true
                elif [[ "$line" =~ ^-[[:space:]]*\[[[:space:]]\] ]]; then
                    HAS_TASKS=true
                    ALL_DONE=false
                fi
            fi
        done < "$TASKS_FILE"
        if [[ "$HAS_TASKS" == true ]] && [[ "$ALL_DONE" == true ]]; then
            CURRENT_PHASE=$p
        fi
    done

    info "Feature: ${FEATURE} (#${ISSUE})"
    info "Current Phase: ${CURRENT_PHASE}"
}

# ============================================================================
# 2. TDD 状態ファイル検証
# ============================================================================
validate_tdd() {
    local FEATURE_NAME
    FEATURE_NAME=$(basename "$FEATURE_DIR")
    local TDD_STATE_FILE="${PROJECT_DIR:-.}/.tdd-state-${FEATURE_NAME}.json"

    # TDD 状態ファイルがなければスキップ
    if [[ ! -f "$TDD_STATE_FILE" ]]; then
        warn "TDD state file not found: ${TDD_STATE_FILE} (skipping TDD validation)"
        return 0
    fi

    # .tdd-state から該当 Phase の test_result を取得
    local STATE_TEST_RESULT
    STATE_TEST_RESULT=$(jq -r ".phases[\"${PHASE}\"].test_result // empty" "$TDD_STATE_FILE" 2>/dev/null)

    # 引数優先、なければ状態ファイルから
    local TEST_RESULT="${TEST_RESULT_ARG:-$STATE_TEST_RESULT}"

    if [[ -z "$TEST_RESULT" ]]; then
        warn "No test_result found for Phase ${PHASE} (skipping TDD validation)"
        return 0
    fi

    info "TDD validation: Phase ${PHASE}, test_result=${TEST_RESULT}"

    case "$PHASE" in
        1)
            case "$TEST_RESULT" in
                fail)
                    info "Phase 1 RED: Tests failing as expected"
                    ;;
                pass)
                    warn "Phase 1 RED: Tests should be failing (RED state), but they pass"
                    ;;
                skipped)
                    warn "Phase 1: Test execution recommended"
                    ;;
            esac
            ;;
        [2-6])
            case "$TEST_RESULT" in
                pass)
                    info "Phase ${PHASE} GREEN: Tests passing"
                    ;;
                fail)
                    error "Phase ${PHASE} GREEN: Tests must pass before commit. Fix failing tests first."
                    exit 1
                    ;;
                skipped)
                    warn "Phase ${PHASE}: Test execution recommended"
                    ;;
            esac
            ;;
        7)
            case "$TEST_RESULT" in
                pass)
                    info "Phase 7 REFACTOR: All tests passing"
                    ;;
                fail|skipped)
                    error "Phase 7 REFACTOR: All tests must pass before final commit. test_result=${TEST_RESULT}"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# ============================================================================
# 3. Phase 検証
# ============================================================================
validate_phase() {
    # Phase 番号チェック
    if ! [[ "$PHASE" =~ ^[1-7]$ ]]; then
        error "Invalid phase number: $PHASE (must be 1-7)"
        exit 1
    fi

    # 順序チェック（警告のみ、ブロックしない）
    local EXPECTED_PHASE=$((CURRENT_PHASE + 1))
    if [[ "$PHASE" -ne "$EXPECTED_PHASE" ]]; then
        warn "Phase order: expected Phase ${EXPECTED_PHASE}, got Phase ${PHASE} (continuing)"
    fi
}

# ============================================================================
# 4. 変更チェック
# ============================================================================
check_changes() {
    info "Checking for changes..."

    if git diff --cached --quiet; then
        warn "No staged changes found."
        echo ""
        echo "To stage all changes:"
        echo "  git add -A"
        echo ""
        exit 1
    fi

    echo ""
    echo -e "${CYAN}Staged changes:${NC}"
    git diff --cached --name-status
    echo ""
}

# ============================================================================
# 5. コミットメッセージ生成
# ============================================================================
generate_commit_message() {
    local CLEAN_SUMMARY="${SUMMARY// /_}"
    CLEAN_SUMMARY="${CLEAN_SUMMARY//　/_}"
    CLEAN_SUMMARY="${CLEAN_SUMMARY//、/}"
    CLEAN_SUMMARY="${CLEAN_SUMMARY//。/}"

    COMMIT_MSG="feat:${ISSUE}_Phase${PHASE}_${CLEAN_SUMMARY}"

    echo -e "${CYAN}Commit message:${NC}"
    echo "  $COMMIT_MSG"
    echo ""
}

# ============================================================================
# 6. コミット実行（非対話: 自律ループ対応）
# ============================================================================
execute_commit() {
    info "Creating commit..."
    git commit -m "$COMMIT_MSG"

    if [[ $? -eq 0 ]]; then
        info "Commit created successfully!"
    else
        error "Commit failed!"
        exit 1
    fi
}

# ============================================================================
# 7. tasks.md 更新（Phase のタスクを完了に）
# ============================================================================
update_tasks_md() {
    local TASKS_FILE="${FEATURE_DIR}/tasks.md"

    if [[ ! -f "$TASKS_FILE" ]]; then
        warn "tasks.md not found, skipping update"
        return
    fi

    info "Updating tasks.md..."

    local TEMP_FILE=$(mktemp)
    local IN_PHASE=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*${PHASE}: ]]; then
            IN_PHASE=true
            echo "$line" >> "$TEMP_FILE"
            continue
        fi

        if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*[0-9]+: ]]; then
            IN_PHASE=false
        fi

        if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^-[[:space:]]*\[[[:space:]]\] ]]; then
            line="${line/\[ \]/[x]}"
        fi

        echo "$line" >> "$TEMP_FILE"
    done < "$TASKS_FILE"

    mv "$TEMP_FILE" "$TASKS_FILE"
    info "  Updated tasks.md"
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "=========================================="
    echo " Spec-Driven Development - Phase Commit"
    echo "=========================================="
    echo ""

    load_status
    validate_phase
    validate_tdd
    check_changes
    generate_commit_message
    execute_commit
    update_tasks_md

    echo ""
    echo "=========================================="
    echo " Phase ${PHASE} committed successfully!"
    echo "=========================================="
    echo ""

    if [[ "$PHASE" -lt 7 ]]; then
        echo "Next: Continue with Phase $((PHASE + 1))"
    else
        echo "All phases completed!"
        echo "Next: /spec complete"
    fi
    echo ""
}

main "$@"
