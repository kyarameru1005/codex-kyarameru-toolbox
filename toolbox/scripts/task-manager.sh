#!/bin/bash
# task-manager.sh — ClaudeCode TaskCreate/Update/Get/List/Output/Stop シム
# データストア: ~/.codex/tasks/tasks.json（環境変数 CODEX_TASKS_FILE で上書き可）
#
# Usage:
#   task-manager.sh create <subject> [description]
#   task-manager.sh get <task_id>
#   task-manager.sh list [--status <status>]
#   task-manager.sh update <task_id> <field> <value>
#   task-manager.sh output <task_id> <message>
#   task-manager.sh stop <task_id>
#   task-manager.sh reset
#   task-manager.sh --help

set -euo pipefail

# ============================================================
# データストア設定
# ============================================================
TASKS_DIR="${CODEX_TASKS_DIR:-${HOME}/.codex/tasks}"
TASKS_FILE="${CODEX_TASKS_FILE:-${TASKS_DIR}/tasks.json}"

# ============================================================
# ヘルプ
# ============================================================
usage() {
    cat <<'EOF'
task-manager.sh — Task Management Shim for ClaudeCode / Codex

Usage:
  task-manager.sh create <subject> [description]
      Create a new task (status=pending). Prints task_id to stdout.

  task-manager.sh get <task_id>
      Show task details as JSON.

  task-manager.sh list [--status <status>]
      List all tasks (or filter by status) as JSON array.

  task-manager.sh update <task_id> <field> <value>
      Update a task field. Supported fields: status, subject, description.

  task-manager.sh output <task_id> <message>
      Append a progress message to the task's output log.

  task-manager.sh stop <task_id>
      Set task status to 'stopped'.

  task-manager.sh reset
      Reset tasks.json to an empty state.

  task-manager.sh --help
      Show this help message.

Environment variables:
  CODEX_TASKS_DIR   Override tasks directory (default: ~/.codex/tasks)
  CODEX_TASKS_FILE  Override tasks file path (default: $CODEX_TASKS_DIR/tasks.json)

Status values: pending, in_progress, completed, stopped, deleted
EOF
}

# ============================================================
# ユーティリティ
# ============================================================
now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

