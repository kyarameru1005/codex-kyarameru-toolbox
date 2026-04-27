#!/bin/bash
# spawn-feature-agents.sh
# Feature 並列起動スクリプト
# D: collab mode（spawn_agent / wait_agent 経由で spec-orchestrator が制御）
# C: spawn_agents_on_csv（state-to-csv.py 実行 → Codex へ指示）
# A: codex exec --full-auto バックグラウンド（フォールバック）
set -euo pipefail

STATE_FILE="${1:-specs/project-state.json}"
MODE="${CODEX_SPAWN_MODE:-auto}"   # auto | collab | csv | file
SCRIPTS_DIR="${HOME}/.codex/scripts"

log() { echo "[spawn-feature-agents] $*" >&2; }

# === モード D: collab mode（spec-orchestrator が spawn_agent/wait_agent を使用）===
try_mode_d() {
    local config="${HOME}/.codex/config.toml"
    if [[ -f "$config" ]] && grep -q 'collab.*=.*true' "$config" 2>/dev/null; then
        log "Mode D: collab mode (spawn_agent / wait_agent)"
        local state_summary
        state_summary=$(python3 -c "
import sys, json
with open('${STATE_FILE}') as f:
    s = json.load(f)
features = s.get('features', [])
print('specs/project-state.json を読み、Wave ベースで全 Feature を並列実装してください。現在の状態: ' + json.dumps(features, ensure_ascii=False))
" 2>/dev/null || echo "specs/project-state.json を読み、Wave ベースで全 Feature を並列実装してください。")
        codex exec --agent spec-orchestrator \
            "$state_summary" \
            --full-auto
        return $?
    fi
    return 1
}

# === モード C: spawn_agents_on_csv ===
try_mode_c() {
    command -v python3 &>/dev/null || return 1
    local csv_script="${SCRIPTS_DIR}/state-to-csv.py"
    if [[ ! -f "$csv_script" ]]; then
        log "Mode C: state-to-csv.py not found at ${csv_script}"
        return 1
    fi
    log "Mode C: spawn_agents_on_csv"
    python3 "$csv_script" "$STATE_FILE"
    log "features.csv 生成完了。Codex の spawn_agents_on_csv で実行してください:"
    log "  ~/.codex/features.csv の各行に対し spec-feature-agent を並列起動し Phase 1-7 を実装"
    return 0
}

# === モード A: codex exec バックグラウンド（フォールバック）===
run_mode_a() {
    log "Mode A: codex exec バックグラウンド"

    if ! command -v codex &>/dev/null; then
        log "ERROR: codex command not found"
        exit 1
    fi
    if ! command -v python3 &>/dev/null; then
        log "ERROR: python3 not found"
        exit 1
    fi

    local PIDS=()
    local WORKTREES_DIR="${HOME}/.codex/worktrees"
    mkdir -p "$WORKTREES_DIR"

    # 実行可能な Feature を特定
    local READY
    READY=$(python3 - "$STATE_FILE" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    state = json.load(f)
done = {x["id"] for x in state["features"] if x["status"] == "done"}
for x in state["features"]:
    if x["status"] == "pending" and all(d in done for d in x.get("depends_on", [])):
        print(f"{x['id']}:{x.get('name', x['id'])}")
PYEOF
    )

    if [[ -z "$READY" ]]; then
        log "No pending features ready to run"
        return 0
    fi

    for entry in $READY; do
        local FID="${entry%%:*}"
        local FNAME="${entry##*:}"
        local WT_PATH="${WORKTREES_DIR}/${FID}"
        local DONE_FILE="${WT_PATH}/.feature-done.json"

        git worktree add "$WT_PATH" -b "feat/${FID}" 2>/dev/null || true

        # status を in_progress に更新
        python3 - "$STATE_FILE" "$FID" "in_progress" <<'PYEOF'
import json, sys
path, fid, status = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: s = json.load(f)
for x in s["features"]:
    if x["id"] == fid: x["status"] = status
with open(path, "w") as f: json.dump(s, f, indent=2, ensure_ascii=False)
PYEOF

        (
            cd "$WT_PATH"
            REPO_ROOT=$(git rev-parse --show-toplevel)
            codex exec --agent spec-feature-agent \
                "Feature ${FID}: specs/features/${FNAME}/ の tasks.md に従い Phase 1-7 を実装し、完了後に JSON を .feature-done.json に書き出す。" \
                --output-last-message "$DONE_FILE" \
                --full-auto 2>/dev/null || true
            STATUS=$(python3 -c \
                "import json; d=json.load(open('${DONE_FILE}')); print(d.get('status','failed'))" \
                2>/dev/null || echo "failed")
            python3 - "${REPO_ROOT}/${STATE_FILE}" "$FID" "$STATUS" <<'PYEOF'
import json, sys
path, fid, status = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f: s = json.load(f)
for x in s["features"]:
    if x["id"] == fid: x["status"] = status
with open(path, "w") as f: json.dump(s, f, indent=2, ensure_ascii=False)
PYEOF
        ) &
        PIDS+=($!)
        log "  ${FID} を起動 (PID: ${PIDS[-1]})"
    done

    for pid in "${PIDS[@]}"; do wait "$pid" || true; done

    # Audit Agent 起動
    log "Audit Agent 起動..."
    mkdir -p "$(dirname specs/audit/audit-report.md)"
    codex exec --agent spec-auditor \
        "specs/audit/audit-report.md を生成してください。" \
        --output-last-message "specs/audit/audit-report.md" \
        --full-auto || true
}

# メイン
if [[ "$MODE" == "auto" || "$MODE" == "collab" ]]; then
    try_mode_d && exit 0
fi
if [[ "$MODE" == "auto" || "$MODE" == "csv" ]]; then
    try_mode_c && exit 0
fi
run_mode_a
