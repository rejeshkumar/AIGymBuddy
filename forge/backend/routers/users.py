from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import Optional
from datetime import date
from core.database import get_db
from core.security import get_current_user
from models.user import User
from models.health_record import WeightLog

router = APIRouter()

class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    level: Optional[str] = None
    gym_name: Optional[str] = None
    trainer_name: Optional[str] = None

class WeightLogRequest(BaseModel):
    weight_kg: float
    note: Optional[str] = None

@router.get("/me")
async def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "name": current_user.name,
        "age": current_user.age,
        "gender": current_user.gender,
        "height_cm": current_user.height_cm,
        "weight_kg": current_user.weight_kg,
        "goal": current_user.goal,
        "level": current_user.level,
        "gym_name": current_user.gym_name,
        "trainer_name": current_user.trainer_name,
        "streak": current_user.streak,
        "xp": current_user.xp,
        "total_workouts": current_user.total_workouts,
        "created_at": current_user.created_at.isoformat(),
    }

@router.patch("/me")
async def update_profile(
    req: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    for field, value in req.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    await db.commit()
    return {"message": "Profile updated"}

@router.post("/weight")
async def log_weight(
    req: WeightLogRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    today = date.today().isoformat()
    result = await db.execute(
        select(WeightLog)
        .where(WeightLog.user_id == current_user.id)
        .where(WeightLog.logged_date == today)
    )
    existing = result.scalar_one_or_none()
    if existing:
        existing.weight_kg = req.weight_kg
        existing.note = req.note
    else:
        log = WeightLog(
            user_id=current_user.id,
            weight_kg=req.weight_kg,
            logged_date=today,
            note=req.note
        )
        db.add(log)

    current_user.weight_kg = req.weight_kg
    await db.commit()
    return {"message": "Weight logged", "weight_kg": req.weight_kg, "date": today}

@router.get("/weight/history")
async def get_weight_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(WeightLog)
        .where(WeightLog.user_id == current_user.id)
        .order_by(desc(WeightLog.logged_date))
        .limit(30)
    )
    logs = result.scalars().all()
    return [{"date": l.logged_date, "weight_kg": l.weight_kg, "note": l.note} for l in logs]
