"""Create database tables. Run after PostgreSQL is up."""
from sqlalchemy import text
from db import engine
from models import Base, User, Workout, WorkoutExercise, Group, UserGroup  # noqa: F401 - register models

if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    # Migration: add completed_sets for existing workout_exercises (PostgreSQL)
    url_str = str(engine.url)
    try:
        with engine.connect() as conn:
            if "postgresql" in url_str:
                conn.execute(text(
                    "ALTER TABLE workout_exercises ADD COLUMN IF NOT EXISTS completed_sets INTEGER DEFAULT 0"
                ))
                conn.execute(text(
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'user'"
                ))
            elif "sqlite" in url_str:
                try:
                    conn.execute(text(
                        "ALTER TABLE workout_exercises ADD COLUMN completed_sets INTEGER DEFAULT 0"
                    ))
                except Exception:
                    pass
                try:
                    conn.execute(text(
                        "ALTER TABLE users ADD COLUMN role VARCHAR DEFAULT 'user'"
                    ))
                except Exception:
                    pass
            conn.commit()
    except Exception:
        pass  # Columns may already exist
    print("Tables created successfully.")
