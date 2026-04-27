#!/bin/bash
# Spec Project Status - project-state.json を読んで全 Feature の進捗を表示
# Usage: project-status.sh [project-state.json] [--json] [--brief]
#
# 引数1: project-state.json のパス（省略時は specs/project-state.json）
#
# オプション:
#   --json   結果を JSON で出力（機械処理用）
#   --brief  サマリのみ表示

set -euo pipefail

# デフォルト値
STATE_FILE="specs/project-state.json"
OUTPUT_JSON=false
OUTPUT_BRIEF=false

# 引数パース
for arg in "$@"; do
    case "$arg" in
        --json) OUTPUT_JSON=true ;;
        --brief) OUTPUT_BRIEF=true ;;
        *) STATE_FILE="$arg" ;;
    esac
done

# ============================================================================
# エラー処理
# ============================================================================
if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: project-state.json not found: $STATE_FILE" >&2
    exit 1
fi

# ============================================================================
# Python で JSON パース & 出力生成
# ============================================================================

# Python スクリプトを一時ファイルに書き出して実行（f-string エスケープ問題を回避）
PYTHON_SCRIPT=$(mktemp)
trap 'rm -f "$PYTHON_SCRIPT"' EXIT

cat > "$PYTHON_SCRIPT" << 'PYEOF'
import json, sys

state_file = sys.argv[1]
output_json = sys.argv[2] == "true"
output_brief = sys.argv[3] == "true"

try:
    with open(state_file, "r") as f:
        state = json.load(f)
except json.JSONDecodeError as e:
    print("Error: JSON parse error in {}: {}".format(state_file, e), file=sys.stderr)
    sys.exit(1)

project_name = state.get("project_name", "unknown")
integration_branch = state.get("integration_branch", "-")
project_status = state.get("status", "unknown")
concurrency = state.get("concurrency", {})
max_parallel = concurrency.get("max_parallel", 1)
features = state.get("features", {})
audit_results = state.get("audit_results", {})
merge_log = state.get("merge_log", [])

# ステータスアイコンマッピング
status_icons = {
    "merged": "\u2705",
    "in_progress": "\U0001f504",
    "queued": "\u23f3",
    "failed": "\u274c",
    "escalated": "\U0001f6a8",
    "pending": "\u23f3",
    "blocked": "\U0001f6ab",
}

# Feature をリストに変換し Wave 順にソート
feature_list = []
for name, info in features.items():
    feature_list.append({"name": name, **info})
feature_list.sort(key=lambda x: (x.get("wave", 999), x["name"]))

# 現在の in_progress 数をカウント
in_progress_count = sum(1 for ft in feature_list if ft.get("status") == "in_progress")

# ステータス別カウント
status_counts = {}
for ft in feature_list:
    s = ft.get("status", "unknown")
    status_counts[s] = status_counts.get(s, 0) + 1

total_features = len(feature_list)

# サマリ表示用の定義
summary_labels = [
    ("merged", "merged", "\u2705"),
    ("in_progress", "in_progress", "\U0001f504"),
    ("queued", "queued", "\u23f3"),
    ("failed", "failed", "\u274c"),
    ("escalated", "escalated", "\U0001f6a8"),
]

# === JSON 出力モード ===
if output_json:
    result = {
        "project_name": project_name,
        "integration_branch": integration_branch,
        "status": project_status,
        "concurrency": {"current": in_progress_count, "max_parallel": max_parallel},
        "features": [],
        "summary": {
            "total": total_features,
            "merged": status_counts.get("merged", 0),
            "in_progress": status_counts.get("in_progress", 0),
            "queued": status_counts.get("queued", 0),
            "failed": status_counts.get("failed", 0),
            "escalated": status_counts.get("escalated", 0),
        },
        "merge_log": merge_log,
    }
    for ft in feature_list:
        name = ft["name"]
        audit = audit_results.get(name, {})
        result["features"].append({
            "name": name,
            "issue_number": ft.get("issue_number"),
            "wave": ft.get("wave"),
            "status": ft.get("status"),
            "audit": audit.get("status", "-"),
            "retry_count": ft.get("retry_count", 0),
            "depends_on": ft.get("depends_on", []),
        })
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0)

