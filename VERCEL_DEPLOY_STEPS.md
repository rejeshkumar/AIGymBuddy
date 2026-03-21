# Deploy AI Gym Buddy Frontend to Vercel – Step-by-Step Guide

This guide walks you through deploying the Flutter web app to Vercel. No technical experience needed.

---

## Before You Start

- Your code is on **GitHub** (AIGymBuddy repo)
- Your **backend** is running on Render (e.g. `https://aigymbuddy.onrender.com`)
- You have a **Vercel account** – sign up free at [vercel.com](https://vercel.com)

---

# Part 1: Create a New Vercel Project

## Step 1: Go to Vercel

1. Open your browser and go to **[vercel.com](https://vercel.com)**
2. Click **"Log in"** or **"Sign Up"**
3. Sign in with **GitHub** (recommended)

---

## Step 2: Create a New Project

1. On the Vercel dashboard, click **"Add New..."** (top right)
2. Click **"Project"**
3. You will see a list of your GitHub repositories

---

## Step 3: Import Your Repository

1. Find **"AIGymBuddy"** in the list (or search for it)
2. Click **"Import"** next to AIGymBuddy
3. If you don't see it:
   - Click **"Adjust GitHub App Permissions"**
   - Make sure Vercel has access to the AIGymBuddy repository
   - Go back and try again

---

# Part 2: Configure the Project

## Step 4: Set the Root Directory

1. On the import screen, look for **"Root Directory"**
2. Click **"Edit"** next to it
3. Type: `frontend`
4. Click **"Continue"**

This tells Vercel to use only the `frontend` folder (where the Flutter app lives).

---

## Step 5: Set the Build and Output Settings

Scroll down to **"Build and Output Settings"**. You need to change these:

### Framework Preset
- Click the dropdown (it might say "Other" or "Vite")
- Select **"Other"** if available, or leave as is

### Build Command
Click **"Override"** and enter:

```
git clone https://github.com/flutter/flutter.git --depth 1 -b stable .flutter 2>/dev/null || true && .flutter/bin/flutter config --enable-web && .flutter/bin/flutter pub get && .flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://aigymbuddy.onrender.com
```

**Important:** Replace `https://aigymbuddy.onrender.com` with your actual Render backend URL if it's different.

### Output Directory
Click **"Override"** and enter:

```
build/web
```

### Install Command (optional – leave blank)
You can leave this blank; the build command handles setup.

---

## Step 6: Environment Variables (Optional)

If you need any environment variables, add them here. For AI Gym Buddy, you usually don't need any – the API URL is in the build command.

---

## Step 7: Deploy

1. Click **"Deploy"**
2. Wait **5–15 minutes** (first build is slow because it downloads Flutter)
3. When it finishes, you'll see **"Congratulations!"** with your live URL

---

# Part 3: After Deployment

## Step 8: Get Your URL

1. Your app will be at a URL like: `https://aigymbuddy-xxxxx.vercel.app`
2. You can add a custom domain later in **Settings → Domains**

---

## Step 9: Update CORS on Render

1. Go to **Render** → your AIGymBuddy backend service
2. Click **Environment**
3. Set `CORS_ORIGINS` to your Vercel URL, e.g.:
   ```
   https://aigymbuddy-xxxxx.vercel.app
   ```
4. Save and redeploy the backend

---

# Quick Reference

| Setting | Value |
|--------|-------|
| **Root Directory** | `frontend` |
| **Build Command** | `git clone https://github.com/flutter/flutter.git --depth 1 -b stable .flutter 2>/dev/null || true && .flutter/bin/flutter config --enable-web && .flutter/bin/flutter pub get && .flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://aigymbuddy.onrender.com` |
| **Output Directory** | `build/web` |

---

# Alternative: Build Locally and Deploy (Faster)

If the Vercel build is too slow or fails, you can build on your computer and deploy the built files:

## Step 1: Build on Your Mac

Open Terminal and run:

```bash
cd /Users/rejesh.kumar/Desktop/Project-\ AI/AIGymBuddy/frontend
flutter build web --dart-define=API_BASE_URL=https://aigymbuddy.onrender.com
```

## Step 2: Deploy to Vercel

1. Go to [vercel.com](https://vercel.com) → **Add New** → **Project**
2. Click **"Deploy with Vercel CLI"** or **"Import Third-Party Git Repository"**
3. Or: Install Vercel CLI (`npm i -g vercel`), then run:
   ```bash
   cd /Users/rejesh.kumar/Desktop/Project-\ AI/AIGymBuddy/frontend/build/web
   vercel --prod
   ```
4. Follow the prompts to link and deploy

---

# Troubleshooting

**Build fails with "flutter: command not found"**
- The build command installs Flutter. Make sure the full command is used.
- Try the "Build Locally" alternative above.

**Build takes too long**
- First build can take 10–15 minutes. Later builds are faster.
- Or use the local build method.

**App loads but login fails**
- Check that `API_BASE_URL` in the build command matches your Render URL.
- Check that `CORS_ORIGINS` on Render includes your Vercel URL.
