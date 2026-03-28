import uuid
from datetime import datetime
from sqlalchemy import String, Integer, Float, DateTime, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column
from core.database import Base

class User(Base):
    __tablename__ = "users"

    id:           Mapped[str]      = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email:        Mapped[str]      = mapped_column(String(255), unique=True, index=True)
    name:         Mapped[str]      = mapped_column(String(255))
    password_hash:Mapped[str]      = mapped_column(String(255))
    age:          Mapped[int|None] = mapped_column(Integer, nullable=True)
    gender:       Mapped[str|None] = mapped_column(String(20), nullable=True)
    height_cm:    Mapped[float|None] = mapped_column(Float, nullable=True)
    weight_kg:    Mapped[float|None] = mapped_column(Float, nullable=True)
    goal:         Mapped[str|None] = mapped_column(String(100), nullable=True)
    level:        Mapped[str|None] = mapped_column(String(50), nullable=True)
    gym_name:     Mapped[str|None] = mapped_column(String(255), nullable=True)
    trainer_name: Mapped[str|None] = mapped_column(String(255), nullable=True)
    streak:       Mapped[int]      = mapped_column(Integer, default=0)
    total_workouts:Mapped[int]     = mapped_column(Integer, default=0)
    xp:           Mapped[int]      = mapped_column(Integer, default=0)
    is_active:    Mapped[bool]     = mapped_column(Boolean, default=True)
    created_at:   Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    last_login:   Mapped[datetime|None] = mapped_column(DateTime, nullable=True)
