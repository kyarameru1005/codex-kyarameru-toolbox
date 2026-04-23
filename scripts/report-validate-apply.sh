#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/report-validate-apply.sh \
    --title <kebab-case-title> \
    [--worker auto|lite|standard] \
    [--apply] \
    [--quick]

Options:
  --title   report title (required, kebab-case)
  --worker  worker selector (default: auto)
  --apply   apply toolbox assets (~/.codex) after checks
  --quick   skip pytest and run quick harness only
USAGE
}

TITLE=""
QUICK_MODE=0
APPLY_MODE=0
PYTHON_BIN="${PYTHON_BIN:-python3}"
START_TS="$(date +%s)"
START_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPORT_PATH=""
METRICS_ENABLED=0
WORKER_MODE="auto"
SELECTED_WORKER=""
CHANGED_FILES_COUNT=0
ESTIMATED_DIFF_LINES=0

write_metrics() {
  local rc="$1"
  local end_ts end_at duration mode status metrics_dir metrics_file
  end_ts="$(date +%s)"
  end_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  duration="$((end_ts - START_TS))"
  mode="full"
  status="failed"
  metrics_dir="docs/harness-reports/metrics"
  metrics_file="$metrics_dir/$(date +%Y-%m).jsonl"

  if [[ $QUICK_MODE -eq 1 ]]; then
    mode="quick"
  fi
  if [[ "$rc" -eq 0 ]]; then
    status="passed"
  fi

  mkdir -p "$metrics_dir"
  printf '{"timestamp":"%s","title":"%s","mode":"%s","status":"%s","exit_code":%s,"duration_sec":%s,"report_path":"%s","worker":"%s","changed_files":%s,"estimated_diff_lines":%s,"started_at":"%s","finished_at":"%s"}\n' \
    "$end_at" "$TITLE" "$mode" "$status" "$rc" "$duration" "$REPORT_PATH" "$SELECTED_WORKER" "$CHANGED_FILES_COUNT" "$ESTIMATED_DIFF_LINES" "$START_AT" "$end_at" >> "$metrics_file"
  echo "[INFO] metrics recorded: $metrics_file"
}

on_exit() {
  local rc="$?"
  if [[ "$METRICS_ENABLED" -ne 1 ]]; then
    return 0
  fi
  set +e
  write_metrics "$rc"
}

trap on_exit EXIT

compute_changed_files_count() {
  CHANGED_FILES_COUNT="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [[ -z "$CHANGED_FILES_COUNT" ]]; then
    CHANGED_FILES_COUNT=0
  fi
}

compute_estimated_diff_lines() {
  local lines
  lines="$(git diff --numstat HEAD 2>/dev/null | awk '{s += $1 + $2} END {print s+0}')"
  if [[ -z "$lines" ]]; then
    lines=0
  fi
  ESTIMATED_DIFF_LINES="$lines"
}

select_worker() {
  local needs_pytest=1

  if [[ $QUICK_MODE -eq 1 ]]; then
    needs_pytest=0
  fi

  compute_changed_files_count
  compute_estimated_diff_lines

  case "$WORKER_MODE" in
    lite)
      SELECTED_WORKER="harness-worker-lite"
      ;;
    standard)
      SELECTED_WORKER="harness-worker"
      ;;
    auto)
      if [[ "$CHANGED_FILES_COUNT" -le 2 && "$ESTIMATED_DIFF_LINES" -le 150 && "$needs_pytest" -eq 0 ]]; then
        SELECTED_WORKER="harness-worker-lite"
      else
        SELECTED_WORKER="harness-worker"
      fi
      ;;
    *)
      echo "[ERROR] invalid --worker: $WORKER_MODE"
      usage
      exit 2
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --quick)
      QUICK_MODE=1
      shift
      ;;
    --worker)
      WORKER_MODE="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY_MODE=1
      shift
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

if [[ -z "$TITLE" ]]; then
  echo "[ERROR] --title is required"
  usage
  exit 2
fi

if [[ "$TITLE" =~ _ ]]; then
  echo "[ERROR] --title must be kebab-case (no underscore): $TITLE"
  exit 1
fi

if [[ "$TITLE" =~ [^a-z0-9-] ]]; then
  echo "[ERROR] --title must contain only lowercase letters, numbers, and hyphen: $TITLE"
  exit 1
fi

if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "[ERROR] python not found: $PYTHON_BIN"
  exit 127
fi

METRICS_ENABLED=1
select_worker
echo "[STEP] select worker: $SELECTED_WORKER (mode=$WORKER_MODE, changed_files=$CHANGED_FILES_COUNT, estimated_diff_lines=$ESTIMATED_DIFF_LINES, quick=$QUICK_MODE)"

echo "[STEP] create report template"
report_output="$(
  bash toolbox/skills/harness-report-writer/scripts/write-report.sh \
    --title "$TITLE"
)"
echo "$report_output"
REPORT_PATH="$(printf '%s\n' "$report_output" | sed -n 's/^\[INFO\] report created: //p' | tail -n 1)"
if [[ -z "$REPORT_PATH" ]]; then
  echo "[ERROR] failed to detect report path"
  exit 1
fi

echo "[STEP] policy check"
bash scripts/policy-check.sh

if [[ $QUICK_MODE -eq 1 ]]; then
  echo "[STEP] quick harness"
  bash scripts/harness.sh --quick
else
  echo "[STEP] tests"
  "$PYTHON_BIN" -m pytest -q

  echo "[STEP] full harness"
  bash scripts/harness.sh
fi

if [[ $APPLY_MODE -eq 1 ]]; then
  echo "[STEP] apply toolbox assets"
  "$PYTHON_BIN" scripts/install.py update
else
  echo "[STEP] skip apply (use --apply to reflect into ~/.codex)"
fi

echo "[DONE] report + validate + apply completed"
