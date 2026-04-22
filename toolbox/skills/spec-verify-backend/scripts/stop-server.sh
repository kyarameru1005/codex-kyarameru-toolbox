#!/bin/bash
# Stop backend server and cleanup
set -euo pipefail

PID_FILE=".spec-backend-server.pid"

if [[ -f "$PID_FILE" ]]; then
    PID_CONTENT=$(cat "$PID_FILE")

    # Docker Compose case
    if [[ "$PID_CONTENT" == "docker-compose" ]]; then
        echo "[INFO] Stopping Docker Compose services..."
        docker compose down
        rm -f "$PID_FILE"
        echo "[INFO] Docker Compose services stopped"
        exit 0
    fi

    # Normal process case
    PID="$PID_CONTENT"
    if kill -0 "$PID" 2>/dev/null; then
        echo "[INFO] Stopping server (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
        for i in $(seq 1 10); do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        if kill -0 "$PID" 2>/dev/null; then
            echo "[WARN] Force killing server..."
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "[INFO] Server stopped"
    else
        echo "[INFO] Server not running (stale PID file)"
    fi
    rm -f "$PID_FILE"
else
    echo "[INFO] No PID file found"
fi

rm -f .spec-backend-server.log
