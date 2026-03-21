# Deploy AI Gym Buddy to Render – Step-by-Step Guide

This guide walks you through deploying your app on Render. No technical experience needed.

---

## Before You Start

- Your code should be on **GitHub** (you pushed it earlier).
- You need a **Render account** – sign up free at [render.com](https://render.com).

---

# Part 1: Create the Database

## Step 1: Sign in to Render

1. Go to [render.com](https://render.com).
2. Click **"Get Started for Free"** or **"Sign In"**.
3. Sign in with **GitHub** (recommended).

---

## Step 2: Create a New PostgreSQL Database

1. On the Render dashboard, click **"+ New"** (top right).
2. Click **"PostgreSQL"**.
3. Fill in:
   - **Name:** `aigymbuddy-db` (or any name you like)
   - **Database:** `aigymbuddy`
   - **User:** `aigymbuddy`
   - **Region:** Choose one close to you (e.g. Oregon)
   - **Plan:** Select **"Free"**
4. Click **"Create Database"**.
5. Wait 1–2 minutes until the status shows **"Available"**.

---

## Step 3: Copy the Database URL

1. Click on your new database (`aigymbuddy-db`).
2. In the **"Connections"** section, find **"Internal Database URL"**.
3. Click the **copy icon** next to it.
4. Save it somewhere safe (e.g. Notepad) – you’ll need it soon.

The URL looks like:  
`postgresql://aigymbuddy:xxxxx@dpg-xxxxx-a.oregon-postgres.render.com/aigymbuddy`

---

# Part 2: Deploy the Backend (API)

## Step 4: Create a New Web Service

1. On the Render dashboard, click **"+ New"** again.
2. Click **"Web Service"**.
3. Connect GitHub if asked:
   - Click **"Connect account"** or **"Configure account"**.
   - Choose your GitHub account and authorize Render.
4. Select your **AIGymBuddy** repository.
5. Click **"Connect"**.

---

## Step 5: Configure the Web Service

Use these settings exactly:

| Setting | Value |
|---------|-------|
| **Name** | `aigymbuddy-api` |
| **Region** | Same as your database (e.g. Oregon) |
| **Branch** | `main` |
| **Root Directory** | `backend` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `python init_db.py 2>/dev/null || true && uvicorn main:app --host 0.0.0.0 --port $PORT` |

---

## Step 6: Add Environment Variables

1. Scroll down to **"Environment Variables"**.
2. Click **"Add Environment Variable"**.
3. Add these one by one:

| Key | Value |
|-----|-------|
| `DATABASE_URL` | Paste the URL you copied in Step 3 |
| `SECRET_KEY` | A random string (e.g. run `openssl rand -hex 32` in Terminal, or use something like `my-super-secret-key-12345`) |
| `CORS_ORIGINS` | `*` (leave for now; you can add your frontend URL later) |

4. Click **"Add"** after each variable.

---

## Step 7: Create the Web Service

1. Scroll down.
2. Click **"Create Web Service"**.
3. Wait 3–5 minutes for the build and deploy to finish.

---

## Step 8: Get Your API URL

1. When the deploy finishes, you’ll see a green **"Live"** status.
2. At the top, find **"Your service is live at"** followed by a URL.
3. Copy that URL (e.g. `https://aigymbuddy-api.onrender.com`).
4. Save it – you’ll need it for the frontend.

---

# Part 3: Deploy the Frontend (Optional)

Your Flutter web app can be hosted on **Vercel** or **Netlify**. Here’s a quick outline:

1. Build the Flutter app locally:
   ```bash
   cd frontend
   flutter build web --dart-define=API_BASE_URL=https://YOUR-API-URL.onrender.com
   ```
   (Replace `YOUR-API-URL` with your actual Render URL.)

2. Deploy the `frontend/build/web` folder to Vercel or Netlify.

3. If you deploy the frontend, update `CORS_ORIGINS` in Render:
   - Go to your web service → **Environment** → Edit `CORS_ORIGINS`.
   - Set it to your frontend URL (e.g. `https://aigymbuddy.vercel.app`).

---

# Part 4: Create an Admin User

After the first successful deploy:

1. In Render, open your web service.
2. Go to **"Shell"** (in the left menu).
3. Click **"Connect"** to open a terminal.
4. Run:
   ```bash
   python create_admin.py admin@example.com YourPassword123
   ```
5. Replace `admin@example.com` and `YourPassword123` with your own email and password.

---

# Quick Checklist

- [ ] PostgreSQL database created
- [ ] Database URL copied
- [ ] Web Service created with Root Directory = `backend`
- [ ] `DATABASE_URL` added
- [ ] `SECRET_KEY` added
- [ ] `CORS_ORIGINS` added (or `*`)
- [ ] Deploy succeeded
- [ ] Admin user created (optional)

---

# Troubleshooting

**"Build failed"**  
- Check the build logs for errors.
- Ensure Root Directory is `backend`.

**"Application failed to respond"**  
- Check that `DATABASE_URL` is correct.
- Ensure the database is in "Available" status.

**Database URL format**  
- If Render gives you `postgres://`, use it as-is. The app will convert it to `postgresql://` automatically.

---

# Free Tier Notes

- Free PostgreSQL expires after 30 days. You can create a new one after that.
- Free web services sleep after 15 minutes of inactivity. The first request may take 30–60 seconds to wake up.
