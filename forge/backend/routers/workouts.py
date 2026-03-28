import os, json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import anthropic
from core.database import get_db
from core.security import get_current_user
from models.user import User
from models.workout import Workout

router = APIRouter()
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

class GenerateRequest(BaseModel):
    muscle_group: str = "Full Body"
    duration_min: int = 45
    equipment: str = "Full Gym"
    intensity: str = "Moderate"

class CompleteWorkoutRequest(BaseModel):
    workout_id: str
    kcal_burned: Optional[int] = None

@router.post("/generate")
async def generate_workout(
    req: GenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    prompt = f"""You are an expert personal trainer. Generate a workout plan as valid JSON only.

User profile:
- Name: {current_user.name}
- Goal: {current_user.goal or 'General Fitness'}
- Level: {current_user.level or 'Intermediate'}
- Age: {current_user.age or 'unknown'}
- Weight: {current_user.weight_kg or 'unknown'} kg

Workout request:
- Muscle group: {req.muscle_group}
- Duration: {req.duration_min} minutes
- Equipment: {req.equipment}
- Intensity: {req.intensity}

Return ONLY this JSON structure, no other text:
{{
  "title": "workout title",
  "muscle_group": "{req.muscle_group}",
  "warmup": "2-3 sentence warmup description",
  "exercises": [
    {{
      "name": "Exercise Name",
      "sets": 3,
      "reps": "12",
      "rest_seconds": 60,
      "muscle": "primary muscle",
      "tip": "form tip in one sentence"
    }}
  ],
  "cooldown": "2-3 sentence cooldown description",
  "estimated_kcal": 350,
  "coach_note": "motivational note personalized to the user"
}}

Include 5-7 exercises appropriate for the level and equipment."""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1500,
        messages=[{"role": "user", "content": prompt}]
    )

    raw = message.content[0].text.strip()
    # Strip markdown code fences if present
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    workout_data = json.loads(raw.strip())

    workout = Workout(
        user_id=current_user.id,
        title=workout_data["title"],
        muscle_group=req.muscle_group,
        duration_min=req.duration_min,
        equipment=req.equipment,
        level=current_user.level or "Intermediate",
        exercises=json.dumps(workout_data["exercises"]),
        ai_generated=True,
    )
    db.add(workout)
    await db.commit()
    await db.refresh(workout)

    return {
        "id": workout.id,
        "title": workout_data["title"],
        "muscle_group": req.muscle_group,
        "duration_min": req.duration_min,
        "warmup": workout_data.get("warmup"),
        "exercises": workout_data["exercises"],
        "cooldown": workout_data.get("cooldown"),
        "estimated_kcal": workout_data.get("estimated_kcal", 350),
        "coach_note": workout_data.get("coach_note", "Let's get it!"),
    }

@router.post("/complete")
async def complete_workout(
    req: CompleteWorkoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Workout).where(Workout.id == req.workout_id, Workout.user_id == current_user.id)
    )
    workout = result.scalar_one_or_none()
    if not workout:
        raise HTTPException(status_code=404, detail="Workout not found")

    workout.completed = True
    workout.completed_at = datetime.utcnow()
    workout.kcal_burned = req.kcal_burned

    current_user.total_workouts += 1
    current_user.streak += 1
    current_user.xp += 200
    await db.commit()

    return {
        "message": "Workout complete! Amazing work!",
        "xp_earned": 200,
        "new_streak": current_user.streak,
        "total_workouts": current_user.total_workouts
    }

@router.get("/history")
async def get_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Workout)
        .where(Workout.user_id == current_user.id)
        .order_by(desc(Workout.created_at))
        .limit(20)
    )
    workouts = result.scalars().all()
    return [
        {
            "id": w.id,
            "title": w.title,
            "muscle_group": w.muscle_group,
            "duration_min": w.duration_min,
            "kcal_burned": w.kcal_burned,
            "completed": w.completed,
            "created_at": w.created_at.isoformat(),
        }
        for w in workouts
    ]
