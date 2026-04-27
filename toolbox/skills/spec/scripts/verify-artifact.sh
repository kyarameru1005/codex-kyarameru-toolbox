#!/bin/bash
# Spec Verify Artifact - 生成ファイルの品質ゲート
# Usage: verify-artifact.sh <feature_dir> <filename> [min_bytes]
#
# チェック項目:
# - ファイルが存在するか
# - サイズが min_bytes 以上か（デフォルト: 200）
# - {{PLACEHOLDER}} が残っていないか
#
# 終了コード:
#   0 - OK
#   1 - ファイルが存在しない
#   2 - サイズ不足
#   3 - プレースホルダ残存

set -euo pipefail

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[PASS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[FAIL]${NC} $1" >&2; }

# ============================================================================
# 引数チェック
# ============================================================================
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <feature_dir> <filename> [min_bytes]" >&2
    echo "  feature_dir: Feature directory (e.g., specs/features/42-user-auth)" >&2
    echo "  filename:    File to verify (e.g., design.md)" >&2
    echo "  min_bytes:   Minimum file size in bytes (default: 200)" >&2
    exit 1
fi

FEATURE_DIR="$1"
FILENAME="$2"
MIN_BYTES="${3:-200}"
FILE_PATH="${FEATURE_DIR}/${FILENAME}"

# ============================================================================
# 1. ファイル存在チェック
# ============================================================================
if [[ ! -f "$FILE_PATH" ]]; then
    error "${FILENAME}: file not found at ${FILE_PATH}"
    exit 1
fi

# ============================================================================
# 2. サイズチェック
# ============================================================================
FILE_SIZE=$(wc -c < "$FILE_PATH")
if [[ "$FILE_SIZE" -lt "$MIN_BYTES" ]]; then
    error "${FILENAME}: size ${FILE_SIZE} bytes < minimum ${MIN_BYTES} bytes"
    exit 2
fi

info "${FILENAME}: size OK (${FILE_SIZE} bytes >= ${MIN_BYTES})"

# ============================================================================
# 3. プレースホルダ残存チェック
# ============================================================================
PLACEHOLDERS=$(grep -oP '\{\{[A-Z_]+\}\}' "$FILE_PATH" 2>/dev/null || true)
if [[ -n "$PLACEHOLDERS" ]]; then
    UNIQUE_PLACEHOLDERS=$(echo "$PLACEHOLDERS" | sort -u)
    COUNT=$(echo "$UNIQUE_PLACEHOLDERS" | wc -l)
    error "${FILENAME}: ${COUNT} placeholder(s) remaining:"
    echo "$UNIQUE_PLACEHOLDERS" | sed 's/^/    /' >&2
    exit 3
fi

info "${FILENAME}: no placeholders remaining"

# ============================================================================
# 結果サマリ
# ============================================================================
echo -e "${GREEN}[OK]${NC} ${FILENAME} verified successfully (${FILE_SIZE} bytes)"
exit 0
