#!/bin/bash
# Start backend server in background with auto-detection
set -euo pipefail

PORT="${1:-8080}"
PID_FILE=".spec-backend-server.pid"

# Already running check
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[INFO] Server already running (PID: $OLD_PID)"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Docker compose detection
if [[ -f "docker-compose.yml" || -f "docker-compose.yaml" || -f "compose.yaml" ]]; then
    echo "[INFO] Docker Compose detected"
    docker compose up -d
    echo "docker-compose" > "$PID_FILE"
    echo "[INFO] Docker Compose services started"
    exit 0
fi

# Framework auto-detection
if [[ -f "Cargo.toml" ]]; then
    CMD="cargo run"
elif [[ -f "go.mod" ]]; then
    CMD="go run ."
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    if grep -q "fastapi\|uvicorn" requirements.txt pyproject.toml 2>/dev/null; then
        CMD="python -m uvicorn main:app --port $PORT"
    elif grep -q "flask" requirements.txt pyproject.toml 2>/dev/null; then
        CMD="python -m flask run --port $PORT"
    elif grep -q "django" requirements.txt pyproject.toml 2>/dev/null; then
        CMD="python manage.py runserver $PORT"
    else
        CMD="python main.py"
    fi
elif [[ -f "package.json" ]]; then
    if grep -q '"start"' package.json 2>/dev/null; then
        CMD="PORT=$PORT npm start"
    elif grep -q '"dev"' package.json 2>/dev/null; then
        CMD="PORT=$PORT npm run dev"
    else
        echo "[ERROR] No start script found in package.json"
        exit 1
    fi
else
    echo "[ERROR] No supported framework detected"
    exit 1
fi

echo "[INFO] Starting server: $CMD"
nohup bash -c "$CMD" > .spec-backend-server.log 2>&1 &
echo $! > "$PID_FILE"
echo "[INFO] Server started (PID: $(cat $PID_FILE))"
