"""Production config - load from environment."""
import os

SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

# CORS: comma-separated origins. Add your frontend URL, e.g. https://aigymbuddy.vercel.app
# Note: "*" does not work with credentials - use the exact URL
CORS_ORIGINS_STR = os.getenv("CORS_ORIGINS", "")
CORS_ORIGINS = [o.strip() for o in CORS_ORIGINS_STR.split(",") if o.strip()]

# Debug mode: enable debug endpoints (never use in production)
DEBUG = os.getenv("DEBUG", "false").lower() in ("1", "true", "yes")
