import os
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from routers import users, workouts, health, social, admin
from config import CORS_ORIGINS, DEBUG

app = FastAPI(title="AI GYM Buddy API", version="0.1.0")

# CORS: CORS_ORIGINS env for production; localhost allowed for dev
# When CORS_ORIGINS is "*", also allow Vercel and common hosts
_origins = list(CORS_ORIGINS) if CORS_ORIGINS else ["http://localhost", "http://127.0.0.1"]
_allow_all = "*" in [o.strip() for o in (os.getenv("CORS_ORIGINS", "") or "").split(",")]
if _allow_all:
    _origins = list(set(_origins + ["https://aigymbuddy.vercel.app"]))
    _origin_regex = r"https?://(localhost|127\.0\.0\.1)(:\d+)?$|https://[a-z0-9-]+\.vercel\.app$"
else:
    _origin_regex = r"https?://(localhost|127\.0\.0\.1)(:\d+)?$"

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_origin_regex=_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.include_router(users.router, prefix="/api", tags=["users"])
app.include_router(workouts.router, prefix="/api", tags=["workouts"])
app.include_router(health.router, prefix="/api", tags=["health"])
app.include_router(social.router, prefix="/api", tags=["social"])
app.include_router(admin.router, prefix="/api", tags=["admin"])


@app.get("/")
def root():
    return {"status": "ok", "app": "AI GYM Buddy"}


if DEBUG:
    @app.get("/api/debug/headers")
    async def debug_headers(request: Request):
        auth = request.headers.get("Authorization", "")
        x_token = request.headers.get("X-Auth-Token", "")
        token_q = request.query_params.get("token", "")
        return {
            "has_auth": bool(auth),
            "has_x_auth": bool(x_token),
            "has_token_query": bool(token_q),
            "auth_prefix": auth[:30] + "..." if len(auth) > 30 else auth,
        }
