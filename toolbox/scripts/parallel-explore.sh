#!/bin/bash
# parallel-explore.sh
# Usage: parallel-explore.sh <feature_dir> [query1] [query2] [query3]
# 3並列コードベース調査スクリプト。
# collab mode 有効時は orchestrator が spawn_agent(spec-explorer) × 3 を直接呼び出すため、
# このスクリプトは collab mode 無効環境向けフォールバック（codex exec バックグラウンド）として提供する。
set -euo pipefail

FEATURE_DIR="${1:-}"
Q1="${2:-コードベース全体構造}"
Q2="${3:-既存パターンと規約}"
Q3="${4:-依存関係とインターフェース}"
OUT="${HOME}/.codex/explore-results/${FEATURE_DIR:-unknown}"
TIMEOUT=300

if [[ -z "$FEATURE_DIR" ]]; then
    echo "Usage: parallel-explore.sh <feature_dir> [query1] [query2] [query3]" >&2
    exit 1
fi

mkdir -p "$OUT"

# codex コマンドが利用可能か確認
if ! command -v codex &>/dev/null; then
    echo "[parallel-explore] WARNING: codex command not found. Skipping exec mode." >&2
    exit 0
fi

# 3並列でバックグラウンド起動
for i in 1 2 3; do
    eval "Q=\$Q${i}"
    codex exec --agent spec-explorer \
        "調査: ${Q}。結果を ${OUT}/explore-${i}.md に書き出し、完了後 DONE と出力。" \
        --output-last-message "${OUT}/explore-${i}.md" \
        --full-auto && touch "${OUT}/explore-${i}.done" &
done

# 完了待機ループ（最大 TIMEOUT 秒）
for i in 1 2 3; do
    elapsed=0
    while [[ ! -f "${OUT}/explore-${i}.done" && $elapsed -lt $TIMEOUT ]]; do
        sleep 5
        elapsed=$((elapsed + 5))
    done
    if [[ -f "${OUT}/explore-${i}.done" ]]; then
        echo "[parallel-explore] explore-${i} completed" >&2
    else
        echo "[parallel-explore] explore-${i} timed out (${TIMEOUT}s)" >&2
    fi
done

# 結果を結合して出力
cat "${OUT}"/explore-*.md 2>/dev/null || echo "[parallel-explore] No results generated"
