#!/bin/bash
# Research Cron - 夜間バッチで AI プロダクト研究ループを実行
#
# Usage:
#   research-cron.sh [project_dir]
#
# crontab 設定例:
#   0 2 * * 1-5 bash ~/.claude/skills/spec-research/scripts/research-cron.sh /path/to/project
#
# 注意:
#   - claude CLI がインストール済みであること
#   - --permission-mode auto で起動（自律実行のため）
#   - ログは research/.research-cron.log に出力

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
LOG_DIR="${PROJECT_DIR}/research"
LOG_FILE="${LOG_DIR}/.research-cron.log"
LOCK_FILE="${PROJECT_DIR}/.research-cron.lock"

# ============================================================================
# ロックファイルチェック（二重実行防止）
# ============================================================================
if [[ -f "$LOCK_FILE" ]]; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[$(date)] Research cron already running (PID: $OLD_PID)" >> "$LOG_FILE"
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ============================================================================
# ログディレクトリ確認
# ============================================================================
mkdir -p "$LOG_DIR"

echo "[$(date)] ========================================" >> "$LOG_FILE"
echo "[$(date)] Research Cron Started" >> "$LOG_FILE"
echo "[$(date)] Project: $PROJECT_DIR" >> "$LOG_FILE"
echo "[$(date)] ========================================" >> "$LOG_FILE"

# ============================================================================
# Phase 1: 研究ループ実行（メイン）
# ============================================================================
echo "[$(date)] Starting research loop..." >> "$LOG_FILE"

cd "$PROJECT_DIR"

# claude CLI で研究ループを実行
# --permission-mode auto: 自律実行（ファイル操作を自動許可）
# --model sonnet: コスト効率（重い分析のみ内部で opus を使用）
echo "/spec research run" | claude \
    --permission-mode auto \
    --print \
    2>> "$LOG_FILE" \
    | tee -a "$LOG_FILE" \
    || {
        echo "[$(date)] ERROR: Research loop failed" >> "$LOG_FILE"
        # 失敗しても digest は試みる
    }

echo "[$(date)] Research loop completed" >> "$LOG_FILE"

# ============================================================================
# Phase 2: Morning Digest 生成（軽量）
# ============================================================================
echo "[$(date)] Generating digest..." >> "$LOG_FILE"

echo "/spec research digest" | claude \
    --permission-mode auto \
    --print \
    2>> "$LOG_FILE" \
    | tee -a "$LOG_FILE" \
    || {
        echo "[$(date)] ERROR: Digest generation failed" >> "$LOG_FILE"
    }

echo "[$(date)] Digest completed" >> "$LOG_FILE"

# ============================================================================
# 完了
# ============================================================================
echo "[$(date)] ========================================" >> "$LOG_FILE"
echo "[$(date)] Research Cron Finished" >> "$LOG_FILE"
echo "[$(date)] ========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
