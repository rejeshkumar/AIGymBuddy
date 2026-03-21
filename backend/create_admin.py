#!/usr/bin/env python3
"""Create or promote a user to admin. Usage: python create_admin.py <email> [password]"""
import sys
from db import SessionLocal
from models import User
from auth import get_password_hash

def main():
    if len(sys.argv) < 2:
        print("Usage: python create_admin.py <email> [password]")
        print("  If user exists: promotes to admin. If new: creates admin with password.")
        sys.exit(1)
    email = sys.argv[1].strip()
    password = sys.argv[2] if len(sys.argv) > 2 else None

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if user:
            user.role = "admin"
            if password and len(password) >= 6:
                user.password = get_password_hash(password)
                print(f"User {email} promoted to admin. Password updated.")
            else:
                print(f"User {email} promoted to admin. (Pass a password to reset it.)")
            db.commit()
        else:
            if not password or len(password) < 6:
                print("New user requires password (min 6 chars)")
                sys.exit(1)
            user = User(
                email=email,
                password=get_password_hash(password),
                goal="general",
                role="admin",
            )
            db.add(user)
            db.commit()
            print(f"Admin user {email} created.")
    finally:
        db.close()

if __name__ == "__main__":
    main()
