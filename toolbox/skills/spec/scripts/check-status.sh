#!/bin/bash
# Spec Check Status - ワークフロー状態を確認・検証
# Usage: check-status.sh [feature_dir] [--verbose]
#
# feature_dir を省略した場合は specs/features/ から自動検出
#
# 確認項目:
# - プロジェクト初期化状態
# - 現在の Feature 状態（tasks.md ベース）
# - Phase 完了状況
# - コミット状況

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# オプション
VERBOSE=false
FEATURE_DIR=""

for arg in "$@"; do
    case "$arg" in
        --verbose|-v) VERBOSE=true ;;
        *) FEATURE_DIR="$arg" ;;
    esac
done

info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
header() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }

# ============================================================================
# 1. プロジェクト初期化チェック
# ============================================================================
check_project() {
    header "Project Status"

    local PROJECT_OK=true

    # specs/ ディレクトリ
    if [[ -d "specs" ]]; then
        info "specs/ directory exists"
    else
        error "specs/ directory not found"
        PROJECT_OK=false
    fi

    # .claude/settings.json (Plan mode)
    if [[ -f ".claude/settings.json" ]]; then
        if grep -q '"defaultMode".*"plan"' .claude/settings.json 2>/dev/null; then
            info "Plan mode enabled (.claude/settings.json)"
        else
            warn "Plan mode not configured in .claude/settings.json"
        fi
    else
        warn ".claude/settings.json not found (Plan mode not enforced)"
    fi

    # config.yaml
    if [[ -f "specs/templates/config.yaml" ]]; then
        info "config.yaml exists"
        if $VERBOSE; then
            echo "    Template source: $(grep -E '^template_source:' specs/templates/config.yaml 2>/dev/null | sed 's/template_source:\s*//' || echo 'unknown')"
        fi
    else
        warn "config.yaml not found"
    fi

    # Git hooks
    local HOOKS_PATH=$(git config core.hooksPath 2>/dev/null || echo "")
    if [[ "$HOOKS_PATH" == ".github/hooks" ]]; then
        info "Git hooks configured (.github/hooks)"
    elif [[ -n "$HOOKS_PATH" ]]; then
        info "Git hooks configured ($HOOKS_PATH)"
    else
        warn "Git hooks not configured"
    fi

    if [[ "$PROJECT_OK" == false ]]; then
        echo ""
        echo "To initialize project:"
        echo "  bash ~/.claude/skills/spec/scripts/init-project.sh"
        return 1
    fi

    return 0
}

