from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from db import get_db
from models import User
from schemas import UserResponse, AdminUserCreate, AdminUserUpdate
from auth import get_current_user, get_current_admin, get_password_hash

router = APIRouter()


@router.get("/admin/users", response_model=list)
def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: str | None = None,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    q = db.query(User)
    if search:
        q = q.filter(User.email.ilike(f"%{search}%"))
    users = q.order_by(User.created_at.desc()).offset(skip).limit(limit).all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "age": u.age,
            "height": u.height,
            "weight": u.weight,
            "goal": u.goal or "general",
            "role": u.role or "user",
            "created_at": u.created_at.isoformat() if u.created_at else None,
        }
        for u in users
    ]


@router.post("/admin/users", response_model=dict)
def create_user(
    body: AdminUserCreate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(
        email=body.email,
        password=get_password_hash(body.password),
        age=body.age,
        height=body.height,
        weight=body.weight,
        goal=body.goal,
        role=body.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"id": user.id, "email": user.email, "role": user.role, "message": "User created"}


@router.get("/admin/users/{user_id}", response_model=dict)
def get_user(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user.id,
        "email": user.email,
        "age": user.age,
        "height": user.height,
        "weight": user.weight,
        "goal": user.goal or "general",
        "role": user.role or "user",
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }


@router.patch("/admin/users/{user_id}")
def update_user(
    user_id: int,
    body: AdminUserUpdate,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    data = body.model_dump(exclude_unset=True)
    if "password" in data and data["password"]:
        data["password"] = get_password_hash(data["password"])
    else:
        data.pop("password", None)
    for k, v in data.items():
        setattr(user, k, v)
    db.commit()
    db.refresh(user)
    return {"message": "User updated", "id": user.id}


@router.delete("/admin/users/{user_id}")
def delete_user(
    user_id: int,
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted"}


@router.get("/admin/stats")
def admin_stats(
    current_user: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    from models import Workout
    from sqlalchemy import func
    total_users = db.query(User).count()
    total_workouts = db.query(Workout).filter(Workout.completed == True).count()
    return {"total_users": total_users, "total_workouts": total_workouts}
