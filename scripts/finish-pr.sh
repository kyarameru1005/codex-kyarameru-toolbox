#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG=""
PR_TITLE=""
BASE_BRANCH="main"
DRAFT_MODE=0
SKIP_VERIFY=0
SKIP_BASE_SYNC=0
FILES=()

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/finish-pr.sh \
    --commit "<commit message>" \
    --pr "<pull request title>" \
    --file <path> [--file <path> ...] \
    [--base <branch>] [--draft] [--skip-verify] [--skip-base-sync]

Notes:
  - main ブランチ上では実行できません
  - --file で指定したファイルのみ stage します
  - 検証は既定で実行（pytest + policy-check）
USAGE
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      COMMIT_MSG="${2:-}"
      shift 2
      ;;
    --pr)
      PR_TITLE="${2:-}"
      shift 2
      ;;
    --file)
      FILES+=("${2:-}")
      shift 2
      ;;
    --base)
      BASE_BRANCH="${2:-}"
      shift 2
      ;;
    --draft)
      DRAFT_MODE=1
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY=1
      shift
      ;;
    --skip-base-sync)
      SKIP_BASE_SYNC=1
      shift
      ;;
    *)
      echo "[ERROR] unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$COMMIT_MSG" || -z "$PR_TITLE" ]]; then
  echo "[ERROR] --commit and --pr are required"
  usage
  exit 2
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "[ERROR] at least one --file is required"
  usage
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] not a git repository"
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "[ERROR] current branch is main. create/switch to a work branch first"
  exit 1
fi

echo "[INFO] repository health check"
bash scripts/repo-health-check.sh --strict

if [[ $SKIP_BASE_SYNC -eq 0 ]]; then
  echo "[INFO] check branch is up-to-date with origin/$BASE_BRANCH"
  git fetch origin "$BASE_BRANCH"
  if ! git merge-base --is-ancestor "origin/$BASE_BRANCH" HEAD; then
    echo "[ERROR] current branch is behind origin/$BASE_BRANCH"
    echo "[ERROR] rebase first: git rebase origin/$BASE_BRANCH"
    exit 1
  fi
else
  echo "[WARN] skip base sync check by --skip-base-sync"
fi

echo "[INFO] precheck"
bash toolbox/skills/git-pr-worker/scripts/pr-precheck.sh

if [[ $SKIP_VERIFY -eq 0 ]]; then
  echo "[INFO] run tests"
  if [[ -x ".venv/bin/python" ]]; then
    .venv/bin/python -m pytest -q
  else
    python3 -m pytest -q
  fi

  echo "[INFO] run secret check"
  bash scripts/secret-check.sh

  echo "[INFO] run policy check"
  bash scripts/policy-check.sh
else
  echo "[WARN] verification skipped by --skip-verify"
fi

echo "[INFO] stage selected files"
git add "${FILES[@]}"

if git diff --cached --quiet; then
  echo "[ERROR] no staged changes. check --file paths"
  exit 1
fi

echo "[INFO] commit"
git commit -m "$COMMIT_MSG"

echo "[INFO] push branch: $CURRENT_BRANCH"
git push -u origin "$CURRENT_BRANCH"

echo "[INFO] create PR"
if [[ $DRAFT_MODE -eq 1 ]]; then
  bash scripts/create-pr.sh "$PR_TITLE" --base "$BASE_BRANCH" --head "$CURRENT_BRANCH" --draft
else
  bash scripts/create-pr.sh "$PR_TITLE" --base "$BASE_BRANCH" --head "$CURRENT_BRANCH"
fi

echo "[DONE] finish-pr completed"
