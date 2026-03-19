from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date, timedelta

from db import get_db
from models import User, Workout, WorkoutExercise
from schemas import (
    WorkoutResponse,
    ExerciseItem,
    WorkoutCompleteRequest,
    WorkoutHistoryItem,
    WorkoutStatsResponse,
)
from auth import get_current_user

router = APIRouter()

# Rule-based workout logic (MVP)
WORKOUT_RULES = {
    "weight_loss": [
        {"name": "Jumping Jacks", "sets": 3, "reps": 30},
        {"name": "Squats", "sets": 3, "reps": 15},
        {"name": "Running in Place", "sets": 3, "reps": 60},
        {"name": "Burpees", "sets": 2, "reps": 10},
    ],
    "muscle_gain": [
        {"name": "Push-ups", "sets": 4, "reps": 12},
        {"name": "Squats", "sets": 4, "reps": 12},
        {"name": "Lunges", "sets": 3, "reps": 12},
        {"name": "Plank", "sets": 3, "reps": 45},
    ],
    "general": [
        {"name": "Squats", "sets": 3, "reps": 12},
        {"name": "Push-ups", "sets": 3, "reps": 10},
        {"name": "Lunges", "sets": 3, "reps": 10},
        {"name": "Jumping Jacks", "sets": 2, "reps": 25},
    ],
}


@router.get("/workout/today", response_model=WorkoutResponse)
def get_today_workout(current_user: User = Depends(get_current_user)):
    goal = current_user.goal or "general"
    exercises = WORKOUT_RULES.get(goal, WORKOUT_RULES["general"])
    return {
        "exercises": [ExerciseItem(**e) for e in exercises],
        "goal": goal,
    }


@router.post("/workout/complete")
def complete_workout(
    body: WorkoutCompleteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Save Workout + WorkoutExercise records to DB."""
    workout = Workout(
        user_id=current_user.id,
        completed=True,
        completed_at=datetime.utcnow(),
    )
    db.add(workout)
    db.commit()
    db.refresh(workout)

    for ex in body.exercises:
        we = WorkoutExercise(
            workout_id=workout.id,
            name=ex.name,
            sets=ex.sets,
            reps=ex.reps,
            completed=ex.completed_sets >= ex.sets,
            completed_sets=ex.completed_sets,
        )
        db.add(we)
    db.commit()

    return {"status": "completed", "workout_id": workout.id, "message": "Workout logged!"}


@router.get("/workout/history", response_model=list)
def get_workout_history(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get user's workout history."""
    workouts = (
        db.query(Workout)
        .filter(Workout.user_id == current_user.id, Workout.completed == True)
        .order_by(Workout.completed_at.desc())
        .limit(limit)
        .all()
    )
    result = []
    for w in workouts:
        exercises = (
            db.query(WorkoutExercise)
            .filter(WorkoutExercise.workout_id == w.id)
            .all()
        )
        result.append({
            "id": w.id,
            "completed_at": w.completed_at.isoformat() if w.completed_at else None,
            "exercises": [
                {"name": e.name, "sets": e.sets, "reps": e.reps}
                for e in exercises
            ],
        })
    return result


@router.get("/workout/stats", response_model=WorkoutStatsResponse)
def get_workout_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get streak and total workout stats."""
    completed = (
        db.query(Workout)
        .filter(Workout.user_id == current_user.id, Workout.completed == True)
        .all()
    )
    total_workouts = len(completed)

    # Get unique dates (user timezone naive - use UTC dates for simplicity)
    dates_set = set(
        w.completed_at.date() if w.completed_at else date.today()
        for w in completed
    )
    dates = sorted(dates_set, reverse=True)

    today = date.today()
    current_streak = 0
    if dates and dates[0] >= today - timedelta(days=1):
        # Count consecutive days going backwards from most recent
        d = dates[0]
        while d in dates_set:
            current_streak += 1
            d -= timedelta(days=1)

    longest_streak = 0
    streak = 0
    sorted_dates = sorted(dates_set)
    for i, d in enumerate(sorted_dates):
        if i == 0 or (d - sorted_dates[i - 1]).days == 1:
            streak += 1
        else:
            streak = 1
        longest_streak = max(longest_streak, streak)

    return WorkoutStatsResponse(
        total_workouts=total_workouts,
        current_streak=current_streak,
        longest_streak=longest_streak,
    )
