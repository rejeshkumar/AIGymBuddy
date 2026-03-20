# AI GYM Buddy

Cross-platform fitness app (Web PWA + Android + iOS) with workout generation, tracking, body scan, and health insights.

## Tech Stack

- **Frontend:** Flutter (mobile + web PWA)
- **Backend:** Python FastAPI
- **Database:** PostgreSQL
- **AI:** MediaPipe (pose), Tesseract OCR

## Project Structure

```
AIGymBuddy/
├── frontend/     # Flutter app
├── backend/      # FastAPI
└── infra/        # Docker + scripts
```

> **📘 For a detailed, non-technical deployment guide**, see **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** — step-by-step instructions for local setup, Docker, and cloud deployment.

## Quick Local Setup (One Command)

```bash
cd AIGymBuddy
bash run-local.sh
```

Then run the backend and frontend in two terminals (see output of the script).

## Quick Start

### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```
API docs: http://127.0.0.1:8000/docs

### Database (Docker)
```bash
docker run --name gym-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## Features (MVP)

- [ ] Auth + Profile
- [ ] Daily Workout Generation (rule-based)
- [ ] Workout Tracking
- [ ] Body Scan (on-device, no storage)
- [ ] Health Report OCR + Insights
- [ ] Progress + Streaks
- [ ] Groups + Leaderboard
# AIGymBuddy
# AIGymBuddy
