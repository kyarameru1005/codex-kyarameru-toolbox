#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash toolbox/skills/harness-report-writer/scripts/write-report.sh \
    [--title <kebab-case-title>]
USAGE
}

TITLE=""
NOW_DATE="$(date +%F)"
NOW_TIME="$(date +%H:%M:%S)"
STAMP="$(date +%Y%m%d-%H%M%S)"
CONCLUSION=""
WORK_DONE=""
ISSUES=""
NEXT_ACTIONS=""
VERIFY_CMD=""
VERIFY_RESULT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
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

prompt_field() {
  local label="$1"
  local value=""
  while true; do
    printf "%s: " "$label" >&2
    read -r value
    if [[ -n "$value" ]]; then
      printf "%s" "$value"
      return 0
    fi
    echo "[ERROR] empty input is not allowed" >&2
  done
}

if [[ -z "$TITLE" ]]; then
  TITLE="$(prompt_field "タイトル(kebab-case)")"
fi

if [[ "$TITLE" =~ _ ]]; then
  echo "[ERROR] title must be kebab-case (no underscore): $TITLE"
  exit 1
fi

if [[ "$TITLE" =~ [^a-z0-9-] ]]; then
  echo "[ERROR] title must contain only lowercase letters, numbers, and hyphen: $TITLE"
  exit 1
fi

CONCLUSION="$(prompt_field "結論")"
WORK_DONE="$(prompt_field "実施内容")"
ISSUES="$(prompt_field "課題")"
NEXT_ACTIONS="$(prompt_field "次アクション")"
VERIFY_CMD="$(prompt_field "検証コマンド")"
VERIFY_RESULT="$(prompt_field "検証結果")"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
OUT_DIR="$ROOT_DIR/docs/harness-reports"
OUT_FILE="$OUT_DIR/${STAMP}-${TITLE}.md"

mkdir -p "$OUT_DIR"

if [[ -f "$OUT_FILE" ]]; then
  echo "[ERROR] report already exists: $OUT_FILE"
  exit 1
fi

cat > "$OUT_FILE" <<REPORT
# Harness Report (${NOW_DATE} ${NOW_TIME}) - ${TITLE}

## 結論
- ${CONCLUSION}

## 実施内容
- ${WORK_DONE}

## 課題
- ${ISSUES}

## 次アクション
- ${NEXT_ACTIONS}

## 検証
- 実行コマンド: ${VERIFY_CMD}
- 結果: ${VERIFY_RESULT}
REPORT

echo "[INFO] report created: $OUT_FILE"
