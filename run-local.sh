#!/bin/bash
# AI Gym Buddy - Local development startup script
# Run this from the AIGymBuddy folder

set -e
cd "$(dirname "$0")"

echo "=== AI Gym Buddy - Local Setup ==="
echo ""

# Check Docker for PostgreSQL
if command -v docker &>/dev/null; then
  if docker info &>/dev/null; then
    if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q 'gym-postgres'; then
      echo "[1/4] Starting PostgreSQL (Docker)..."
      docker run --name gym-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres
      sleep 3
    else
      echo "[1/4] Starting existing PostgreSQL container..."
      docker start gym-postgres 2>/dev/null || true
    fi
  else
    echo "[1/4] Docker is not running."
    echo "      → Start Docker Desktop, then run this script again, OR"
    echo "      → Install PostgreSQL via Homebrew: brew install postgresql@16 && brew services start postgresql@16"
    echo ""
  fi
else
  echo "[1/4] Docker not found. Install Docker Desktop or PostgreSQL (brew install postgresql@16)"
fi

# Backend setup
echo "[2/4] Setting up backend..."
cd backend
if [ ! -d "venv" ]; then
  python3 -m venv venv
  ./venv/bin/pip install -r requirements.txt
fi
./venv/bin/python init_db.py 2>/dev/null || true
cd ..

# Frontend setup
echo "[3/4] Setting up frontend..."
cd frontend
flutter pub get
cd ..

echo "[4/4] Ready!"
echo ""
echo "Run in TWO separate terminals:"
echo ""
echo "  Terminal 1 (Backend):"
echo "    cd $(pwd)/backend && source venv/bin/activate && uvicorn main:app --reload --port 8000"
echo ""
echo "  Terminal 2 (Frontend):"
echo "    cd $(pwd)/frontend && flutter run"
echo ""
echo "Then open the app - it will show backend connection status."
