from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    age: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    goal: str = "general"


class UserResponse(BaseModel):
    id: int
    email: str
    age: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    goal: str
    role: Optional[str] = "user"

    class Config:
        from_attributes = True


class AdminUserCreate(BaseModel):
    email: EmailStr
    password: str
    age: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    goal: str = "general"
    role: str = "user"


class AdminUserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = None
    age: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    goal: Optional[str] = None
    role: Optional[str] = None


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ExerciseItem(BaseModel):
    name: str
    sets: int
    reps: int


class WorkoutResponse(BaseModel):
    exercises: List[ExerciseItem]
    goal: str


class ExerciseCompleteItem(BaseModel):
    name: str
    sets: int
    reps: int
    completed_sets: int = 0


class WorkoutCompleteRequest(BaseModel):
    exercises: List[ExerciseCompleteItem]


class WorkoutHistoryItem(BaseModel):
    id: int
    completed_at: Optional[datetime] = None
    exercises: List[ExerciseItem]

    class Config:
        from_attributes = True


class WorkoutStatsResponse(BaseModel):
    total_workouts: int
    current_streak: int
    longest_streak: int


class LeaderboardEntry(BaseModel):
    user_id: int
    email: str
    workout_count: int
    rank: int


class GroupItem(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class GroupCreate(BaseModel):
    name: str = "My Group"


class HealthReportResponse(BaseModel):
    hba1c: Optional[float] = None
    cholesterol: Optional[float] = None
    raw_text: Optional[str] = None
