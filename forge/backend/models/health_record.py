import uuid
from datetime import datetime
from sqlalchemy import String, Float, DateTime, Text, ForeignKey, Date
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class HealthRecord(Base):
    __tablename__ = "health_records"

    id:            Mapped[str]       = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id:       Mapped[str]       = mapped_column(String, ForeignKey("users.id"), index=True)
    blood_pressure:Mapped[str|None]  = mapped_column(String(20), nullable=True)   # "120/80"
    resting_hr:    Mapped[float|None]= mapped_column(Float, nullable=True)
    blood_glucose: Mapped[float|None]= mapped_column(Float, nullable=True)
    vo2_max:       Mapped[float|None]= mapped_column(Float, nullable=True)
    cholesterol:   Mapped[float|None]= mapped_column(Float, nullable=True)
    body_fat_pct:  Mapped[float|None]= mapped_column(Float, nullable=True)
    vitamin_d:     Mapped[float|None]= mapped_column(Float, nullable=True)
    hemoglobin:    Mapped[float|None]= mapped_column(Float, nullable=True)
    ai_insights:   Mapped[str|None]  = mapped_column(Text, nullable=True)  # JSON
    report_text:   Mapped[str|None]  = mapped_column(Text, nullable=True)
    recorded_at:   Mapped[datetime]  = mapped_column(DateTime, default=datetime.utcnow)


class WeightLog(Base):
    __tablename__ = "weight_logs"

    id:         Mapped[str]   = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id:    Mapped[str]   = mapped_column(String, ForeignKey("users.id"), index=True)
    weight_kg:  Mapped[float] = mapped_column(Float)
    logged_date:Mapped[str]   = mapped_column(String(20))   # "2025-03-27"
    note:       Mapped[str|None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
