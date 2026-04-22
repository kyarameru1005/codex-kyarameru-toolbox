#!/bin/bash
# Start dev server in background with auto-detection
set -euo pipefail

PORT="${1:-3000}"
PID_FILE=".spec-dev-server.pid"

# Already running check
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[INFO] Dev server already running (PID: $OLD_PID)"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Framework auto-detection
if [[ -f "next.config.js" || -f "next.config.mjs" || -f "next.config.ts" ]]; then
    CMD="npx next dev -p $PORT"
elif [[ -f "vite.config.js" || -f "vite.config.ts" || -f "vite.config.mjs" ]]; then
    CMD="npx vite --port $PORT"
elif [[ -f "angular.json" ]]; then
    CMD="npx ng serve --port $PORT"
elif [[ -f "package.json" ]]; then
    # Check for dev script
    if grep -q '"dev"' package.json 2>/dev/null; then
        CMD="npm run dev -- --port $PORT 2>/dev/null || npm run dev"
    elif grep -q '"start"' package.json 2>/dev/null; then
        CMD="npm start"
    else
        echo "[ERROR] No dev or start script found in package.json"
        exit 1
    fi
else
    echo "[ERROR] No supported framework detected"
    exit 1
fi

echo "[INFO] Starting dev server: $CMD"
nohup bash -c "$CMD" > .spec-dev-server.log 2>&1 &
echo $! > "$PID_FILE"
echo "[INFO] Dev server started (PID: $(cat $PID_FILE))"
