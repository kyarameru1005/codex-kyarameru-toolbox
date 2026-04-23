#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="toolbox/harness/state/tasks.json"
COMMAND="${1:-}"
shift || true

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/update-task-state.sh <command> [options]

Commands:
  init
  upsert --task-id <id> --status <queued|running|checkpointed|passed|failed> [--owner <agent>] [--retries <n>]
  set-status --task-id <id> --status <queued|running|checkpointed|passed|failed>
  show

Options:
  --file <path>  state file path (default: toolbox/harness/state/tasks.json)
USAGE
}

if [[ -z "$COMMAND" ]]; then
  usage
  exit 2
fi

TASK_ID=""
STATUS=""
OWNER=""
RETRIES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      STATE_FILE="${2:-}"
      shift 2
      ;;
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --status)
      STATUS="${2:-}"
      shift 2
      ;;
    --owner)
      OWNER="${2:-}"
      shift 2
      ;;
    --retries)
      RETRIES="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] unknown arg: $1"
      usage
      exit 2
      ;;
  esac
done

validate_status() {
  local s="$1"
  case "$s" in
    queued|running|checkpointed|passed|failed) ;;
    *)
      echo "[ERROR] invalid status: $s"
      exit 1
      ;;
  esac
}

ensure_state_dir() {
  mkdir -p "$(dirname "$STATE_FILE")"
}

init_state() {
  ensure_state_dir
  python3 - "$STATE_FILE" <<'PY'
import json
import sys
from datetime import datetime, timezone

path = sys.argv[1]
payload = {
    "version": 1,
    "updated_at": datetime.now(timezone.utc).isoformat(),
    "tasks": [],
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"[INFO] initialized: {path}")
PY
}

upsert_task() {
  if [[ -z "$TASK_ID" || -z "$STATUS" ]]; then
    echo "[ERROR] upsert requires --task-id and --status"
    exit 2
  fi
  validate_status "$STATUS"
  if [[ -z "$RETRIES" ]]; then
    RETRIES="0"
  fi
  ensure_state_dir

  python3 - "$STATE_FILE" "$TASK_ID" "$STATUS" "$OWNER" "$RETRIES" <<'PY'
import json
import sys
from datetime import datetime, timezone

path, task_id, status, owner, retries = sys.argv[1:]
now = datetime.now(timezone.utc).isoformat()

try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    data = {"version": 1, "updated_at": now, "tasks": []}

if "tasks" not in data or not isinstance(data["tasks"], list):
    data["tasks"] = []

found = False
for task in data["tasks"]:
    if task.get("task_id") == task_id:
        task["status"] = status
        if owner:
            task["owner"] = owner
        task["retries"] = int(retries)
        task["updated_at"] = now
        found = True
        break

if not found:
    data["tasks"].append({
        "task_id": task_id,
        "status": status,
        "owner": owner,
        "retries": int(retries),
        "updated_at": now,
    })

data["updated_at"] = now

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"[INFO] upserted task: {task_id} ({status})")
PY
}

set_status() {
  if [[ -z "$TASK_ID" || -z "$STATUS" ]]; then
    echo "[ERROR] set-status requires --task-id and --status"
    exit 2
  fi
  validate_status "$STATUS"

  python3 - "$STATE_FILE" "$TASK_ID" "$STATUS" <<'PY'
import json
import sys
from datetime import datetime, timezone

path, task_id, status = sys.argv[1:]
now = datetime.now(timezone.utc).isoformat()

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

if "tasks" not in data or not isinstance(data["tasks"], list):
    print("[ERROR] invalid state file: tasks is missing")
    sys.exit(1)

for task in data["tasks"]:
    if task.get("task_id") == task_id:
        task["status"] = status
        task["updated_at"] = now
        data["updated_at"] = now
        with open(path, "w", encoding="utf-8") as wf:
            json.dump(data, wf, ensure_ascii=False, indent=2)
            wf.write("\n")
        print(f"[INFO] updated status: {task_id} -> {status}")
        sys.exit(0)

print(f"[ERROR] task not found: {task_id}")
sys.exit(1)
PY
}

show_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "[ERROR] state file not found: $STATE_FILE"
    exit 1
  fi
  cat "$STATE_FILE"
}

case "$COMMAND" in
  init)
    init_state
    ;;
  upsert)
    upsert_task
    ;;
  set-status)
    set_status
    ;;
  show)
    show_state
    ;;
  *)
    echo "[ERROR] unknown command: $COMMAND"
    usage
    exit 2
    ;;
esac
