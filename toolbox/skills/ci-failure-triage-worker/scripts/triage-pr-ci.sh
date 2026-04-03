#!/usr/bin/env bash
set -euo pipefail

PR_NUMBER="${1:-}"

usage() {
  echo "Usage: bash toolbox/skills/ci-failure-triage-worker/scripts/triage-pr-ci.sh <pr-number|current>"
}

if [[ -z "$PR_NUMBER" ]]; then
  usage
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] gh command is required"
  exit 127
fi

if [[ "$PR_NUMBER" == "current" ]]; then
  PR_NUMBER="$(gh pr view --json number -q .number)"
fi

echo "[INFO] PR: #$PR_NUMBER"
echo "[INFO] checks summary"
CHECKS_OUTPUT="$(gh pr checks "$PR_NUMBER" || true)"
printf '%s\n' "$CHECKS_OUTPUT"

echo "[INFO] failed checks"
FAILED_LINES="$(printf '%s\n' "$CHECKS_OUTPUT" | rg "\bfail\b" || true)"
if [[ -z "$FAILED_LINES" ]]; then
  echo "[OK] no failed checks found"
  exit 0
fi
printf '%s\n' "$FAILED_LINES"

echo "[INFO] suggested local reproduction commands"
if printf '%s\n' "$FAILED_LINES" | rg -qi "\btests\b"; then
  echo "- .venv/bin/python -m pytest -q"
fi
if printf '%s\n' "$FAILED_LINES" | rg -qi "\bharness\b"; then
  echo "- bash scripts/harness.sh"
fi
if printf '%s\n' "$FAILED_LINES" | rg -qi "agents-policy|policy"; then
  echo "- bash scripts/policy-check.sh"
fi

echo "[INFO] next actions"
echo "1. 失敗ジョブのURLを開いて先頭エラーを特定"
echo "2. ローカル再現コマンドで再現"
echo "3. 修正後に同コマンド再実行してから push"
