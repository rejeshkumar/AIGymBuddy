import os, json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
from typing import Optional
import anthropic
from core.database import get_db
from core.security import get_current_user
from models.user import User
from models.health_record import HealthRecord

router = APIRouter()
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

class VitalsRequest(BaseModel):
    blood_pressure: Optional[str] = None
    resting_hr: Optional[float] = None
    blood_glucose: Optional[float] = None
    vo2_max: Optional[float] = None
    cholesterol: Optional[float] = None
    body_fat_pct: Optional[float] = None
    vitamin_d: Optional[float] = None
    hemoglobin: Optional[float] = None

class ReportTextRequest(BaseModel):
    report_text: str

@router.post("/vitals")
async def save_vitals(
    req: VitalsRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    vitals_dict = req.model_dump(exclude_none=True)
    insights = await _generate_health_insights(current_user, vitals_dict)

    record = HealthRecord(
        user_id=current_user.id,
        ai_insights=json.dumps(insights),
        **vitals_dict
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)

    return {
        "id": record.id,
        "vitals": vitals_dict,
        "insights": insights,
        "message": "Health data saved and analysed by AI"
    }

@router.post("/report/analyse")
async def analyse_report(
    req: ReportTextRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    prompt = f"""You are a medical AI assistant. Analyse this health report text and extract key values.
Return ONLY valid JSON, no other text:
{{
  "extracted": {{
    "blood_pressure": "120/80 or null",
    "resting_hr": 65.0,
    "blood_glucose": 95.0,
    "cholesterol": 180.0,
    "vitamin_d": 32.0,
    "hemoglobin": 14.2,
    "body_fat_pct": null
  }},
  "insights": [
    {{"level": "good", "marker": "Hemoglobin", "message": "Your hemoglobin is excellent - great for endurance training"}},
    {{"level": "warn", "marker": "Cholesterol", "message": "Slightly elevated - reduce saturated fats, add cardio 3x/week"}},
    {{"level": "alert", "marker": "Vitamin D", "message": "Low Vitamin D affects muscle recovery. Take 2000 IU daily"}}
  ],
  "training_impact": "How these results affect training plan in 2-3 sentences"
}}

Health report text:
{req.report_text[:3000]}"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )

    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    data = json.loads(raw.strip())

    record = HealthRecord(
        user_id=current_user.id,
        report_text=req.report_text,
        ai_insights=json.dumps(data.get("insights", [])),
        **{k: v for k, v in data.get("extracted", {}).items() if v is not None and k != "blood_pressure"}
    )
    if data.get("extracted", {}).get("blood_pressure"):
        record.blood_pressure = data["extracted"]["blood_pressure"]
    db.add(record)
    await db.commit()

    return data

@router.get("/latest")
async def get_latest_health(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(HealthRecord)
        .where(HealthRecord.user_id == current_user.id)
        .order_by(desc(HealthRecord.recorded_at))
        .limit(1)
    )
    record = result.scalar_one_or_none()
    if not record:
        return {"message": "No health records yet"}

    return {
        "blood_pressure": record.blood_pressure,
        "resting_hr": record.resting_hr,
        "blood_glucose": record.blood_glucose,
        "vo2_max": record.vo2_max,
        "cholesterol": record.cholesterol,
        "body_fat_pct": record.body_fat_pct,
        "vitamin_d": record.vitamin_d,
        "hemoglobin": record.hemoglobin,
        "insights": json.loads(record.ai_insights) if record.ai_insights else [],
        "recorded_at": record.recorded_at.isoformat(),
    }

async def _generate_health_insights(user: User, vitals: dict) -> list:
    prompt = f"""Analyse these health vitals for a {user.age or 'adult'} year old with goal: {user.goal or 'fitness'}.
Vitals: {json.dumps(vitals)}
Return ONLY a JSON array of insights:
[{{"level": "good|warn|alert", "marker": "Vital name", "message": "Specific actionable insight"}}]
Give 3-5 insights maximum."""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=600,
        messages=[{"role": "user", "content": prompt}]
    )
    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
    return json.loads(raw.strip())
