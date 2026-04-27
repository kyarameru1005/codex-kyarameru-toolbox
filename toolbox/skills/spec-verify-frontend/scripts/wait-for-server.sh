#!/bin/bash
# Wait for server to be ready
set -euo pipefail

URL="${1:-http://localhost:3000}"
TIMEOUT="${2:-30}"
INTERVAL=2
ELAPSED=0

echo "[INFO] Waiting for server at $URL (timeout: ${TIMEOUT}s)..."

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    if curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null | grep -qE "^[23]"; then
        echo "[INFO] Server is ready! (${ELAPSED}s)"
        exit 0
    fi
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[ERROR] Server not ready after ${TIMEOUT}s"
echo "[INFO] Last log lines:"
tail -20 .spec-dev-server.log 2>/dev/null || echo "(no log file)"
exit 1
