# AI Gym Buddy – Deploy to Git & Railway

Quick steps to push to GitHub and deploy to Railway.

---

## 1. Push to GitHub

```bash
cd /Users/rejesh.kumar/Desktop/Project-\ AI/AIGymBuddy

# Stage and commit
git add .
git commit -m "Initial commit - production ready"

# Create repo on GitHub: https://github.com/new (name: aigymbuddy)

# Add remote and push
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/aigymbuddy.git
git push -u origin main
```

---

## 2. Deploy Backend to Railway

1. Go to [railway.app](https://railway.app) → Sign in with GitHub.
2. **New Project** → **Deploy from GitHub repo** → select `aigymbuddy`.
3. **Settings** → **Root Directory** = `backend`.
4. **Add PostgreSQL**: **+ New** → **Database** → **PostgreSQL**.
5. **Variables** (Settings → Variables):
   - `SECRET_KEY` = `openssl rand -hex 32` output
   - `CORS_ORIGINS` = `https://your-frontend-url.vercel.app` (set after step 3)
6. **Networking** → **Generate Domain** → copy URL (e.g. `https://aigymbuddy-production.up.railway.app`).

---

## 3. Deploy Flutter Web (Vercel)

```bash
cd frontend
flutter build web --dart-define=API_BASE_URL=https://YOUR-RAILWAY-URL.up.railway.app
```

1. Go to [vercel.com](https://vercel.com) → Import project from GitHub.
2. **Root Directory** = `frontend`.
3. **Build Command** = `flutter build web --dart-define=API_BASE_URL=https://YOUR-RAILWAY-URL.up.railway.app`
4. **Output Directory** = `build/web`.
5. Deploy → copy frontend URL (e.g. `https://aigymbuddy.vercel.app`).

---

## 4. Update CORS

In Railway backend **Variables**, set:
```
CORS_ORIGINS=https://your-frontend-url.vercel.app
```

---

## 5. Create Admin User

After first deploy, in Railway **Connect** → shell:

```bash
cd backend
python create_admin.py admin@example.com YourSecurePassword
```

---

## Environment Summary

| Variable      | Where   | Value                                      |
|---------------|---------|--------------------------------------------|
| `SECRET_KEY`  | Railway | `openssl rand -hex 32`                      |
| `DATABASE_URL`| Railway | Auto from PostgreSQL add-on                |
| `CORS_ORIGINS`| Railway | Your Vercel frontend URL                   |
| `API_BASE_URL`| Vercel  | Your Railway backend URL (dart-define)     |
