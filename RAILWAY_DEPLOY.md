# Deploy AI Gym Buddy to Railway

## 1. Push to Git

```bash
cd /Users/rejesh.kumar/Desktop/Project-\ AI/AIGymBuddy
git init
git add .
git commit -m "Initial commit - production ready"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/aigymbuddy.git
git push -u origin main
```

## 2. Deploy Backend to Railway

1. Go to [railway.app](https://railway.app) and sign in with GitHub.
2. **New Project** → **Deploy from GitHub repo** → select your repo.
3. **Settings** → set **Root Directory** to `backend`.
4. **Add PostgreSQL**: Click **+ New** → **Database** → **PostgreSQL**. Railway will inject `DATABASE_URL`.
5. **Variables** (Settings → Variables):
   - `SECRET_KEY` = run `openssl rand -hex 32` and paste the output
   - `CORS_ORIGINS` = your frontend URL (see step 3)
6. **Deploy**: Railway will auto-detect Python and deploy. If using Dockerfile, it will use that.
7. **Generate Domain**: Settings → Networking → Generate Domain. Copy the URL (e.g. `https://aigymbuddy-production.up.railway.app`).

## 3. Deploy Flutter Web (Frontend)

**Option A: Vercel / Netlify (recommended)**

1. Build Flutter with your API URL:
   ```bash
   cd frontend
   flutter build web --dart-define=API_BASE_URL=https://YOUR-RAILWAY-URL.up.railway.app
   ```
2. Deploy `frontend/build/web` to Vercel or Netlify.
3. Copy your frontend URL (e.g. `https://aigymbuddy.vercel.app`).

**Option B: Railway Static**

1. Create a second Railway service for static hosting.
2. Build: `flutter build web --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL`
3. Use a static site config or serve `build/web`.

## 4. Update CORS

In Railway backend **Variables**, set:
```
CORS_ORIGINS=https://your-frontend-url.vercel.app
```
(Use your actual frontend URL from step 3.)

## 5. Create Admin User

After first deploy, run locally (with DATABASE_URL pointing to Railway DB) or use Railway's shell:

```bash
# Set DATABASE_URL to your Railway PostgreSQL connection string, then:
cd backend
python create_admin.py admin@example.com yourpassword
```

Or use Railway's **Connect** to open a shell and run the command.

## Environment Variables Summary

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY` | Yes | JWT secret - `openssl rand -hex 32` |
| `DATABASE_URL` | Auto | Injected by Railway when you add PostgreSQL |
| `CORS_ORIGINS` | Yes | Your frontend URL (comma-separated if multiple) |
| `DEBUG` | No | Set to `true` only for local dev |
