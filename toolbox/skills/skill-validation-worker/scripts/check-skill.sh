#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-}"

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: bash toolbox/skills/skill-validation-worker/scripts/check-skill.sh <skill-dir>"
  exit 2
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "[ERROR] skill directory not found: $TARGET_DIR"
  exit 1
fi

SKILL_FILE="$TARGET_DIR/SKILL.md"
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "[ERROR] missing SKILL.md: $SKILL_FILE"
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

for pat in "目的" "推奨トリガー" "出力"; do
  if ! has_pattern "$pat" "$SKILL_FILE"; then
    echo "[ERROR] missing section/keyword in SKILL.md: $pat"
    exit 1
  fi
done

for bad in "適宜" "必要に応じて" "可能であれば" "状況に応じて"; do
  if has_pattern "$bad" "$SKILL_FILE"; then
    echo "[ERROR] ambiguous phrase found in SKILL.md: $bad"
    exit 1
  fi
done

SKILL_DIR_NAME="$(basename "$TARGET_DIR")"
if [[ "$SKILL_DIR_NAME" =~ _ ]]; then
  echo "[ERROR] skill directory should be kebab-case (no underscore): $TARGET_DIR"
  exit 1
fi

# Validate frontmatter `name` if present.
if has_pattern '^---$' "$SKILL_FILE"; then
  fm_name="$(
    awk '
      BEGIN { in_fm=0; seen=0 }
      /^---[[:space:]]*$/ {
        if (seen == 0) { in_fm=1; seen=1; next }
        if (in_fm == 1) { in_fm=0; exit }
      }
      in_fm == 1 && $0 ~ /^name:[[:space:]]*/ {
        sub(/^name:[[:space:]]*/, "", $0)
        print $0
        exit
      }
    ' "$SKILL_FILE"
  )"
  if [[ -n "$fm_name" ]] && [[ "$fm_name" != "$SKILL_DIR_NAME" ]]; then
    echo "[ERROR] frontmatter name must match directory name: $fm_name != $SKILL_DIR_NAME"
    exit 1
  fi
fi

if [[ -d "$TARGET_DIR/scripts" ]]; then
  while IFS= read -r -d '' script; do
    if [[ "$(basename "$script")" =~ _ ]]; then
      echo "[ERROR] script filename should be kebab-case: $script"
      exit 1
    fi
    if ! bash -n "$script"; then
      echo "[ERROR] invalid bash syntax: $script"
      exit 1
    fi
  done < <(find "$TARGET_DIR/scripts" -type f -name '*.sh' -print0)
fi

echo "[OK] skill validation passed: $TARGET_DIR"
