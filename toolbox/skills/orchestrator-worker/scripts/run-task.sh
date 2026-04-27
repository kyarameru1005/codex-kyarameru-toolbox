#!/usr/bin/env bash
set -euo pipefail

TASK_ID=""
OWNER=""
TASK_COMMAND=""
CHECKPOINT_COMMAND=""
MAX_RETRIES=0
RETRY_BACKOFF_SEC=3
STATE_FILE="toolbox/harness/state/tasks.json"

usage() {
  cat <<'USAGE'
Usage:
  bash toolbox/skills/orchestrator-worker/scripts/run-task.sh \
    --task-id <id> \
    --owner <agent> \
    --command "<cmd>" \
    [--max-retries <n>] \
    [--retry-backoff-sec <sec>] \
    [--checkpoint-command "<cmd>"] \
    [--state-file <path>]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --owner)
      OWNER="${2:-}"
      shift 2
      ;;
    --command)
      TASK_COMMAND="${2:-}"
      shift 2
      ;;
    --checkpoint-command)
      CHECKPOINT_COMMAND="${2:-}"
      shift 2
      ;;
    --max-retries)
      MAX_RETRIES="${2:-}"
      shift 2
      ;;
    --retry-backoff-sec)
      RETRY_BACKOFF_SEC="${2:-}"
      shift 2
      ;;
    --state-file)
      STATE_FILE="${2:-}"
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

if [[ -z "$TASK_ID" || -z "$OWNER" || -z "$TASK_COMMAND" ]]; then
  echo "[ERROR] --task-id, --owner, --command are required"
  usage
  exit 2
fi

if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --max-retries must be integer >= 0: $MAX_RETRIES"
  exit 2
fi

if ! [[ "$RETRY_BACKOFF_SEC" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] --retry-backoff-sec must be integer >= 0: $RETRY_BACKOFF_SEC"
  exit 2
fi

ensure_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "[INFO] state file not found. initialize: $STATE_FILE"
    bash scripts/update-task-state.sh init --file "$STATE_FILE"
  fi
}

read_task_status() {
  python3 - "$STATE_FILE" "$TASK_ID" <<'PY'
import json
import sys

path, task_id = sys.argv[1:]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print("__NONE__")
    raise SystemExit(0)

for task in data.get("tasks", []):
    if task.get("task_id") == task_id:
        print(task.get("status", "__NONE__"))
        raise SystemExit(0)
print("__NONE__")
PY
}

read_task_retries() {
  python3 - "$STATE_FILE" "$TASK_ID" <<'PY'
import json
import sys

path, task_id = sys.argv[1:]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    print("0")
    raise SystemExit(0)

for task in data.get("tasks", []):
    if task.get("task_id") == task_id:
        retries = task.get("retries", 0)
        if isinstance(retries, int):
            print(retries)
        else:
            print(0)
        raise SystemExit(0)
print("0")
PY
}

run_with_report() {
  local label="$1"
  local command="$2"
  local rc=0

  echo "[$label] $command"
  set +e
  bash -lc "$command"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "[ERROR] phase failed: $label"
    echo "[ERROR] command: $command"
    echo "[ERROR] exit code: $rc"
    echo "[ERROR] reproduce: $command"
  fi
  return "$rc"
}

ensure_state
CURRENT_STATUS="$(read_task_status)"
CURRENT_RETRIES="$(read_task_retries)"

if [[ "$CURRENT_STATUS" == "__NONE__" ]]; then
  bash scripts/update-task-state.sh upsert \
    --file "$STATE_FILE" \
    --task-id "$TASK_ID" \
    --status queued \
    --owner "$OWNER" \
    --retries 0
  CURRENT_RETRIES=0
elif [[ "$CURRENT_STATUS" == "passed" ]]; then
  echo "[INFO] already passed: $TASK_ID"
  exit 0
fi

ATTEMPT="$CURRENT_RETRIES"

while true; do
  echo "[STEP] task=$TASK_ID attempt=$ATTEMPT/$MAX_RETRIES"
  bash scripts/update-task-state.sh set-status \
    --file "$STATE_FILE" \
    --task-id "$TASK_ID" \
    --status running

  if [[ -n "$CHECKPOINT_COMMAND" ]]; then
    if run_with_report "CHECKPOINT" "$CHECKPOINT_COMMAND"; then
      bash scripts/update-task-state.sh set-status \
        --file "$STATE_FILE" \
        --task-id "$TASK_ID" \
        --status checkpointed
      bash scripts/update-task-state.sh set-status \
        --file "$STATE_FILE" \
        --task-id "$TASK_ID" \
        --status running
    fi
  fi

  if run_with_report "TASK" "$TASK_COMMAND"; then
    bash scripts/update-task-state.sh set-status \
      --file "$STATE_FILE" \
      --task-id "$TASK_ID" \
      --status passed
    echo "[DONE] task passed: $TASK_ID"
    exit 0
  fi

  bash scripts/update-task-state.sh set-status \
    --file "$STATE_FILE" \
    --task-id "$TASK_ID" \
    --status failed

  if [[ "$ATTEMPT" -ge "$MAX_RETRIES" ]]; then
    echo "[ERROR] retry exhausted: task=$TASK_ID attempts=$ATTEMPT max=$MAX_RETRIES"
    exit 1
  fi

  ATTEMPT=$((ATTEMPT + 1))
  bash scripts/update-task-state.sh upsert \
    --file "$STATE_FILE" \
    --task-id "$TASK_ID" \
    --status queued \
    --owner "$OWNER" \
    --retries "$ATTEMPT"

  if [[ "$RETRY_BACKOFF_SEC" -gt 0 ]]; then
    echo "[INFO] retry backoff: ${RETRY_BACKOFF_SEC}s"
    sleep "$RETRY_BACKOFF_SEC"
  fi
done

