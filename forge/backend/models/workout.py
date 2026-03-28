import uuid
from datetime import datetime
from sqlalchemy import String, Integer, Float, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class Workout(Base):
    __tablename__ = "workouts"

    id:          Mapped[str]      = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id:     Mapped[str]      = mapped_column(String, ForeignKey("users.id"), index=True)
    title:       Mapped[str]      = mapped_column(String(255))
    muscle_group:Mapped[str]      = mapped_column(String(100))
    duration_min:Mapped[int]      = mapped_column(Integer)
    kcal_burned: Mapped[int|None] = mapped_column(Integer, nullable=True)
    equipment:   Mapped[str]      = mapped_column(String(100))
    level:       Mapped[str]      = mapped_column(String(50))
    exercises:   Mapped[str]      = mapped_column(Text)   # JSON string
    completed:   Mapped[bool]     = mapped_column(Boolean, default=False)
    ai_generated:Mapped[bool]     = mapped_column(Boolean, default=True)
    notes:       Mapped[str|None] = mapped_column(Text, nullable=True)
    created_at:  Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    completed_at:Mapped[datetime|None] = mapped_column(DateTime, nullable=True)
