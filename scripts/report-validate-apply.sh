#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/report-validate-apply.sh \
    --title <kebab-case-title> \
    [--quick]

Options:
  --title   report title (required, kebab-case)
  --quick   skip pytest and run quick harness only
USAGE
}

TITLE=""
QUICK_MODE=0
PYTHON_BIN="${PYTHON_BIN:-python3}"

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

echo "[STEP] create report template"
bash toolbox/skills/harness-report-writer/scripts/write-report.sh \
  --title "$TITLE"

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

echo "[STEP] apply toolbox assets"
"$PYTHON_BIN" scripts/install.py update

echo "[DONE] report + validate + apply completed"
