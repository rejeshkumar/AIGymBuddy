from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:pass@localhost:5432/postgres"
)
# Railway uses postgres:// - SQLAlchemy needs postgresql://
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Fail fast on Railway if DATABASE_URL is missing (PORT is set by Railway)
if os.getenv("PORT") and ("localhost" in DATABASE_URL or "127.0.0.1" in DATABASE_URL):
    raise RuntimeError(
        "DATABASE_URL not set on Railway. Add PostgreSQL: Project → + New → Database → PostgreSQL, "
        "then link it to this service (Variables → Add Reference → DATABASE_URL from PostgreSQL)."
    )

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
