#!/bin/bash
# Stop dev server and cleanup
set -euo pipefail

PID_FILE=".spec-dev-server.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "[INFO] Stopping dev server (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
        # Wait for graceful shutdown
        for i in $(seq 1 10); do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            echo "[WARN] Force killing dev server..."
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "[INFO] Dev server stopped"
    else
        echo "[INFO] Dev server not running (stale PID file)"
    fi
    rm -f "$PID_FILE"
else
    echo "[INFO] No PID file found"
fi

# Cleanup log
rm -f .spec-dev-server.log
