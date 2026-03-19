# AI Gym Buddy — QA Report

**Date:** March 2026

---

## Bugs Fixed

### 1. **passlib/bcrypt compatibility (CRITICAL)**
- **Issue:** Signup/Login failed with `AttributeError: module 'bcrypt' has no attribute '__about__'` and `ValueError: password cannot be longer than 72 bytes`
- **Cause:** passlib 1.7.4 incompatible with bcrypt 4.1+
- **Fix:** Replaced passlib with direct bcrypt usage in `auth.py`

### 2. **Database migration for completed_sets**
- **Issue:** Existing `workout_exercises` table missing `completed_sets` column
- **Fix:** Added PostgreSQL migration in `init_db.py` to add column if not exists

---

## QA Checklist

| Feature | Test | Status |
|---------|------|--------|
| **Auth** | Signup, Login, Logout | ✅ |
| **Daily Workout** | Load today's workout, track sets, complete | ✅ |
| **Progress** | View stats, streak, history | ✅ |
| **Body Scan** | Capture/gallery, display locally | ✅ |
| **Health OCR** | Pick image, upload, view extracted values | ✅ |
| **Groups** | Create group, join by ID | ✅ |
| **Leaderboard** | View all, filter by group | ✅ |

---

## How to Run QA

### Backend
```bash
cd AIGymBuddy/backend
source venv/bin/activate
python init_db.py
uvicorn main:app --reload --port 8000
```

### Frontend
```bash
cd AIGymBuddy/frontend
flutter pub get
flutter run -d chrome
```

### Test Flow
1. Sign up with new email
2. Go to Workout tab → complete a workout
3. Go to Progress tab → verify stats
4. Body Scan → take/select photo
5. Health OCR → select image, upload
6. Leaderboard → create group, join, view

---

## Known Limitations

- **Health OCR:** Requires pytesseract + Tesseract installed on server
- **Body Scan:** Camera may need permission on mobile
- **Leaderboard:** Shows all users when no group filter
