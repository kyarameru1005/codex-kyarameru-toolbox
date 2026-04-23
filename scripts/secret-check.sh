#!/usr/bin/env bash
set -euo pipefail

PATTERNS_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/secret-check.sh [--patterns-only]

Options:
  --patterns-only  skip gitleaks and run regex-based checks only
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patterns-only)
      PATTERNS_ONLY=1
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

TMP_LIST="$(mktemp)"
trap 'rm -f "$TMP_LIST"' EXIT

build_target_list() {
  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] || continue
    case "$f" in
      .venv/*|.git/*|.pytest_cache/*|__pycache__/*|dist/*|build/*|htmlcov/*|ai_log/*)
        continue
        ;;
      toolbox/sessions/*|toolbox/vendor_imports/*|toolbox/plugins/cache/*|toolbox/cache/*|toolbox/tmp/*|toolbox/log/*|toolbox/.codex/*|toolbox/.tmp/*)
        continue
        ;;
    esac
    printf '%s\0' "$f"
  done < <(git ls-files -z --cached --others --exclude-standard)
}

echo "[CHECK] build target file list"
build_target_list > "$TMP_LIST"
echo "[OK] target files prepared"

if [[ $PATTERNS_ONLY -eq 0 ]]; then
  if command -v gitleaks >/dev/null 2>&1; then
    echo "[CHECK] gitleaks detect"
    gitleaks detect --no-git --source . --config scripts/gitleaks.toml --redact --exit-code 1
    echo "[OK] gitleaks detect"
  else
    echo "[WARN] gitleaks not found; skip gitleaks detect (patterns-only checks will run)"
  fi
fi

run_pattern_check() {
  local pattern="$1"
  local label="$2"
  echo "[CHECK] $label"
  if command -v rg >/dev/null 2>&1; then
    if xargs -0 rg -n --pcre2 --color=never -- "$pattern" < "$TMP_LIST"; then
      echo "[ERROR] detected by pattern: $label"
      exit 1
    fi
  else
    if xargs -0 grep -nE -- "$pattern" < "$TMP_LIST"; then
      echo "[ERROR] detected by pattern: $label"
      exit 1
    fi
  fi
  echo "[OK] $label"
}

run_pattern_check '/Users/[A-Za-z0-9._-]+' "no absolute user home path"
run_pattern_check 'https://discord\.com/api/webhooks/[0-9]{17,}/[A-Za-z0-9_-]{20,}' "no discord webhook URL"
run_pattern_check 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}' "no github personal token"
run_pattern_check 'AKIA[0-9A-Z]{16}' "no AWS access key pattern"
run_pattern_check '-----BEGIN (RSA|EC|OPENSSH|DSA|PGP)? ?PRIVATE KEY-----' "no private key block"
run_pattern_check 'sk-[A-Za-z0-9]{20,}' "no OpenAI-style API key pattern"

echo "[DONE] secret checks passed"
