from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from db import get_db
from models import User, Workout, Group, UserGroup
from schemas import GroupCreate
from auth import get_current_user

router = APIRouter()


@router.get("/leaderboard")
def get_leaderboard(
    group_id: int | None = None,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Leaderboard by workout count. Optionally filter by group_id."""
    subq = (
        db.query(Workout.user_id, func.count(Workout.id).label("cnt"))
        .filter(Workout.completed == True)
        .group_by(Workout.user_id)
    ).subquery()

    workout_count = func.coalesce(subq.c.cnt, 0).label("workout_count")
    q = (
        db.query(User.id, User.email, workout_count)
        .outerjoin(subq, User.id == subq.c.user_id)
    )

    if group_id is not None:
        ug_ids = db.query(UserGroup.user_id).filter(
            UserGroup.group_id == group_id
        ).subquery()
        q = q.filter(User.id.in_(ug_ids))

    rows = q.order_by(desc(workout_count)).limit(limit).all()

    leaderboard = []
    for rank, (uid, email, cnt) in enumerate(rows, 1):
        leaderboard.append({
            "user_id": uid,
            "email": email or "",
            "workout_count": int(cnt) if cnt is not None else 0,
            "rank": rank,
        })

    return {"leaderboard": leaderboard}


@router.get("/groups")
def get_groups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get groups the user belongs to."""
    user_groups = (
        db.query(Group)
        .join(UserGroup, UserGroup.group_id == Group.id)
        .filter(UserGroup.user_id == current_user.id)
        .all()
    )
    return {
        "groups": [{"id": g.id, "name": g.name} for g in user_groups],
    }


@router.post("/groups")
def create_group(
    body: GroupCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    name = body.name.strip() or "My Group"
    """Create a group and add current user as member."""
    group = Group(name=name)
    db.add(group)
    db.commit()
    db.refresh(group)
    ug = UserGroup(user_id=current_user.id, group_id=group.id)
    db.add(ug)
    db.commit()
    return {"id": group.id, "name": group.name}


@router.post("/groups/{group_id}/join")
def join_group(
    group_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Join an existing group."""
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    existing = db.query(UserGroup).filter(
        UserGroup.user_id == current_user.id,
        UserGroup.group_id == group_id,
    ).first()
    if existing:
        return {"message": "Already in group", "group": {"id": group.id, "name": group.name}}
    ug = UserGroup(user_id=current_user.id, group_id=group_id)
    db.add(ug)
    db.commit()
    return {"message": "Joined", "group": {"id": group.id, "name": group.name}}
