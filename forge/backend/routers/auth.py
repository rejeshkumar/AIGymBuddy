from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr
from datetime import datetime
from core.database import get_db
from core.security import hash_password, verify_password, create_token
from models.user import User

router = APIRouter()

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class AuthResponse(BaseModel):
    token: str
    user: dict

@router.post("/register", response_model=AuthResponse)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        email=req.email,
        name=req.name,
        password_hash=hash_password(req.password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {
        "token": create_token(user.id),
        "user": _user_dict(user)
    }

@router.post("/login", response_model=AuthResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user.last_login = datetime.utcnow()
    await db.commit()

    return {
        "token": create_token(user.id),
        "user": _user_dict(user)
    }

def _user_dict(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "goal": user.goal,
        "level": user.level,
        "streak": user.streak,
        "xp": user.xp,
        "total_workouts": user.total_workouts,
    }