gen_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif [[ -f /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
    else
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    fi
}

ensure_dir() {
    mkdir -p "$TASKS_DIR"
}

init_tasks_file() {
    ensure_dir
    if [[ ! -f "$TASKS_FILE" ]]; then
        echo '{"tasks":[],"next_id":1}' > "$TASKS_FILE"
    fi
}

# ============================================================
# JSON 操作: jq 優先、なければ python3 フォールバック
# ============================================================
HAS_JQ=false
if command -v jq &>/dev/null; then
    HAS_JQ=true
fi

# ファイルの内容全体を jq/python3 で変換して上書き
# 引数: <jq_filter> <python3_script_body>
# python3 スクリプト内では data 変数にパース済みの dict が入っている
transform_file() {
    local jq_filter="$1"
    local py_script="$2"

    if [[ ! -f "$TASKS_FILE" ]]; then
        init_tasks_file
    fi

    local tmp_file="${TASKS_FILE}.tmp.$$"

    if $HAS_JQ; then
        # flock で排他制御（jq 環境）
        (
            flock -x 200
            jq "$jq_filter" "$TASKS_FILE" > "$tmp_file" && mv "$tmp_file" "$TASKS_FILE"
        ) 200>"${TASKS_FILE}.lock"
    else
        python3 - "$TASKS_FILE" "$tmp_file" <<PYEOF
import sys, json

tasks_file = sys.argv[1]
tmp_file   = sys.argv[2]

with open(tasks_file, 'r') as f:
    data = json.load(f)

${py_script}

with open(tmp_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False)

import os
os.replace(tmp_file, tasks_file)
PYEOF
    fi
}

# ファイルを読んで値を返す
# 引数: <jq_filter> <python3_script_body>
# python3 スクリプト内では data に dict が入り、result 変数に出力文字列を代入する
query_file() {
    local jq_filter="$1"
    local py_script="$2"

    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "[]"
        return 0
    fi

    if $HAS_JQ; then
        jq -r "$jq_filter" "$TASKS_FILE"
    else
        python3 - "$TASKS_FILE" <<PYEOF
import sys, json

tasks_file = sys.argv[1]

with open(tasks_file, 'r') as f:
    data = json.load(f)

${py_script}
PYEOF
    fi
}

# ============================================================
# コマンド実装
# ============================================================

# create <subject> [description]
cmd_create() {
    local subject="${1:-}"
    local description="${2:-}"

    if [[ -z "$subject" ]]; then
        echo "Error: subject is required" >&2
        echo "Usage: task-manager.sh create <subject> [description]" >&2
        exit 1
    fi

    ensure_dir
    init_tasks_file

    local task_id
    task_id=$(gen_uuid)
    local created_at
    created_at=$(now_iso)

    local jq_filter
    jq_filter=$(cat <<JQ_EOF
.tasks += [{
  "id": "$task_id",
  "subject": $(echo "$subject" | jq -R .),
  "description": $(echo "$description" | jq -R .),
  "activeForm": "",
  "status": "pending",
  "owner": "",
  "blockedBy": [],
  "blocks": [],
  "output": [],
  "created_at": "$created_at",
  "updated_at": "$created_at"
}]
JQ_EOF
)

    local py_script
    py_script=$(cat <<PYEOF_CONTENT
import uuid as _uuid, datetime as _dt
task_id = "${task_id}"
subject = ${subject@Q}
description = ${description@Q}
created_at = "${created_at}"
new_task = {
    "id": task_id,
    "subject": subject,
    "description": description,
    "activeForm": "",
    "status": "pending",
    "owner": "",
    "blockedBy": [],
    "blocks": [],
    "output": [],
    "created_at": created_at,
    "updated_at": created_at,
}
data["tasks"].append(new_task)
PYEOF_CONTENT
)

    if $HAS_JQ; then
        (
            flock -x 200
            local tmp_file="${TASKS_FILE}.tmp.$$"
            jq "$jq_filter" "$TASKS_FILE" > "$tmp_file" && mv "$tmp_file" "$TASKS_FILE"
        ) 200>"${TASKS_FILE}.lock"
    else
        python3 - "$TASKS_FILE" "${TASKS_FILE}.tmp.$$" "$task_id" "$subject" "$description" "$created_at" <<'PYEOF'
import sys, json, os

tasks_file  = sys.argv[1]
tmp_file    = sys.argv[2]
task_id     = sys.argv[3]
subject     = sys.argv[4]
description = sys.argv[5]
created_at  = sys.argv[6]

with open(tasks_file, 'r') as f:
    data = json.load(f)

new_task = {
    "id": task_id,
    "subject": subject,
    "description": description,
    "activeForm": "",
    "status": "pending",
    "owner": "",
    "blockedBy": [],
    "blocks": [],
    "output": [],
    "created_at": created_at,
    "updated_at": created_at,
}
data["tasks"].append(new_task)

with open(tmp_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False)

os.replace(tmp_file, tasks_file)
PYEOF
    fi

    echo "$task_id"
}

# get <task_id>
cmd_get() {
    local task_id="${1:-}"

    if [[ -z "$task_id" ]]; then
        echo "Error: task_id is required" >&2
        echo "Usage: task-manager.sh get <task_id>" >&2
        exit 1
    fi

    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "Error: task not found: $task_id" >&2
        exit 1
    fi

    if $HAS_JQ; then
        local result
        result=$(jq --arg id "$task_id" '.tasks[] | select(.id == $id)' "$TASKS_FILE")
        if [[ -z "$result" ]]; then
            echo "Error: task not found: $task_id" >&2
            exit 1
        fi
        echo "$result"
    else
        python3 - "$TASKS_FILE" "$task_id" <<'PYEOF'
import sys, json

tasks_file = sys.argv[1]
task_id    = sys.argv[2]

with open(tasks_file, 'r') as f:
    data = json.load(f)

found = [t for t in data.get("tasks", []) if t["id"] == task_id]
if not found:
    print(f"Error: task not found: {task_id}", file=sys.stderr)
    sys.exit(1)

print(json.dumps(found[0], ensure_ascii=False))
PYEOF
    fi
}

# list [--status <status>]
cmd_list() {
    local filter_status=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)
                filter_status="${2:-}"
                shift 2
                ;;
            *)
                echo "Error: unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "[]"
        return 0
    fi

    if $HAS_JQ; then
        if [[ -n "$filter_status" ]]; then
            jq --arg s "$filter_status" '[.tasks[] | select(.status == $s)]' "$TASKS_FILE"
        else
            jq '.tasks' "$TASKS_FILE"
        fi
    else
        python3 - "$TASKS_FILE" "$filter_status" <<'PYEOF'
import sys, json

tasks_file    = sys.argv[1]
filter_status = sys.argv[2]

with open(tasks_file, 'r') as f:
    data = json.load(f)

tasks = data.get("tasks", [])
if filter_status:
    tasks = [t for t in tasks if t.get("status") == filter_status]

print(json.dumps(tasks, ensure_ascii=False))
PYEOF
    fi
}

