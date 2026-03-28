import os, json
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import List, Optional
import anthropic
from core.database import get_db
from core.security import get_current_user
from models.user import User
from models.workout import Workout
from models.health_record import HealthRecord, WeightLog

router = APIRouter()
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

class Message(BaseModel):
    role: str   # "user" or "assistant"
    content: str

class ChatRequest(BaseModel):
    message: str
    history: Optional[List[Message]] = []

class PostureRequest(BaseModel):
    exercise: str
    joint_data: Optional[dict] = None
    rep_count: int = 0

@router.post("/chat")
async def chat_with_coach(
    req: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Gather user context
    health_result = await db.execute(
        select(HealthRecord)
        .where(HealthRecord.user_id == current_user.id)
        .order_by(desc(HealthRecord.recorded_at)).limit(1)
    )
    health = health_result.scalar_one_or_none()

    weight_result = await db.execute(
        select(WeightLog)
        .where(WeightLog.user_id == current_user.id)
        .order_by(desc(WeightLog.logged_date)).limit(5)
    )
    weights = weight_result.scalars().all()

    workout_result = await db.execute(
        select(Workout)
        .where(Workout.user_id == current_user.id)
        .order_by(desc(Workout.created_at)).limit(3)
    )
    recent_workouts = workout_result.scalars().all()

    weight_trend = ""
    if len(weights) >= 2:
        diff = weights[0].weight_kg - weights[-1].weight_kg
        weight_trend = f"Weight trend: {'+' if diff > 0 else ''}{diff:.1f} kg over last {len(weights)} logs"

    system_prompt = f"""You are FORGE AI Coach — a world-class personal trainer and health coach built into the FORGE fitness app.
You are motivational, precise, science-backed and direct. Never vague. Always actionable.

USER PROFILE:
- Name: {current_user.name}
- Goal: {current_user.goal or 'General Fitness'}
- Level: {current_user.level or 'Intermediate'}
- Age: {current_user.age or 'unknown'}, Gender: {current_user.gender or 'unknown'}
- Current weight: {current_user.weight_kg or 'unknown'} kg, Height: {current_user.height_cm or 'unknown'} cm
- Streak: {current_user.streak} days, Total workouts: {current_user.total_workouts}
- {weight_trend}

HEALTH DATA:
{f"Blood pressure: {health.blood_pressure}" if health and health.blood_pressure else "No blood pressure data"}
{f"Resting HR: {health.resting_hr} bpm" if health and health.resting_hr else ""}
{f"Vitamin D: {health.vitamin_d} ng/mL" if health and health.vitamin_d else ""}
{f"VO2 Max: {health.vo2_max}" if health and health.vo2_max else ""}

RECENT WORKOUTS: {', '.join([w.title for w in recent_workouts]) if recent_workouts else 'None yet'}

Be the coach that changes their life. Keep responses under 150 words unless asked for detail.
Use their name occasionally. Be direct like a world-class trainer would be."""

    messages = []
    for m in (req.history or [])[-10:]:  # last 10 messages for context
        messages.append({"role": m.role, "content": m.content})
    messages.append({"role": "user", "content": req.message})

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=400,
        system=system_prompt,
        messages=messages
    )

    return {
        "message": response.content[0].text,
        "role": "assistant"
    }

@router.post("/form-feedback")
async def get_form_feedback(
    req: PostureRequest,
    current_user: User = Depends(get_current_user),
):
    prompt = f"""You are a biomechanics expert. Give instant form feedback for {req.exercise}.
Rep count: {req.rep_count}
{f"Joint data: {json.dumps(req.joint_data)}" if req.joint_data else ""}

Return ONLY JSON:
{{
  "score": 85,
  "feedback": "One specific correction in under 10 words",
  "tip": "One positive reinforcement in under 10 words",
  "safe_to_continue": true
}}"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=200,
        messages=[{"role": "user", "content": prompt}]
    )
    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    return json.loads(raw.strip())

@router.get("/daily-insight")
async def get_daily_insight(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    health_result = await db.execute(
        select(HealthRecord)
        .where(HealthRecord.user_id == current_user.id)
        .order_by(desc(HealthRecord.recorded_at)).limit(1)
    )
    health = health_result.scalar_one_or_none()

    prompt = f"""Generate a personalized daily coaching insight for {current_user.name}.
Goal: {current_user.goal or 'fitness'}, Level: {current_user.level or 'intermediate'}
Streak: {current_user.streak} days
{f"Low Vitamin D: {health.vitamin_d}" if health and health.vitamin_d and health.vitamin_d < 30 else ""}
Return a single motivational, actionable insight in 2 sentences max. Be specific and personal."""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=150,
        messages=[{"role": "user", "content": prompt}]
    )
    return {"insight": message.content[0].text.strip()}
