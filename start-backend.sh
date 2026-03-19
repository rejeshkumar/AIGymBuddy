#!/bin/bash
# Start AI Gym Buddy backend

cd "$(dirname "$0")/backend"

# Kill any process on port 8000
if lsof -i :8000 2>/dev/null | grep -q LISTEN; then
  echo "Killing existing process on port 8000..."
  kill $(lsof -t -i :8000) 2>/dev/null || true
  sleep 2
fi

echo "Starting backend on http://localhost:8000"
source venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000
