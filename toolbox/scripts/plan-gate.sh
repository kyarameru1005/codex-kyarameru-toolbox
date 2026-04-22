#!/bin/bash
# Codex Plan Gate
# Plan を必ず生成してから実行するための2段階ラッパー。
#
# Usage:
#   plan-gate.sh plan "<task>" [plan_file]
#   plan-gate.sh exec <plan_file> [extra_instruction]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

usage() {
    cat << 'USAGE'
Usage:
  plan-gate.sh plan "<task>" [plan_file]
  plan-gate.sh exec <plan_file> [extra_instruction]

Examples:
  plan-gate.sh plan "OAuth login を実装したい"
  plan-gate.sh exec .codex/plans/plan-20260226-120000.md
USAGE
}

require_codex() {
    if ! command -v codex >/dev/null 2>&1; then
        error "codex command not found"
        exit 1
    fi
}

repo_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
}

make_plan() {
    local task="$1"
    local root
    root="$(repo_root)"

    local plan_dir="${root}/.codex/plans"
    mkdir -p "$plan_dir"

    local plan_file="${2:-${plan_dir}/plan-$(date +%Y%m%d-%H%M%S).md}"

    local prompt
    prompt=$(cat <<PROMPT
You are in strict planning mode.

Task:
${task}

Output requirements:
- Output in Markdown only.
- Include sections: Goal, Scope, Assumptions, Risks, Step-by-step Plan, Validation.
- Keep steps actionable and testable.
- Do not request code edits in this run.
PROMPT
)

    info "Generating plan with Codex..."
    codex exec "$prompt" --output-last-message "$plan_file"

    echo ""
    info "Plan saved: $plan_file"
    info "Next: review the plan, then run:"
    echo "  bash .codex/scripts/plan-gate.sh exec $plan_file"
}

execute_with_plan() {
    local plan_file="$1"
    local extra_instruction="${2:-}"

    if [[ ! -f "$plan_file" ]]; then
        error "Plan file not found: $plan_file"
        exit 1
    fi

    local plan_content
    plan_content="$(cat "$plan_file")"

    local prompt
    prompt=$(cat <<PROMPT
Execute the task by following the approved plan below.

<approved_plan>
${plan_content}
</approved_plan>

Execution rules:
- Follow the plan unless there is a blocking issue.
- If you must deviate, explain why before changing direction.
- Make concrete edits and report changed files.
- Run relevant checks when possible.

${extra_instruction:+Additional instruction:
${extra_instruction}}
PROMPT
)

    info "Executing with approved plan: $plan_file"
    codex exec "$prompt"
}

main() {
    require_codex

    local command="${1:-}"
    case "$command" in
        plan)
            shift
            if [[ $# -lt 1 ]]; then
                usage
                exit 1
            fi
            make_plan "$@"
            ;;
        exec)
            shift
            if [[ $# -lt 1 ]]; then
                usage
                exit 1
            fi
            execute_with_plan "$@"
            ;;
        help|--help|-h|"")
            usage
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
