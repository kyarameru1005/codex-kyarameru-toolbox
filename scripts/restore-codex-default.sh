#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="${ROOT_DIR}/codex-initial-state"
TARGET_DIR="${HOME}/.codex"
BACKUP_BASE_DIR="${ROOT_DIR}"
DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/restore-codex-default.sh [--source <dir>] [--target <dir>] [--backup-base-dir <dir>] [--dry-run] [--yes]

Options:
  --source <dir>  復元元ディレクトリ（既定: codex-initial-state）
  --target <dir>  復元先ディレクトリ（既定: ~/.codex）
  --backup-base-dir <dir> バックアップ保存先ディレクトリ（既定: リポジトリ直下）
  --dry-run       実際には変更せず、実行内容のみ表示
  --yes           確認プロンプトをスキップ
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --backup-base-dir)
      BACKUP_BASE_DIR="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --yes)
      ASSUME_YES=1
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

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[ERROR] source directory not found: $SOURCE_DIR"
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "[ERROR] target directory not found: $TARGET_DIR"
  exit 1
fi

if [[ ! -d "$BACKUP_BASE_DIR" ]]; then
  echo "[ERROR] backup base directory not found: $BACKUP_BASE_DIR"
  exit 1
fi

STAMP="$(date +%Y%m%d%H%M%S)"
BACKUP_DIR="${BACKUP_BASE_DIR}/codex-backup-${STAMP}"

echo "[INFO] source: $SOURCE_DIR"
echo "[INFO] target: $TARGET_DIR"
echo "[INFO] backup: $BACKUP_DIR"

if [[ $ASSUME_YES -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    echo "[ERROR] non-interactive shell requires --yes"
    exit 2
  fi

  read -r -p "[CONFIRM] restore default codex config now? [y/N]: " answer
  case "${answer,,}" in
    y|yes) ;;
    *) echo "[INFO] canceled"; exit 0 ;;
  esac
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY-RUN] cp -R \"$TARGET_DIR\" \"$BACKUP_DIR\""
  echo "[DRY-RUN] rsync -a --delete \"$SOURCE_DIR/\" \"$TARGET_DIR/\""
  exit 0
fi

cp -R "$TARGET_DIR" "$BACKUP_DIR"
rsync -a --delete "$SOURCE_DIR/" "$TARGET_DIR/"

echo "[DONE] restored: $TARGET_DIR"
echo "[DONE] backup saved: $BACKUP_DIR"
