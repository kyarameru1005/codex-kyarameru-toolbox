#!/bin/bash
# Phase Runner - Phase ライフサイクル管理
# Usage:
#   phase-runner.sh <feature_dir> <phase> start
#   phase-runner.sh <feature_dir> <phase> finish <summary> [test_result]
#
# start: Phase 開始を記録（.phase-state に書き込み）
# finish: テスト実行確認 → commit-phase.sh 呼び出し → Phase 完了記録
#
# 例:
#   phase-runner.sh specs/features/123-user-auth 1 start
#   phase-runner.sh specs/features/123-user-auth 1 finish テストコード作成 fail

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${GREEN}[PHASE]${NC} $1"; }
warn() { echo -e "${YELLOW}[PHASE]${NC} $1"; }
error() { echo -e "${RED}[PHASE]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <feature_dir> <phase> <start|finish> [summary] [test_result]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  start   - Mark phase as in_progress" >&2
    echo "  finish  - Validate, commit, and mark phase as completed" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 specs/features/123-auth 1 start" >&2
    echo "  $0 specs/features/123-auth 1 finish テストコード作成 fail" >&2
    exit 1
fi

FEATURE_DIR="$1"
PHASE="$2"
ACTION="$3"
SUMMARY="${4:-}"
TEST_RESULT="${5:-}"

PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
FEATURE_NAME=$(basename "$FEATURE_DIR")
STATE_FILE="${PROJECT_DIR}/.phase-state-${FEATURE_NAME}.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================================
# 状態ファイル操作
# ============================================================================

init_state_file() {
    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" << EOF
{
  "feature": "$FEATURE_NAME",
  "created_at": "$TIMESTAMP",
  "current_phase": null,
  "current_status": "idle",
  "phases": {}
}
EOF
        info "Created phase state file: $STATE_FILE"
    fi
}

get_current_phase() {
    jq -r '.current_phase // empty' "$STATE_FILE" 2>/dev/null
}

get_current_status() {
    jq -r '.current_status // "idle"' "$STATE_FILE" 2>/dev/null
}

update_state() {
    local phase="$1"
    local status="$2"
    local extra="${3:-}"

    local tmp=$(mktemp)
    if [[ -n "$extra" ]]; then
        jq --arg p "$phase" --arg s "$status" --arg t "$TIMESTAMP" --arg e "$extra" \
            '.current_phase = ($p | tonumber) | .current_status = $s | .phases[$p] = (.phases[$p] // {}) + {status: $s, updated_at: $t, summary: $e}' \
            "$STATE_FILE" > "$tmp"
    else
        jq --arg p "$phase" --arg s "$status" --arg t "$TIMESTAMP" \
            '.current_phase = ($p | tonumber) | .current_status = $s | .phases[$p] = (.phases[$p] // {}) + {status: $s, updated_at: $t}' \
            "$STATE_FILE" > "$tmp"
    fi
    mv "$tmp" "$STATE_FILE"
}

# ============================================================================
# start コマンド
# ============================================================================
do_start() {
    init_state_file

    local current=$(get_current_phase)
    local status=$(get_current_status)

    # 別の Phase が in_progress の場合は警告
    if [[ -n "$current" && "$status" == "in_progress" && "$current" != "$PHASE" ]]; then
        error "Phase ${current} is still in_progress!"
        error "Run 'phase-runner.sh $FEATURE_DIR $current finish <summary>' first."
        echo ""
        echo "Current state:"
        jq '.' "$STATE_FILE"
        exit 1
    fi

    # 同じ Phase が既に完了している場合は警告（再実行）
    local phase_status
    phase_status=$(jq -r ".phases[\"${PHASE}\"].status // empty" "$STATE_FILE" 2>/dev/null)
    if [[ "$phase_status" == "completed" ]]; then
        warn "Phase $PHASE was already completed. Re-opening..."
    fi

    # Phase 順序チェック（警告のみ）
    if [[ "$PHASE" -gt 1 ]]; then
        local prev=$((PHASE - 1))
        local prev_status
        prev_status=$(jq -r ".phases[\"${prev}\"].status // empty" "$STATE_FILE" 2>/dev/null)
        if [[ "$prev_status" != "completed" ]]; then
            warn "Phase $prev is not completed yet (status: ${prev_status:-not started})"
        fi
    fi

    update_state "$PHASE" "in_progress"

    echo ""
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD} Phase ${PHASE} Started${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "  Feature:   ${FEATURE_NAME}"
    echo -e "  Phase:     ${PHASE}"
    echo -e "  Started:   ${TIMESTAMP}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# ============================================================================
# finish コマンド
# ============================================================================
do_finish() {
    if [[ -z "$SUMMARY" ]]; then
        error "Summary is required for finish command"
        echo "Usage: $0 $FEATURE_DIR $PHASE finish <summary> [test_result]" >&2
        exit 1
    fi

    init_state_file

    local current=$(get_current_phase)
    local status=$(get_current_status)

    # Phase が start されていない場合は警告（ブロックはしない）
    if [[ "$current" != "$PHASE" || "$status" != "in_progress" ]]; then
        warn "Phase $PHASE was not properly started (current: Phase ${current:-none}, status: ${status})"
        warn "Proceeding anyway..."
    fi

    # ステージされた変更があるか確認
    if git diff --cached --quiet 2>/dev/null; then
        error "No staged changes. Run 'git add' before finishing the phase."
        exit 1
    fi

    # commit-phase.sh を呼び出し
    info "Calling commit-phase.sh..."
    if [[ -n "$TEST_RESULT" ]]; then
        bash "${SCRIPT_DIR}/commit-phase.sh" "$FEATURE_DIR" "$PHASE" "$SUMMARY" "$TEST_RESULT"
    else
        bash "${SCRIPT_DIR}/commit-phase.sh" "$FEATURE_DIR" "$PHASE" "$SUMMARY"
    fi

    local commit_exit=$?
    if [[ $commit_exit -ne 0 ]]; then
        error "commit-phase.sh failed (exit: $commit_exit)"
        update_state "$PHASE" "commit_failed" "$SUMMARY"
        exit $commit_exit
    fi

    # Phase 完了を記録
    update_state "$PHASE" "completed" "$SUMMARY"

    echo ""
    echo -e "${BOLD}${GREEN}========================================${NC}"
    echo -e "${BOLD} Phase ${PHASE} Completed${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "  Feature:   ${FEATURE_NAME}"
    echo -e "  Phase:     ${PHASE}"
    echo -e "  Summary:   ${SUMMARY}"
    echo -e "  Finished:  ${TIMESTAMP}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    if [[ "$PHASE" -lt 7 ]]; then
        echo "Next: phase-runner.sh $FEATURE_DIR $((PHASE + 1)) start"
    else
        echo "All phases completed! Next: /spec complete"
    fi
    echo ""
}

# ============================================================================
# status コマンド（おまけ）
# ============================================================================
do_status() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "No phase state file found."
        exit 0
    fi
    echo ""
    echo -e "${BOLD}Phase State: ${FEATURE_NAME}${NC}"
    echo ""
    jq -r '
        "Current Phase: \(.current_phase // "none")",
        "Status: \(.current_status)",
        "",
        (.phases | to_entries | sort_by(.key | tonumber) | .[] |
            "  Phase \(.key): \(.value.status) \(if .value.summary then "(\(.value.summary))" else "" end)")
    ' "$STATE_FILE"
    echo ""
}

# ============================================================================
# Main
# ============================================================================
case "$ACTION" in
    start) do_start ;;
    finish) do_finish ;;
    status) do_status ;;
    *)
        error "Unknown action: $ACTION"
        echo "Valid actions: start, finish, status" >&2
        exit 1
        ;;
esac
