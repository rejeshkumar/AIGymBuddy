#!/bin/bash
# Create database tables on first run, then start the API
python3 init_db.py 2>/dev/null || python init_db.py 2>/dev/null || true
exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
