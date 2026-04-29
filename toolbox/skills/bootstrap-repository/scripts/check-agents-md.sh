#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-AGENTS.md}"
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

required_patterns=(
  "目的"
  "優先"
  "応答"
  "実行"
  "Git"
  "ログ"
  "命名"
)

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

for pat in "${required_patterns[@]}"; do
  if ! has_pattern "$pat" "$TARGET"; then
    add_error "missing required section/keyword: $pat"
  fi
done

for bad in "適宜" "必要に応じて" "可能であれば" "状況に応じて"; do
  if has_pattern "$bad" "$TARGET"; then
    add_error "ambiguous phrase found: $bad"
  fi
done

if ! has_pattern "kebab-case|ハイフン" "$TARGET"; then
  add_error "missing naming rule (kebab-case/hyphen)"
fi

# Done条件相当の存在確認（完了条件、または検証結果報告の明示）
if ! has_pattern "Done|完了条件|Done条件|完了とする|検証結果" "$TARGET"; then
  add_error "missing done criteria (Done条件/完了条件/検証結果相当)"
fi

# 検証実行または未実行理由の明示
if ! has_pattern "テスト|test|lint|typecheck|検証.*(実行|結果)|未実行.*理由|理由.*未実行" "$TARGET"; then
  add_error "missing verification execution rule (run checks or state reason when skipped)"
fi

# 破壊的操作制約
if ! has_pattern "git reset --hard|破壊的操作|強制上書き|force push|履歴改変" "$TARGET"; then
  add_error "missing destructive operation constraints"
fi

# 推奨: 報告フォーマット
if ! has_pattern "Report format|報告フォーマット|変更(した)?ファイル.*検証結果|検証結果.*残課題|人間が確認すべき点" "$TARGET"; then
  add_warn "missing report format guidance (変更ファイル/検証結果/残課題 など)"
fi

# 推奨: 変更範囲/注意範囲
if ! has_pattern "変更可能範囲|変更してよい範囲|変更注意範囲|注意範囲|影響範囲|変更不可|禁止事項" "$TARGET"; then
  add_warn "missing editable/sensitive scope guidance"
fi

# 推奨: PR本文正本
if ! has_pattern "PR本文.*正本|正本.*PR本文" "$TARGET"; then
  add_warn "PR本文を正本とする記述が見つかりません"
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  echo "[SUMMARY] ERROR: $ERROR_COUNT, WARN: $WARN_COUNT"
  exit 1
fi

echo "[SUMMARY] ERROR: $ERROR_COUNT, WARN: $WARN_COUNT"
echo "[OK] AGENTS.md check passed: $TARGET"
