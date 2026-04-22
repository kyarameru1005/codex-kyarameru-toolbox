#!/bin/bash
# Codex wrapper for plan-worker with Pre/Post gate checks.
#
# Usage:
#   spec-planner.sh <request_id> <mode> <feature> [mcp_names] [context_file]

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
  spec-planner.sh <request_id> <mode> <feature> [mcp_names] [context_file]

Example:
  spec-planner.sh plan_20260226-120000 requirements oauth-support "tavily" ""
USAGE
}

if [[ $# -lt 3 ]]; then
    usage
    exit 1
fi

REQUEST_ID="$1"
MODE="$2"
FEATURE="$3"
MCP_NAMES="${4:-}"
CONTEXT_FILE="${5:-}"

AGENT_HOME="${AGENT_HOME:-${HOME}/.codex}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

find_existing_path() {
    local primary="$1"
    local fallback="$2"

    if [[ -f "$primary" ]]; then
        echo "$primary"
        return 0
    fi

    if [[ -f "$fallback" ]]; then
        echo "$fallback"
        return 0
    fi

    return 1
}

PLANNER_SCRIPT="$(find_existing_path \
    "${AGENT_HOME}/skills/plan-worker/scripts/run_planner.sh" \
    "${SCRIPT_DIR}/../../.shared/skills/plan-worker/scripts/run_planner.sh")" || {
    error "run_planner.sh not found"
    exit 1
}

PRE_HOOK="$(find_existing_path \
    "${AGENT_HOME}/hooks/spec-pre-hook.sh" \
    "${SCRIPT_DIR}/../../.shared/hooks/spec-pre-hook.sh")" || true

POST_HOOK="$(find_existing_path \
    "${AGENT_HOME}/hooks/spec-post-hook.sh" \
    "${SCRIPT_DIR}/../../.shared/hooks/spec-post-hook.sh")" || true

COMMAND_STR=$(printf 'bash "%s" "%s" "%s" "%s" "%s" "%s"' \
    "$PLANNER_SCRIPT" "$REQUEST_ID" "$MODE" "$FEATURE" "$MCP_NAMES" "$CONTEXT_FILE")

run_pre_hook() {
    local command="$1"

    if [[ -z "${PRE_HOOK:-}" || ! -f "$PRE_HOOK" ]]; then
        echo "$command"
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found. Skipping pre-hook gate checks."
        echo "$command"
        return 0
    fi

    local input_json
    input_json=$(jq -n --arg cmd "$command" '{tool_input: {command: $cmd}}')

    local hook_output
    set +e
    hook_output=$(printf '%s' "$input_json" | \
        AGENT_HOME="$AGENT_HOME" CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$PRE_HOOK")
    local hook_status=$?
    set -e

    if [[ $hook_status -eq 2 ]]; then
        error "Pre-check blocked by spec transition gate."
        exit 2
    fi

    if [[ $hook_status -ne 0 ]]; then
        error "Pre-hook failed (exit: $hook_status)"
        exit $hook_status
    fi

    local updated
    updated=$(printf '%s' "$hook_output" | jq -r '.hookSpecificOutput.updatedInput.command // empty' 2>/dev/null || true)
    if [[ -n "$updated" ]]; then
        echo "$updated"
    else
        echo "$command"
    fi
}

run_post_hook() {
    local command="$1"

    if [[ -z "${POST_HOOK:-}" || ! -f "$POST_HOOK" ]]; then
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 0
    fi

    local input_json
    input_json=$(jq -n --arg cmd "$command" '{tool_input: {command: $cmd}, tool_output: {}}')

    # post-hook は警告出力用途。失敗しても本体ステータスは変えない。
    printf '%s' "$input_json" | \
        AGENT_HOME="$AGENT_HOME" CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$POST_HOOK" || true
}

COMMAND_STR="$(run_pre_hook "$COMMAND_STR")"

set +e
AGENT_HOME="$AGENT_HOME" CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash -c "$COMMAND_STR"
RUN_STATUS=$?
set -e

run_post_hook "$COMMAND_STR"
exit "$RUN_STATUS"
