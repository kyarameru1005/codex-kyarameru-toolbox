#!/usr/bin/env bash
set -euo pipefail

BODY_FILE=""
PR_NUMBER=""

usage() {
  echo "Usage:"
  echo "  bash toolbox/skills/pr-quality-gate-worker/scripts/check-pr-quality.sh --body-file <file>"
  echo "  bash toolbox/skills/pr-quality-gate-worker/scripts/check-pr-quality.sh --pr <number>"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --body-file)
      BODY_FILE="${2:-}"
      shift 2
      ;;
    --pr)
      PR_NUMBER="${2:-}"
      shift 2
      ;;
    *)
      echo "[ERROR] unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -n "$BODY_FILE" && -n "$PR_NUMBER" ]]; then
  echo "[ERROR] choose either --body-file or --pr"
  exit 2
fi

if [[ -z "$BODY_FILE" && -z "$PR_NUMBER" ]]; then
  usage
  exit 2
fi

TMP_FILE=""
if [[ -n "$PR_NUMBER" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "[ERROR] gh command is required when using --pr"
    exit 127
  fi
  TMP_FILE="$(mktemp)"
  gh pr view "$PR_NUMBER" --json body -q .body > "$TMP_FILE"
  TARGET_FILE="$TMP_FILE"
else
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "[ERROR] body file not found: $BODY_FILE"
    exit 1
  fi
  TARGET_FILE="$BODY_FILE"
fi

has_pattern() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -Eq "$pattern" "$file"
  fi
}

missing=0
if ! has_pattern "^## 目的" "$TARGET_FILE"; then
  echo "[ERROR] missing section: 目的"
  missing=1
fi
if ! has_pattern "^## 主な変更点" "$TARGET_FILE"; then
  echo "[ERROR] missing section: 主な変更点"
  missing=1
fi
if ! has_pattern "^## 検証結果" "$TARGET_FILE"; then
  echo "[ERROR] missing section: 検証結果"
  missing=1
fi
if ! has_pattern "実行コマンド|command" "$TARGET_FILE"; then
  echo "[WARN] 検証結果に実行コマンドの記載が見つかりません"
fi

if [[ -n "$TMP_FILE" ]]; then
  rm -f "$TMP_FILE"
fi

if [[ $missing -ne 0 ]]; then
  echo "[FAIL] PR quality gate failed"
  exit 1
fi

echo "[OK] PR quality gate passed"
