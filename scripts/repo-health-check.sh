#!/usr/bin/env bash
set -euo pipefail

STRICT=0
CHECK_OWNERSHIP=1
ALLOW_DETACHED=0

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/repo-health-check.sh [--strict] [--skip-ownership] [--allow-detached]

Options:
  --strict          fail when warnings are detected
  --skip-ownership  skip owner check under toolbox runtime directories
  --allow-detached  do not warn on detached HEAD
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=1
      shift
      ;;
    --skip-ownership)
      CHECK_OWNERSHIP=0
      shift
      ;;
    --allow-detached)
      ALLOW_DETACHED=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] not a git repository"
  exit 1
fi

warn_count=0

warn() {
  warn_count=$((warn_count + 1))
  echo "[WARN] $1"
}

branch="$(git branch --show-current || true)"
if [[ -z "$branch" && $ALLOW_DETACHED -eq 0 ]]; then
  warn "detached HEAD detected. switch to a named branch first"
fi

if [[ $CHECK_OWNERSHIP -eq 1 ]]; then
  user_name="$(id -un)"
  group_name="$(id -gn)"
  owner_dirs=(
    toolbox/cache
    toolbox/hooks
    toolbox/mcp
    toolbox/plugins
    toolbox/prompts
    toolbox/scripts
    toolbox/vendor_imports
  )

  bad_owner_found=0
  for d in "${owner_dirs[@]}"; do
    if [[ -d "$d" ]] && find "$d" \! -user "$user_name" -print -quit | grep -q .; then
      bad_owner_found=1
      break
    fi
  done

  if [[ $bad_owner_found -eq 1 ]]; then
    warn "non-user-owned files found under toolbox runtime dirs"
    echo "[INFO] suggested fix:"
    printf '  sudo chown -R %s:%s %s\n' "$user_name" "$group_name" "${owner_dirs[*]}"
  fi
fi

if [[ $warn_count -eq 0 ]]; then
  echo "[OK] repository health check passed"
  exit 0
fi

if [[ $STRICT -eq 1 ]]; then
  echo "[ERROR] repository health check failed with $warn_count warning(s)"
  exit 1
fi

echo "[WARN] repository health check completed with $warn_count warning(s)"
