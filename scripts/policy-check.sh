#!/usr/bin/env bash
set -euo pipefail

check_file() {
  local path="$1"
  echo "[CHECK] file exists: $path"
  if [[ ! -f "$path" ]]; then
    echo "[ERROR] missing file: $path"
    exit 1
  fi
  echo "[OK] file exists: $path"
}

check_pattern() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  echo "[CHECK] $label"
  if command -v rg >/dev/null 2>&1; then
    if ! rg -q "$pattern" "$path"; then
      echo "[ERROR] pattern not found: $label"
      echo "[ERROR] file: $path"
      exit 1
    fi
  else
    if ! grep -Eq "$pattern" "$path"; then
      echo "[ERROR] pattern not found: $label"
      echo "[ERROR] file: $path"
      exit 1
    fi
  fi
  echo "[OK] $label"
}

check_file "AGENTS.md"
check_file "toolbox/AGENTS.md"
check_file ".github/workflows/tests.yml"
check_file "scripts/secret-check.sh"
check_file "scripts/gitleaks.toml"
check_file "toolbox/skills/agents-md-writer/scripts/check_agents_md.sh"
check_file "toolbox/skills/skill-validation-worker/scripts/check-skill.sh"
check_file "toolbox/skills/ci-failure-triage-worker/scripts/triage-pr-ci.sh"
check_file "toolbox/skills/pr-quality-gate-worker/scripts/check-pr-quality.sh"
check_file "toolbox/skills/harness-report-writer/SKILL.md"
check_file "toolbox/skills/orchestrator-worker/SKILL.md"
check_file "docs/pr-template.md"
check_file "scripts/create-pr.sh"

echo "[CHECK] validate AGENTS.md files"
bash toolbox/skills/agents-md-writer/scripts/check_agents_md.sh AGENTS.md
bash toolbox/skills/agents-md-writer/scripts/check_agents_md.sh toolbox/AGENTS.md
echo "[OK] AGENTS.md validation"

WORKFLOW_FILE=".github/workflows/tests.yml"
check_pattern "^jobs:" "$WORKFLOW_FILE" "workflow has jobs section"
check_pattern "^  tests:" "$WORKFLOW_FILE" "workflow has tests job"
check_pattern "^  secret-scan:" "$WORKFLOW_FILE" "workflow has secret-scan job"
check_pattern "^  harness:" "$WORKFLOW_FILE" "workflow has harness job"
check_pattern "^  agents-policy:" "$WORKFLOW_FILE" "workflow has agents-policy job"
check_pattern "bash scripts/harness\\.sh" "$WORKFLOW_FILE" "workflow runs harness"
check_pattern "bash scripts/secret-check\\.sh --patterns-only" "$WORKFLOW_FILE" "workflow runs regex secret check"

HARNESS_FILE="scripts/harness.sh"
check_pattern "bash scripts/secret-check\\.sh" "$HARNESS_FILE" "harness runs secret-check"

PR_TEMPLATE_FILE="docs/pr-template.md"
check_pattern "^## 目的" "$PR_TEMPLATE_FILE" "pr template has 目的 section"
check_pattern "^## 主な変更点" "$PR_TEMPLATE_FILE" "pr template has 主な変更点 section"
check_pattern "^## 検証結果" "$PR_TEMPLATE_FILE" "pr template has 検証結果 section"

echo "[CHECK] harness-report-writer location is toolbox/skills only"
harness_locations="$(
  (
    find . -type d -name 'harness-report-writer' \
      -not -path './.git/*' \
      -not -path './.venv/*' \
      -not -path './toolbox/tmp/*' \
      -not -path './toolbox/.codex/*' \
      -not -path './toolbox/.tmp/*' \
      2>/dev/null || true
  ) \
    | sed 's#^\./##' \
    | sort
)"
if [[ "$harness_locations" != "toolbox/skills/harness-report-writer" ]]; then
  echo "[ERROR] harness-report-writer must exist only at toolbox/skills/harness-report-writer"
  echo "[ERROR] found:"
  printf '%s\n' "$harness_locations"
  exit 1
fi
echo "[OK] harness-report-writer location"

echo "[DONE] policy checks passed"
