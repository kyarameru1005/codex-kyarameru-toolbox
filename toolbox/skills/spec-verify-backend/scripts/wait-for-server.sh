#!/bin/bash
# Wait for backend server to be ready
set -euo pipefail

URL="${1:-http://localhost:8080/health}"
TIMEOUT="${2:-30}"
INTERVAL=2
ELAPSED=0

echo "[INFO] Waiting for server at $URL (timeout: ${TIMEOUT}s)..."

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" =~ ^[23] ]]; then
        echo "[INFO] Server is ready! (${ELAPSED}s, HTTP $HTTP_CODE)"
        exit 0
    fi
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "[ERROR] Server not ready after ${TIMEOUT}s"
# Try fallback: just check if port is open
PORT=$(echo "$URL" | grep -oP ':\K[0-9]+')
if [[ -n "$PORT" ]] && ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "[WARN] Port $PORT is open but health endpoint not responding"
    echo "[INFO] Proceeding with caution..."
    exit 0
fi

echo "[INFO] Last log lines:"
tail -20 .spec-backend-server.log 2>/dev/null || echo "(no log file)"
exit 1
