import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text

DATABASE_URL = os.getenv("DATABASE_URL", "")

if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
elif DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)

if not DATABASE_URL:
    DATABASE_URL = "postgresql+asyncpg://forge:forge123@localhost:5432/forgedb"

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

async def create_tables():
    async with engine.begin() as conn:
        # Nuclear option: drop everything and start fresh
        await conn.execute(text("DROP TABLE IF EXISTS health_records CASCADE"))
        await conn.execute(text("DROP TABLE IF EXISTS weight_logs CASCADE"))
        await conn.execute(text("DROP TABLE IF EXISTS workouts CASCADE"))
        await conn.execute(text("DROP TABLE IF EXISTS users CASCADE"))
        
        from models import user, workout, health_record, weight_log
        await conn.run_sync(Base.metadata.create_all)
