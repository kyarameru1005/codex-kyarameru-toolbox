#!/bin/bash
# codex-notify.sh - セッション開始・終了の通知ハンドラ
#
# Usage:
#   CODEX_EVENT=session-start bash codex-notify.sh
#   CODEX_EVENT=session-end   bash codex-notify.sh
#
# Environment Variables:
#   CODEX_EVENT       イベント種別（session-start / session-end / agent-turn-complete / approval-requested）
#   CODEX_SESSION_ID  セッションID（オプション）
#
# Exit Codes:
#   0: 常に正常終了（未知のイベントも警告のみで exit 0）

# set -euo pipefail は使用しない（常に exit 0 を保証するため）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${CODEX_STATE_FILE:-${HOME}/.codex/.spec-session-state.json}"
LOG_FILE="${CODEX_LOG_FILE:-${HOME}/.codex/session.log}"

CODEX_EVENT="${CODEX_EVENT:-}"
CODEX_SESSION_ID="${CODEX_SESSION_ID:-}"

# タイムスタンプ
now() {
    date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S'
}

# ログ記録
log_event() {
    local event="$1"
    local message="$2"
    local timestamp
    timestamp="$(now)"
    local session_part=""
    [[ -n "$CODEX_SESSION_ID" ]] && session_part=" session=$CODEX_SESSION_ID"

    # ログファイルが書き込み可能なら記録
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    if [[ -d "$log_dir" ]] || mkdir -p "$log_dir" 2>/dev/null; then
        echo "[$timestamp]${session_part} event=$event $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# セッション開始処理
handle_session_start() {
    local session_info=""
    [[ -n "$CODEX_SESSION_ID" ]] && session_info=" (session: $CODEX_SESSION_ID)"

    echo "[codex-notify] Session started${session_info}"
    echo "[codex-notify] Time: $(now)"

    # .spec-session-state.json が存在する場合は再開ヒントを表示
    if [[ -f "$STATE_FILE" ]]; then
        echo "[codex-notify] Found previous session state: $STATE_FILE"
        if command -v jq &>/dev/null; then
            local current_spec current_phase
            current_spec=$(jq -r '.current_spec // empty' "$STATE_FILE" 2>/dev/null || true)
            current_phase=$(jq -r '.current_phase // empty' "$STATE_FILE" 2>/dev/null || true)
            if [[ -n "$current_spec" ]]; then
                echo "[codex-notify] Resume hint: spec='$current_spec' phase='$current_phase'"
                echo "[codex-notify] Run: /spec-go to continue"
            fi
        else
            echo "[codex-notify] Hint: previous session state found. Run /spec-go to resume."
        fi
    fi

    log_event "session-start" "started"
}

# セッション終了処理
handle_session_end() {
    local session_info=""
    [[ -n "$CODEX_SESSION_ID" ]] && session_info=" (session: $CODEX_SESSION_ID)"

    echo "[codex-notify] Session ended${session_info}"
    echo "[codex-notify] Time: $(now)"

    # セッション終了ログ記録
    log_event "session-end" "ended"

    # state ファイルのディレクトリが存在する場合、終了タイムスタンプを更新
    local state_dir
    state_dir="$(dirname "$STATE_FILE")"
    if [[ -f "$STATE_FILE" ]] && command -v jq &>/dev/null; then
        local updated
        updated=$(jq --arg ts "$(now)" --arg sid "$CODEX_SESSION_ID" \
            '.last_session_end = $ts | if $sid != "" then .last_session_id = $sid else . end' \
            "$STATE_FILE" 2>/dev/null) || true
        if [[ -n "$updated" ]]; then
            echo "$updated" > "$STATE_FILE" 2>/dev/null || true
        fi
    elif [[ -d "$state_dir" ]] || mkdir -p "$state_dir" 2>/dev/null; then
        # state ファイルが存在しない場合は新規作成
        if [[ ! -f "$STATE_FILE" ]]; then
            local content="{\"last_session_end\":\"$(now)\""
            [[ -n "$CODEX_SESSION_ID" ]] && content="${content},\"last_session_id\":\"${CODEX_SESSION_ID}\""
            content="${content}}"
            echo "$content" > "$STATE_FILE" 2>/dev/null || true
        fi
    fi
}

# メイン処理
case "$CODEX_EVENT" in
    session-start)
        handle_session_start
        ;;
    session-end)
        handle_session_end
        ;;
    agent-turn-complete)
        # 将来の通知実装のためのプレースホルダー（何もしない）
        log_event "agent-turn-complete" "noop"
        ;;
    approval-requested)
        echo "[codex-notify] WARN: Approval requested but running in Codex (non-interactive)" >&2
        log_event "approval-requested" "warning"
        ;;
    "")
        echo "[codex-notify] WARN: CODEX_EVENT is not set" >&2
        ;;
    *)
        echo "[codex-notify] WARN: Unknown event: '$CODEX_EVENT'" >&2
        log_event "$CODEX_EVENT" "unknown-event"
        ;;
esac

exit 0
