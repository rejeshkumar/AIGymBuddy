# AI Gym Buddy — Deployment Guide

**Document Version:** 1.0  
**Application:** AI Gym Buddy — Cross-platform fitness app  
**Date:** March 2026

---

## Table of Contents

1. [What This Document Covers](#1-what-this-document-covers)
2. [What You Need Before Starting](#2-what-you-need-before-starting)
3. [Path A — Run on Your Mac (Local Testing)](#3-path-a--run-on-your-mac-local-testing)
4. [Path B — Run with Docker (Easier Setup)](#4-path-b--run-with-docker-easier-setup)
5. [Path C — Local → Git → Railway (Production)](#5-path-c--local--git--railway-production)
6. [Path D — Deploy to VPS/Cloud Server](#6-path-d--deploy-to-vpscloud-server)
7. [Verifying Everything Works](#7-verifying-everything-works)
8. [Troubleshooting](#8-troubleshooting)
9. [Quick Reference — All Commands](#9-quick-reference--all-commands)

---

## 1. What This Document Covers

This guide helps you get the **AI Gym Buddy** app running. AI Gym Buddy is a fitness app with:

- **Mobile/Web app** (Flutter) — workout tracking, body scan, health insights
- **Backend API** (Python FastAPI) — handles users, workouts, data
- **Database** (PostgreSQL) — stores all user and workout data

You can run it in three ways:

| Path | Best For | Difficulty |
|------|----------|------------|
| **A — On your Mac** | Testing, demos, development | Medium |
| **B — With Docker** | Quick setup, no manual installs | Easy |
| **C — On cloud server** | Production, 24/7 access for users | Advanced |

---

## 2. What You Need Before Starting

### For Path A (Mac) and Path B (Docker)

| Item | Requirement |
|------|-------------|
| Mac computer | macOS 10.15 or later |
| Internet connection | For downloading tools |
| Terminal app | Built into Mac (press `Cmd + Space`, type "Terminal", press Enter) |
| 30–60 minutes | For first-time setup |

### Software to Install (Path A only)

| Software | Version | Where to Download |
|----------|---------|-------------------|
| **Python** | 3.11 or 3.12 | [python.org/downloads](https://www.python.org/downloads/) — choose "macOS 64-bit installer" |
| **PostgreSQL** or **Docker** | Latest | See options below |
| **Flutter** | 3.2+ | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |

### For Path B (Docker) — Simpler

| Software | Where to Download |
|----------|-------------------|
| **Docker Desktop** | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) — download for Mac |

If you use Docker, you **do not** need to install Python or PostgreSQL separately — Docker runs them in containers.

---

## 3. Path A — Run on Your Mac (Local Testing)

This path runs the database, backend, and frontend directly on your Mac. Good for testing and development.

---

### Step 1 — Install Python (if not already installed)

1. Go to [python.org/downloads](https://www.python.org/downloads/)
2. Download **Python 3.11** or **3.12** for macOS
3. Run the installer — **check the box** "Add Python to PATH" if shown
4. Open **Terminal** and type:
   ```bash
   python3 --version
   ```
   You should see something like `Python 3.11.6`. If you see "command not found", Python is not installed correctly.

---

### Step 2 — Start the Database (PostgreSQL)

**Option 2a — Using Docker (recommended if you have Docker)**

```bash
docker run --name gym-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres
```

This starts PostgreSQL in the background. You only need to run this once.

**Option 2b — Using Homebrew (if you prefer native install)**

1. Install Homebrew (if you don't have it):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Install PostgreSQL:
   ```bash
   brew install postgresql@16
   brew services start postgresql@16
   ```

---

### Step 3 — Set Up the Backend

1. Open **Terminal**
2. Go to the project folder:
   ```bash
   cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/backend"
   ```
   *(Replace the path if your project is in a different location.)*

3. Create a virtual environment (a separate Python environment for this project):
   ```bash
   python3 -m venv venv
   ```

4. Activate the virtual environment:
   ```bash
   source venv/bin/activate
   ```
   You should see `(venv)` appear at the start of your terminal line.

5. Install the required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

6. Create the database tables:
   ```bash
   python init_db.py
   ```
   You should see: `Tables created successfully.`

7. (Optional) Create the first admin user:
   ```bash
   python create_admin.py admin@example.com yourpassword
   ```
   This creates an admin account or promotes an existing user to admin. Admins can manage users from the app.

8. Start the backend server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
   Leave this terminal window open. The backend is now running.

9. **Verify:** Open a browser and go to [http://localhost:8000](http://localhost:8000). You should see:
   ```json
   {"status":"ok","app":"AI GYM Buddy"}
   ```
   API documentation: [http://localhost:8000/docs](http://localhost:8000/docs)

---

### Step 4 — Set Up the Frontend (Flutter)

1. Install Flutter (if not already installed):
   - Go to [docs.flutter.dev/get-started/install/macos](https://docs.flutter.dev/get-started/install/macos)
   - Follow the official Flutter installation guide for macOS

2. Open a **new** Terminal window (keep the backend running in the first one).

3. Go to the frontend folder:
   ```bash
   cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/frontend"
   ```

4. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

5. Run the app:
   ```bash
   flutter run
   ```
   Choose your target (Chrome for web, or a connected device/emulator for mobile).

---

### Step 5 — Configure API URL (if needed)

The Flutter app connects to the backend at `http://localhost:8000` by default. If you run the app on an **Android emulator**, change the API URL to `http://10.0.2.2:8000` in the frontend code (check `lib/` for API base URL configuration).

---

## 4. Path B — Run with Docker (Easier Setup)

Docker runs the database and backend in containers. You only need to install **Docker Desktop** and **Flutter**.

---

### Step 1 — Install Docker Desktop

1. Go to [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Download **Docker Desktop for Mac**
3. Install and open Docker Desktop
4. Wait until Docker is running (whale icon in the menu bar)

---

### Step 2 — Start Database and Backend with Docker

1. Open **Terminal**
2. Go to the infra folder:
   ```bash
   cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/infra"
   ```

3. Start the services:
   ```bash
   docker compose up -d
   ```
   This starts:
   - **PostgreSQL** on port 5432
   - **Backend API** on port 8000

4. Create the database tables (run once):
   ```bash
   cd ../backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python init_db.py
   ```

5. **Verify:** Open [http://localhost:8000](http://localhost:8000) — you should see the API response.

---

### Step 3 — Run the Flutter Frontend

Same as Path A, Step 4:

```bash
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/frontend"
flutter pub get
flutter run
```

---

## 5. Path C — Local → Git → Railway (Production)

This is the recommended workflow: **develop locally** → **push to GitHub** → **deploy to Railway**. Railway auto-deploys whenever you push to GitHub.

---

### Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. LOCAL       │     │  2. GIT          │     │  3. RAILWAY     │
│  Develop & test │ ──► │  git push        │ ──► │  Auto-deploy    │
│  on your Mac    │     │  to GitHub      │     │  from GitHub    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

### Phase 1 — Develop Locally

Follow **Path A** or **Path B** above to get the app running on your Mac. Make sure:

- Backend runs at http://localhost:8000
- Database tables are created (`python init_db.py`)
- Flutter app connects to the backend

---

### Phase 2 — Push to GitHub

#### Step 1 — Create a GitHub Account (if you don't have one)

1. Go to [github.com](https://github.com)
2. Sign up for a free account

#### Step 2 — Install Git (if not already installed)

On Mac, Git usually comes with Xcode. Check by opening Terminal and typing:

```bash
git --version
```

If not installed, run: `xcode-select --install`

#### Step 3 — Create a New Repository on GitHub

1. Log in to GitHub
2. Click the **+** icon (top right) → **New repository**
3. Name it: `ai-gym-buddy` (or any name you prefer)
4. Choose **Public**
5. **Do not** check "Add a README" (you already have code)
6. Click **Create repository**

#### Step 4 — Push Your Code from Your Mac

Open Terminal and run (replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub username and repo name):

```bash
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy"

# Initialize Git (if not already done)
git init

# Add a .gitignore to exclude venv, build files, etc.
# (Create .gitignore if it doesn't exist — see below)

git add .
git commit -m "Initial commit: AI Gym Buddy"

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

**Create a `.gitignore` file** in the AIGymBuddy folder if you don't have one. It should contain:

```
# Python
venv/
__pycache__/
*.pyc
.env

# Flutter
.dart_tool/
build/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.iml
```

---

### Phase 3 — Deploy to Railway

#### Step 1 — Create a Railway Account

1. Go to [railway.app](https://railway.app)
2. Click **Login** → **Login with GitHub**
3. Authorize Railway to access your GitHub account

#### Step 2 — Create a New Project

1. Click **New Project**
2. Select **Deploy from GitHub repo**
3. Choose your **ai-gym-buddy** repository
4. Railway will detect the project

#### Step 3 — Add PostgreSQL

1. In your Railway project, click **+ New**
2. Select **Database** → **PostgreSQL**
3. Railway will create a PostgreSQL service and provide a `DATABASE_URL`

#### Step 4 — Configure the Backend Service

1. Railway may auto-detect the backend. If not, click **+ New** → **GitHub Repo** → select your repo
2. Set the **Root Directory** to `backend` (so Railway builds from the backend folder)
3. Click on the backend service → **Variables** tab
4. Add variable: `DATABASE_URL` = (copy from the PostgreSQL service — click **Connect** → **Postgres URL**)
5. Railway will auto-redeploy
6. **Database tables** are created automatically on each deploy (the backend runs `init_db.py` before starting — safe to run every time)

#### Step 5 — Get Your API URL

1. Click on the backend service
2. Go to **Settings** → **Networking** → **Generate Domain**
3. Copy the URL (e.g., `https://ai-gym-buddy-api-production.up.railway.app`)

#### Step 6 — Deploy Flutter Web (Optional)

To make the Flutter app available on the web:

1. On your Mac, build the web app:
   ```bash
   cd AIGymBuddy/frontend
   flutter build web
   ```
2. The output is in `frontend/build/web/`
3. Deploy this folder to **Vercel** or **Netlify** (drag-and-drop the `build/web` folder), **or** add a static site service in Railway
4. Update the API URL in your Flutter app to point to your Railway backend URL (e.g., `https://your-api.up.railway.app`)

---

### Ongoing Workflow

After the initial setup, your workflow is:

| Step | What to Do |
|------|------------|
| **Develop** | Make changes locally, test with backend + frontend running |
| **Commit** | `git add .` → `git commit -m "Describe your change"` |
| **Push** | `git push origin main` |
| **Deploy** | Railway automatically deploys within 1–2 minutes |

---

## 6. Path D — Deploy to VPS/Cloud Server

For full control or if you prefer a traditional server (Hetzner, DigitalOcean, etc.) instead of Railway.

---

### What You Need

| Item | Details |
|------|---------|
| Cloud server | Hetzner, DigitalOcean, or similar (~$5–10/month) |
| Domain name | Optional (~$10/year) |
| SSH access | To connect to the server from your Mac |

---

### High-Level Steps

1. **Rent a server** (e.g., Hetzner CX22 — ~₹400/month)
2. **Install** on the server: Ubuntu 22.04, Python, PostgreSQL, Nginx, Flutter (for web build)
3. **Upload** your AIGymBuddy code to the server
4. **Build** the Flutter web app and serve it via Nginx
5. **Run** the backend with systemd or PM2
6. **Configure** Nginx as a reverse proxy
7. **Enable HTTPS** with Let's Encrypt (free)

*For detailed VPS deployment steps, refer to the MediSyn DEPLOYMENT_GUIDE or expand this section as needed.*

---

## 7. Verifying Everything Works

### Backend (API)

| Check | How to Verify |
|-------|----------------|
| API is running | Open [http://localhost:8000](http://localhost:8000) — see `{"status":"ok","app":"AI GYM Buddy"}` |
| API docs | Open [http://localhost:8000/docs](http://localhost:8000/docs) — see interactive API documentation |

### Database

| Check | How to Verify |
|-------|----------------|
| PostgreSQL running | If using Docker: `docker ps` — see `gym-postgres` container |
| Tables created | Backend starts without errors; `init_db.py` printed "Tables created successfully" |

### Frontend

| Check | How to Verify |
|-------|----------------|
| App loads | Flutter app opens in browser or on device |
| Connects to API | Login or any API call works (check Network tab in browser DevTools) |

---

## 8. Troubleshooting

### "command not found: python" or "command not found: python3"

- **Cause:** Python is not installed or not in your PATH.
- **Fix:** Install Python from [python.org](https://www.python.org/downloads/) and use `python3` instead of `python` in all commands.

---

### "ModuleNotFoundError: No module named 'sqlalchemy'"

- **Cause:** You ran `uvicorn` without activating the virtual environment, so it used system Python instead of the venv.
- **Fix:**
  ```bash
  cd AIGymBuddy/backend
  source venv/bin/activate
  uvicorn main:app --reload
  ```
  Or run directly: `./venv/bin/uvicorn main:app --reload`

---

### "connection refused" or "could not connect to server"

- **Cause:** PostgreSQL is not running.
- **Fix (Docker):**
  ```bash
  docker start gym-postgres
  ```
  Or run: `docker run --name gym-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres`

---

### "Tables created successfully" but backend still fails

- **Cause:** Database URL might be wrong (e.g., different host/port).
- **Fix:** The default is `postgresql://postgres:pass@localhost:5432/postgres`. If your PostgreSQL uses different credentials, set:
  ```bash
  export DATABASE_URL="postgresql://USER:PASSWORD@HOST:5432/DATABASE"
  ```
  before running the backend.

---

### Flutter: "flutter: command not found"

- **Cause:** Flutter is not installed or not in PATH.
- **Fix:** Follow [Flutter install guide for macOS](https://docs.flutter.dev/get-started/install/macos) and add Flutter to your PATH.

---

### Docker: "Cannot connect to the Docker daemon"

- **Cause:** Docker Desktop is not running.
- **Fix:** Open Docker Desktop and wait until it is fully started.

---

## 9. Quick Reference — All Commands

### One-Time Setup (Path A)

```bash
# 1. Start database (Docker)
docker run --name gym-postgres -e POSTGRES_PASSWORD=pass -p 5432:5432 -d postgres

# 2. Backend setup
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/backend"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python init_db.py

# 3. Frontend setup
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/frontend"
flutter pub get
```

### Every Time You Want to Run (Path A)

```bash
# Terminal 1 — Backend
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/backend"
source venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 — Frontend
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/frontend"
flutter run
```

### Docker (Path B)

```bash
# Start everything
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy/infra"
docker compose up -d

# Stop everything
docker compose down
```

### Git → Railway (Path C)

```bash
# After making changes locally
cd "/Users/rejesh.kumar/Desktop/Project- AI/AIGymBuddy"
git add .
git commit -m "Describe your change"
git push origin main
# Railway auto-deploys in 1–2 minutes
```

---

## Summary

| Component | Default URL/Port |
|-----------|------------------|
| Backend API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Flutter app | Runs in browser or on device |

---

*For questions or issues, refer to the Troubleshooting section or check the project README.*
