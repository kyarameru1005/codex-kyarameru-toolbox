#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-docs/repository-layout.md}"
AGENTS_FILE="${2:-AGENTS.md}"
ERROR_COUNT=0
WARN_COUNT=0

if [[ ! -f "$TARGET" ]]; then
  echo "[ERROR] file not found: $TARGET"
  exit 1
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

add_error() {
  local msg="$1"
  ERROR_COUNT=$((ERROR_COUNT + 1))
  echo "[ERROR] $msg"
}

add_warn() {
  local msg="$1"
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "[WARN] $msg"
}

required_patterns=(
  "^# Repository Layout"
  "^## 構成"
  "^## 管理対象"
  "^## Git 管理しないもの"
  "^## 変更時の確認"
  "docs/repository-layout\\.md|主要ディレクトリの責務|Git 管理方針"
)

for pat in "${required_patterns[@]}"; do
  if ! has_pattern "$pat" "$TARGET"; then
    add_error "missing required section/keyword: $pat"
  fi
done

for bad in "適宜" "可能であれば" "状況に応じて"; do
  if has_pattern "$bad" "$TARGET"; then
    add_warn "ambiguous phrase found: $bad"
  fi
done

if ! has_pattern '^```text$' "$TARGET"; then
  add_error "missing tree code block (text fenced block)"
fi

if ! has_pattern '^[│├└].*# ' "$TARGET"; then
  add_error "missing tree entries with inline responsibility comments"
fi

if ! has_pattern 'docs/' "$TARGET"; then
  add_warn "docs/ entry not found in structure section"
fi

if ! has_pattern 'scripts/' "$TARGET"; then
  add_warn "scripts/ entry not found in structure section"
fi

if ! has_pattern 'toolbox/' "$TARGET"; then
  add_warn "toolbox/ entry not found in structure section"
fi

if ! has_pattern 'cache|session|sqlite|tmp|egg-info|__pycache__' "$TARGET"; then
  add_warn "Git 管理しないものの具体例が少ない可能性があります"
fi

if [[ -f "$AGENTS_FILE" ]]; then
  if ! has_pattern 'docs/repository-layout\.md' "$AGENTS_FILE"; then
    add_warn "AGENTS.md does not reference docs/repository-layout.md"
  fi
else
  add_warn "AGENTS file not found for consistency check: $AGENTS_FILE"
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  echo "[SUMMARY] ERROR: $ERROR_COUNT, WARN: $WARN_COUNT"
  exit 1
fi

echo "[SUMMARY] ERROR: $ERROR_COUNT, WARN: $WARN_COUNT"
echo "[OK] repository-layout check passed: $TARGET"