# ============================================================================
# 2. Feature ディレクトリ検出
# ============================================================================
detect_feature_dir() {
    if [[ -n "$FEATURE_DIR" ]] && [[ -d "$FEATURE_DIR" ]]; then
        return 0
    fi

    # specs/features/ から最新のディレクトリを自動検出
    if [[ -d "specs/features" ]]; then
        FEATURE_DIR=$(ls -td specs/features/*/ 2>/dev/null | head -1 | sed 's:/$::')
    fi

    if [[ -z "$FEATURE_DIR" ]] || [[ ! -d "$FEATURE_DIR" ]]; then
        return 1
    fi

    return 0
}

# ============================================================================
# 3. Feature 状態チェック（tasks.md ベース）
# ============================================================================
check_feature() {
    header "Feature Status"

    if ! detect_feature_dir; then
        warn "No active feature found"
        echo ""
        echo "To start a new feature:"
        echo "  bash ~/.claude/skills/spec/scripts/init-feature.sh [issue] <feature>"
        return 1
    fi

    local TASKS_FILE="${FEATURE_DIR}/tasks.md"
    if [[ ! -f "$TASKS_FILE" ]]; then
        error "tasks.md not found in: $FEATURE_DIR"
        return 1
    fi

    # ディレクトリ名から issue と feature を導出
    local DIR_NAME
    DIR_NAME=$(basename "$FEATURE_DIR")
    local ISSUE="${DIR_NAME%%-*}"
    local FEATURE="${DIR_NAME#*-}"
    local BRANCH="feat/${DIR_NAME}"

    echo ""
    echo -e "  Feature:  ${BOLD}${FEATURE}${NC}"
    echo -e "  Issue:    #${ISSUE}"
    echo -e "  Branch:   ${BRANCH}"
    echo -e "  Dir:      ${FEATURE_DIR}"
    echo ""

    # Feature ディレクトリ確認
    info "Feature directory exists: $FEATURE_DIR"

    # ブランチ確認
    local CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$CURRENT_BRANCH" == "$BRANCH" ]]; then
        info "On correct branch: $BRANCH"
    else
        warn "Not on feature branch (current: $CURRENT_BRANCH, expected: $BRANCH)"
    fi

    return 0
}

# ============================================================================
# 4. Phase 完了状況チェック（tasks.md パース）
# ============================================================================
check_phases() {
    header "Phase Progress"

    if [[ -z "$FEATURE_DIR" ]] || [[ ! -d "$FEATURE_DIR" ]]; then
        return 1
    fi

    local TASKS_FILE="${FEATURE_DIR}/tasks.md"
    if [[ ! -f "$TASKS_FILE" ]]; then
        return 1
    fi

    echo ""
    printf "  %-8s %-30s %-10s %-6s\n" "Phase" "Name" "Status" "Done"
    printf "  %-8s %-30s %-10s %-6s\n" "-----" "------------------------------" "----------" "------"

    for p in 0 1 2 3 4 5 6 7; do
        local IN_PHASE=false
        local PHASE_NAME=""
        local TOTAL=0
        local DONE=0

        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*${p}:[[:space:]]*(.*) ]]; then
                IN_PHASE=true
                PHASE_NAME="${BASH_REMATCH[1]}"
                continue
            fi
            if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*[0-9]+: ]]; then
                break
            fi
            if [[ "$IN_PHASE" == true ]]; then
                if [[ "$line" =~ ^-[[:space:]]*\[x\] ]]; then
                    TOTAL=$((TOTAL + 1))
                    DONE=$((DONE + 1))
                elif [[ "$line" =~ ^-[[:space:]]*\[[[:space:]]\] ]]; then
                    TOTAL=$((TOTAL + 1))
                fi
            fi
        done < "$TASKS_FILE"

        # Phase が tasks.md に存在しない場合はスキップ
        if [[ -z "$PHASE_NAME" ]]; then
            continue
        fi

        local STATUS="pending"
        local STATUS_COLOR="${NC}"
        if [[ "$TOTAL" -gt 0 ]]; then
            if [[ "$DONE" -eq "$TOTAL" ]]; then
                STATUS="completed"
                STATUS_COLOR="${GREEN}"
            elif [[ "$DONE" -gt 0 ]]; then
                STATUS="in_progress"
                STATUS_COLOR="${YELLOW}"
            fi
        fi

        printf "  %-8s %-30s ${STATUS_COLOR}%-10s${NC} %d/%d\n" \
            "$p" "$PHASE_NAME" "$STATUS" "$DONE" "$TOTAL"
    done

    echo ""
}

# ============================================================================
# 5. ファイル存在チェック
# ============================================================================
check_files() {
    header "Feature Files"

    if [[ -z "$FEATURE_DIR" ]] || [[ ! -d "$FEATURE_DIR" ]]; then
        return 1
    fi

    local FILES=(
        "hearing.md"
        "requirements.md"
        "design.md"
        "tasks.md"
        "test-spec.md"
        "issue.md"
    )

    echo ""
    for file in "${FILES[@]}"; do
        local FILE_PATH="${FEATURE_DIR}/${file}"
        if [[ -f "$FILE_PATH" ]]; then
            local SIZE=$(wc -c < "$FILE_PATH")
            if [[ "$SIZE" -gt 500 ]]; then
                info "$file (${SIZE} bytes)"
            else
                warn "$file (${SIZE} bytes - possibly empty/template)"
            fi
        else
            error "$file not found"
        fi
    done
    echo ""
}

# ============================================================================
# 6. Git 状態チェック
# ============================================================================
check_git() {
    header "Git Status"

    echo ""

    # ステージされていない変更
    local UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
    if [[ "$UNSTAGED" -gt 0 ]]; then
        warn "Unstaged changes: ${UNSTAGED} files"
        if $VERBOSE; then
            git diff --name-only 2>/dev/null | head -5 | sed 's/^/    /'
            if [[ "$UNSTAGED" -gt 5 ]]; then
                echo "    ... and $((UNSTAGED - 5)) more"
            fi
        fi
    else
        info "No unstaged changes"
    fi

    # ステージされた変更
    local STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
    if [[ "$STAGED" -gt 0 ]]; then
        warn "Staged changes: ${STAGED} files (not committed)"
        if $VERBOSE; then
            git diff --cached --name-only 2>/dev/null | head -5 | sed 's/^/    /'
        fi
    else
        info "No staged changes"
    fi

    # 未追跡ファイル
    local UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    if [[ "$UNTRACKED" -gt 0 ]]; then
        warn "Untracked files: ${UNTRACKED}"
    fi

    echo ""
}

# ============================================================================
# 7. 次のアクション提案
# ============================================================================
suggest_next_action() {
    header "Suggested Next Action"

    if [[ -z "$FEATURE_DIR" ]] || [[ ! -d "$FEATURE_DIR" ]]; then
        echo ""
        echo "  Start a new feature:"
        echo "    /spec new <feature>"
        echo ""
        return
    fi

    local TASKS_FILE="${FEATURE_DIR}/tasks.md"
    if [[ ! -f "$TASKS_FILE" ]]; then
        echo ""
        echo "  Define requirements:"
        echo "    /spec requirements"
        echo ""
        return
    fi

    # tasks.md から最初の未完了 Phase を検出
    local NEXT_PHASE=""
    local ALL_DONE=true
    for p in 0 1 2 3 4 5 6 7; do
        local IN_PHASE=false
        local HAS_UNCHECKED=false
        local PHASE_EXISTS=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*${p}: ]]; then
                IN_PHASE=true
                PHASE_EXISTS=true
                continue
            fi
            if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^##[[:space:]]*Phase[[:space:]]*[0-9]+: ]]; then
                break
            fi
            if [[ "$IN_PHASE" == true ]] && [[ "$line" =~ ^-[[:space:]]*\[[[:space:]]\] ]]; then
                HAS_UNCHECKED=true
            fi
        done < "$TASKS_FILE"

        if [[ "$PHASE_EXISTS" == true ]] && [[ "$HAS_UNCHECKED" == true ]]; then
            if [[ -z "$NEXT_PHASE" ]]; then
                NEXT_PHASE=$p
            fi
            ALL_DONE=false
        fi
    done

    echo ""
    if [[ "$ALL_DONE" == true ]]; then
        echo "  All phases completed!"
        echo "  Next steps:"
        echo "    1. Run /spec verify"
        echo "    2. Run /spec complete"
    elif [[ -n "$NEXT_PHASE" ]]; then
        echo "  Continue with Phase ${NEXT_PHASE}:"
        echo "    /spec work"
    fi
    echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
    echo ""
    echo "=========================================="
    echo " Spec-Driven Development - Status Check"
    echo "=========================================="

    check_project
    check_feature
    check_phases
    check_files
    check_git
    suggest_next_action

    echo "=========================================="
    echo ""
}

main "$@"