# === Brief 出力モード ===
if output_brief:
    print("=== Project Status: {} ===".format(project_name))
    print()
    print("Status: {}".format(project_status))
    print("Concurrency: {}/{}".format(in_progress_count, max_parallel))
    print()
    print("--- Summary ---")
    print("Total: {} features".format(total_features))
    for label, key, icon in summary_labels:
        count = status_counts.get(key, 0)
        print("  {} {}: {}".format(icon, label, count))
    sys.exit(0)

# === 通常出力モード ===
print("=== Project Status: {} ===".format(project_name))
print()
print("Integration branch: {}".format(integration_branch))
print("Status: {}".format(project_status))
print("Concurrency: {}/{}".format(in_progress_count, max_parallel))
print()

# --- Features テーブル ---
print("--- Features ---")
print()

# カラム幅を計算
name_width = max((len(ft["name"]) for ft in feature_list), default=7)
name_width = max(name_width, 7)  # "Feature" の最低幅

# status_width: テキスト部分のみ（アイコン+スペース分は別途加算）
max_status_len = max((len(ft.get("status", "")) for ft in feature_list), default=6)
status_width = max(max_status_len + 3, 12)  # +3 for icon + space

audit_width = 6
depends_width = max(
    (len(", ".join(ft.get("depends_on", []))) for ft in feature_list),
    default=10,
)
depends_width = max(depends_width, 10)

# ヘッダ
fmt = "| {:<" + str(name_width) + "} | {:>5} | {:>4} | {:<" + str(status_width) + "} | {:<" + str(audit_width) + "} | {:>5} | {:<" + str(depends_width) + "} |"

print(fmt.format("Feature", "Issue", "Wave", "Status", "Audit", "Retry", "Depends on"))
print("|{}|{}|{}|{}|{}|{}|{}|".format(
    "-" * (name_width + 2),
    "-" * 7,
    "-" * 6,
    "-" * (status_width + 2),
    "-" * (audit_width + 2),
    "-" * 7,
    "-" * (depends_width + 2),
))

for ft in feature_list:
    name = ft["name"]
    issue_num = ft.get("issue_number", "-")
    issue_str = "#{}".format(issue_num)
    wave = str(ft.get("wave", "-"))
    status_raw = ft.get("status", "unknown")
    icon = status_icons.get(status_raw, "?")

    audit_info = audit_results.get(name, {})
    audit_status = audit_info.get("status", "-")
    retry = str(ft.get("retry_count", 0))
    depends = ", ".join(ft.get("depends_on", []))

    # ステータス表示: アイコン(絵文字)は端末で幅2だが len() では1文字
    # status_width 分のパディングを手動計算
    status_text = "{} {}".format(icon, status_raw)
    # 絵文字1文字分の余分な幅を考慮してパディング
    pad = status_width - len(status_raw) - 2
    if pad < 0:
        pad = 0
    status_padded = "{} {}{}".format(icon, status_raw, " " * pad)

    print("| {:<{nw}} | {:>5} | {:>4} | {} | {:<{aw}} | {:>5} | {:<{dw}} |".format(
        name, issue_str, wave, status_padded, audit_status, retry, depends,
        nw=name_width, aw=audit_width, dw=depends_width,
    ))

print()

# --- Summary ---
print("--- Summary ---")
print("Total: {} features".format(total_features))
for label, key, icon in summary_labels:
    count = status_counts.get(key, 0)
    print("  {} {}: {}".format(icon, label, count))

# --- Recent Merge Log ---
if merge_log:
    print()
    print("--- Recent Merge Log ---")
    for entry in merge_log[-10:]:  # 直近10件
        feature_name = entry.get("feature", "unknown")
        merged_at = entry.get("merged_at", "-")
        conflict = entry.get("conflict", False)
        conflict_str = "conflict" if conflict else "no conflict"
        print("  {} \u2192 merged at {} ({})".format(feature_name, merged_at, conflict_str))
PYEOF

python3 "$PYTHON_SCRIPT" "$STATE_FILE" "$OUTPUT_JSON" "$OUTPUT_BRIEF"
