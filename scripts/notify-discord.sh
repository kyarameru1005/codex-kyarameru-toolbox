#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/notify-discord.sh --status <started|progress|success|failure|info> --summary <text> [options]

Options:
  --project <name>   Project name shown in message (default: current directory name)
  --branch <name>    Branch name shown in message (default: current git branch or unknown)
  --link <url>       Optional URL for details (PR, workflow run, etc.)
  --username <name>  Discord sender name (default: codex-notifier)
  --dry-run          Print payload only; do not send to Discord
  -h, --help         Show this help

Required environment variable (except --dry-run):
  DISCORD_WEBHOOK_URL
USAGE
}

status=""
summary=""
project="$(basename "$PWD")"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
link=""
username="codex-notifier"
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      status="${2:-}"
      shift 2
      ;;
    --summary)
      summary="${2:-}"
      shift 2
      ;;
    --project)
      project="${2:-}"
      shift 2
      ;;
    --branch)
      branch="${2:-}"
      shift 2
      ;;
    --link)
      link="${2:-}"
      shift 2
      ;;
    --username)
      username="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=true
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

if [[ -z "$status" ]]; then
  echo "[ERROR] --status is required"
  usage
  exit 2
fi

case "$status" in
  started|progress|success|failure|info)
    ;;
  *)
    echo "[ERROR] invalid status: $status"
    usage
    exit 2
    ;;
esac

if [[ -z "$summary" ]]; then
  echo "[ERROR] --summary is required"
  usage
  exit 2
fi

timestamp="$(date '+%Y-%m-%d %H:%M:%S %z')"
icon=":information_source:"
status_label="情報"
if [[ "$status" == "started" ]]; then
  icon=":rocket:"
  status_label="開始"
elif [[ "$status" == "progress" ]]; then
  icon=":hourglass_flowing_sand:"
  status_label="進行中"
elif [[ "$status" == "success" ]]; then
  icon=":white_check_mark:"
  status_label="完了"
elif [[ "$status" == "failure" ]]; then
  icon=":x:"
  status_label="失敗"
fi

content="${icon} [${status_label}] ${summary}
プロジェクト: ${project}
ブランチ: ${branch}
時刻: ${timestamp}"

if [[ -n "$link" ]]; then
  content="${content}
詳細: ${link}"
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ERROR] python3 is required to build JSON payload"
  exit 1
fi

payload="$(python3 -c 'import json,sys; print(json.dumps({"username": sys.argv[1], "content": sys.argv[2]}, ensure_ascii=False))' "$username" "$content")"

if [[ "$dry_run" == "true" ]]; then
  echo "[DRY-RUN] payload:"
  echo "$payload"
  exit 0
fi

if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
  echo "[ERROR] DISCORD_WEBHOOK_URL is not set"
  exit 2
fi

http_code="$(curl -sS -o /tmp/discord-notify-response.txt -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$payload" \
  "$DISCORD_WEBHOOK_URL")"

if [[ "$http_code" != "204" && "$http_code" != "200" ]]; then
  echo "[ERROR] Discord webhook request failed: HTTP ${http_code}"
  echo "[ERROR] Response:"
  cat /tmp/discord-notify-response.txt
  exit 1
fi

echo "[OK] Discord notification sent (${http_code})"
