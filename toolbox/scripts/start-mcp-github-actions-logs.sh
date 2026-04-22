#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  echo "[ERROR] GITHUB_PERSONAL_ACCESS_TOKEN is not set" >&2
  echo "[ERROR] export GITHUB_PERSONAL_ACCESS_TOKEN=<token> and restart Codex" >&2
  exit 1
fi

exec npx -y @modelcontextprotocol/server-github
