import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from core.database import create_tables
from routers import auth, users, workouts, health, coach

@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield

app = FastAPI(
    title="FORGE API",
    description="AI-powered fitness OS",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,     prefix="/api/auth",     tags=["auth"])
app.include_router(users.router,    prefix="/api/users",    tags=["users"])
app.include_router(workouts.router, prefix="/api/workouts", tags=["workouts"])
app.include_router(health.router,   prefix="/api/health",   tags=["health"])
app.include_router(coach.router,    prefix="/api/coach",    tags=["coach"])

@app.get("/")
async def root():
    return {"status": "FORGE API running", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}
