#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="main"
ALLOW_DIRTY=0

usage() {
  echo "Usage: bash scripts/start-branch.sh <kind> <topic> [--base <branch>] [--allow-dirty]"
  echo "  kind: feat|fix|chore|docs|refactor|test"
  echo "  topic: kebab-case を推奨（例: skill-validation-flow）"
}

if [[ $# -lt 2 ]]; then
  usage
  exit 2
fi

KIND="$1"
TOPIC="$2"
shift 2

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_BRANCH="${2:-}"
      shift 2
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      shift
      ;;
    *)
      echo "[ERROR] unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

case "$KIND" in
  feat|fix|chore|docs|refactor|test) ;;
  *)
    echo "[ERROR] invalid kind: $KIND"
    usage
    exit 2
    ;;
esac

if [[ "$TOPIC" =~ _ ]]; then
  echo "[ERROR] topic must be kebab-case (no underscore): $TOPIC"
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] not a git repository"
  exit 1
fi

if [[ $ALLOW_DIRTY -eq 0 ]] && [[ -n "$(git status --porcelain)" ]]; then
  echo "[ERROR] working tree is not clean. commit/stash first or use --allow-dirty"
  exit 1
fi

TARGET_BRANCH="${KIND}/${TOPIC}"

echo "[INFO] switch to base branch: $BASE_BRANCH"
git switch "$BASE_BRANCH"

if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  echo "[INFO] branch already exists. switching: $TARGET_BRANCH"
  git switch "$TARGET_BRANCH"
else
  echo "[INFO] create branch: $TARGET_BRANCH"
  git switch -c "$TARGET_BRANCH"
fi

echo "[DONE] current branch: $(git branch --show-current)"
