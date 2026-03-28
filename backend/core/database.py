import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text, inspect

DATABASE_URL = os.getenv("DATABASE_URL", "")
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
elif DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)
if not DATABASE_URL:
    DATABASE_URL = "postgresql+asyncpg://forge:forge123@localhost:5432/forgedb"

engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

async def create_tables():
    # Import all models first so Base knows about them
    from models.user import User
    from models.workout import Workout
    from models.health_record import HealthRecord, WeightLog

    async with engine.begin() as conn:
        # Check if users table has wrong type and drop if needed
        try:
            result = await conn.execute(text("""
                SELECT data_type FROM information_schema.columns
                WHERE table_name='users' AND column_name='id'
            """))
            row = result.fetchone()
            if row and row[0] != 'character varying':
                # Old integer-based table exists - drop everything
                await conn.execute(text("DROP TABLE IF EXISTS health_records CASCADE"))
                await conn.execute(text("DROP TABLE IF EXISTS weight_logs CASCADE"))
                await conn.execute(text("DROP TABLE IF EXISTS workouts CASCADE"))
                await conn.execute(text("DROP TABLE IF EXISTS users CASCADE"))
        except Exception:
            # Tables don't exist yet, that's fine
            pass

        # Create all tables fresh
        await conn.run_sync(Base.metadata.create_all)