# update <task_id> <field> <value>
cmd_update() {
    local task_id="${1:-}"
    local field="${2:-}"
    local value="${3:-}"

    if [[ -z "$task_id" || -z "$field" || -z "$value" ]]; then
        echo "Error: task_id, field, and value are required" >&2
        echo "Usage: task-manager.sh update <task_id> <field> <value>" >&2
        echo "Supported fields: status, subject, description" >&2
        exit 1
    fi

    case "$field" in
        status|subject|description) ;;
        *)
            echo "Error: unsupported field: $field (supported: status, subject, description)" >&2
            exit 1
            ;;
    esac

    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "Error: task not found: $task_id" >&2
        exit 1
    fi

    local updated_at
    updated_at=$(now_iso)

    if $HAS_JQ; then
        (
            flock -x 200
            local tmp_file="${TASKS_FILE}.tmp.$$"
            jq --arg id "$task_id" --arg field "$field" --arg val "$value" --arg ts "$updated_at" \
               '(.tasks[] | select(.id == $id) | .[$field]) = $val |
                (.tasks[] | select(.id == $id) | .updated_at) = $ts' \
               "$TASKS_FILE" > "$tmp_file" && mv "$tmp_file" "$TASKS_FILE"
        ) 200>"${TASKS_FILE}.lock"
    else
        python3 - "$TASKS_FILE" "${TASKS_FILE}.tmp.$$" "$task_id" "$field" "$value" "$updated_at" <<'PYEOF'
import sys, json, os

tasks_file  = sys.argv[1]
tmp_file    = sys.argv[2]
task_id     = sys.argv[3]
field       = sys.argv[4]
value       = sys.argv[5]
updated_at  = sys.argv[6]

with open(tasks_file, 'r') as f:
    data = json.load(f)

found = False
for t in data.get("tasks", []):
    if t["id"] == task_id:
        t[field] = value
        t["updated_at"] = updated_at
        found = True
        break

if not found:
    print(f"Error: task not found: {task_id}", file=sys.stderr)
    sys.exit(1)

with open(tmp_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False)

os.replace(tmp_file, tasks_file)
PYEOF
    fi
}

# output <task_id> <message>
cmd_output() {
    local task_id="${1:-}"
    local message="${2:-}"

    if [[ -z "$task_id" || -z "$message" ]]; then
        echo "Error: task_id and message are required" >&2
        echo "Usage: task-manager.sh output <task_id> <message>" >&2
        exit 1
    fi

    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "Error: task not found: $task_id" >&2
        exit 1
    fi

    local ts
    ts=$(now_iso)

    if $HAS_JQ; then
        (
            flock -x 200
            local tmp_file="${TASKS_FILE}.tmp.$$"
            jq --arg id "$task_id" --arg msg "$message" --arg ts "$ts" \
               '(.tasks[] | select(.id == $id) | .output) += [{"timestamp": $ts, "message": $msg}] |
                (.tasks[] | select(.id == $id) | .updated_at) = $ts' \
               "$TASKS_FILE" > "$tmp_file" && mv "$tmp_file" "$TASKS_FILE"
        ) 200>"${TASKS_FILE}.lock"
    else
        python3 - "$TASKS_FILE" "${TASKS_FILE}.tmp.$$" "$task_id" "$message" "$ts" <<'PYEOF'
import sys, json, os

tasks_file = sys.argv[1]
tmp_file   = sys.argv[2]
task_id    = sys.argv[3]
message    = sys.argv[4]
ts         = sys.argv[5]

with open(tasks_file, 'r') as f:
    data = json.load(f)

found = False
for t in data.get("tasks", []):
    if t["id"] == task_id:
        t.setdefault("output", []).append({"timestamp": ts, "message": message})
        t["updated_at"] = ts
        found = True
        break

if not found:
    print(f"Error: task not found: {task_id}", file=sys.stderr)
    sys.exit(1)

with open(tmp_file, 'w') as f:
    json.dump(data, f, ensure_ascii=False)

os.replace(tmp_file, tasks_file)
PYEOF
    fi
}

# stop <task_id>
cmd_stop() {
    local task_id="${1:-}"

    if [[ -z "$task_id" ]]; then
        echo "Error: task_id is required" >&2
        echo "Usage: task-manager.sh stop <task_id>" >&2
        exit 1
    fi

    cmd_update "$task_id" status stopped
}

# reset
cmd_reset() {
    ensure_dir
    echo '{"tasks":[],"next_id":1}' > "$TASKS_FILE"
}

# ============================================================
# エントリーポイント
# ============================================================
COMMAND="${1:-}"

case "$COMMAND" in
    --help|-h|help)
        usage
        exit 0
        ;;
    create)
        shift
        cmd_create "$@"
        ;;
    get)
        shift
        cmd_get "$@"
        ;;
    list)
        shift
        cmd_list "$@"
        ;;
    update)
        shift
        cmd_update "$@"
        ;;
    output)
        shift
        cmd_output "$@"
        ;;
    stop)
        shift
        cmd_stop "$@"
        ;;
    reset)
        cmd_reset
        ;;
    "")
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown command: $COMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
