#!/bin/bash
# hook-runner.sh - 汎用 hook ランナー
#
# Usage:
#   hook-runner.sh pre <command_name> [args...]
#   hook-runner.sh post <command_name> [args...]
#
# Environment Variables:
#   HOOKS_DIR         hook スクリプトのディレクトリ（デフォルト: このスクリプトと同ディレクトリ）
#   HOOK_TIMEOUT      タイムアウト秒数（デフォルト: 10）
#   CODEX_HOOK_PRE    pre hook スクリプトパス（コロン区切り複数可）
#   CODEX_HOOK_POST   post hook スクリプトパス（コロン区切り複数可）
#
# Exit Codes:
#   pre モード: hook が exit 2 → exit 2（ブロック）、それ以外 → exit 0
#   post モード: 常に exit 0（hook の失敗は無視）
#   未登録コマンド: exit 0（pass-through）

set -uo pipefail

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${HOOKS_DIR:-$SCRIPT_DIR}"
HOOK_TIMEOUT="${HOOK_TIMEOUT:-10}"
REGISTRY_FILE="${HOOKS_DIR}/hook-registry.json"

# ログ関数
log_info()  { echo "[hook-runner] INFO:  $*" >&2; }
log_warn()  { echo "[hook-runner] WARN:  $*" >&2; }
log_error() { echo "[hook-runner] ERROR: $*" >&2; }

# 使い方チェック
if [[ $# -lt 2 ]]; then
    log_error "Usage: $0 <pre|post> <command_name> [args...]"
    exit 1
fi

MODE="$1"
COMMAND_NAME="$2"
shift 2

# mode バリデーション
if [[ "$MODE" != "pre" && "$MODE" != "post" ]]; then
    log_error "Invalid mode: $MODE (must be 'pre' or 'post')"
    exit 1
fi

# jq がない場合はスキップして続行（AC-9）
if ! command -v jq &>/dev/null; then
    log_warn "jq not found, skipping hooks for '$COMMAND_NAME'"
    exit 0
fi

# hook-registry.json が存在しない場合は pass-through
if [[ ! -f "$REGISTRY_FILE" ]]; then
    log_warn "hook-registry.json not found: $REGISTRY_FILE"
    exit 0
fi

# registry から hook スクリプト一覧を取得
get_hooks() {
    local cmd="$1"
    local mode="$2"
    jq -r --arg cmd "$cmd" --arg mode "$mode" \
        '.hooks[$cmd][$mode][]? // empty' \
        "$REGISTRY_FILE" 2>/dev/null
}

# hook スクリプトを実行
run_hook_script() {
    local hook_script="$1"
    local mode="$2"
    local cmd_name="$3"

    # パス解決: 相対パスは HOOKS_DIR から、絶対パスはそのまま
    local resolved_script
    if [[ "$hook_script" = /* ]]; then
        resolved_script="$hook_script"
    else
        resolved_script="${HOOKS_DIR}/${hook_script}"
    fi

    if [[ ! -f "$resolved_script" ]]; then
        log_warn "Hook script not found: $resolved_script"
        return 0
    fi

    if [[ ! -x "$resolved_script" ]]; then
        log_warn "Hook script not executable: $resolved_script (trying with bash)"
    fi

    log_info "Running $mode hook: $hook_script for command '$cmd_name'"

    local exit_code=0
    if command -v timeout &>/dev/null; then
        timeout "$HOOK_TIMEOUT" bash "$resolved_script" "$cmd_name" "$@" 2>&1 || exit_code=$?
    else
        bash "$resolved_script" "$cmd_name" "$@" 2>&1 || exit_code=$?
    fi

    return "$exit_code"
}

# メイン処理
HOOKS_LIST=()
while IFS= read -r hook; do
    [[ -n "$hook" ]] && HOOKS_LIST+=("$hook")
done < <(get_hooks "$COMMAND_NAME" "$MODE")

# 未登録コマンドは pass-through
if [[ ${#HOOKS_LIST[@]} -eq 0 ]]; then
    log_info "No $MODE hooks registered for '$COMMAND_NAME', passing through"
    exit 0
fi

case "$MODE" in
    pre)
        for hook in "${HOOKS_LIST[@]}"; do
            exit_code=0
            run_hook_script "$hook" "pre" "$COMMAND_NAME" "$@" || exit_code=$?
            if [[ "$exit_code" -eq 2 ]]; then
                log_warn "Pre hook blocked command '$COMMAND_NAME' (exit 2): $hook"
                exit 2
            elif [[ "$exit_code" -ne 0 ]]; then
                log_warn "Pre hook returned exit $exit_code for '$COMMAND_NAME': $hook (continuing)"
            fi
        done
        exit 0
        ;;
    post)
        for hook in "${HOOKS_LIST[@]}"; do
            exit_code=0
            run_hook_script "$hook" "post" "$COMMAND_NAME" "$@" || exit_code=$?
            if [[ "$exit_code" -ne 0 ]]; then
                log_warn "Post hook returned exit $exit_code for '$COMMAND_NAME': $hook (ignored)"
            fi
        done
        # post モードは常に exit 0
        exit 0
        ;;
esac
