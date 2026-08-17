"""Authentication endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select

from app_auth.hashing import hash_password, verify_password
from app_auth.sessions import create_session, is_session_valid
from app_database.engine import Database
from app_schemas.contracts import (
    SessionResponse,
    UserCreate,
    UserLogin,
    UserResponse,
)
from app_schemas.database import Session, User

from ..dependencies import get_database

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(
    user_data: UserCreate,
    db: Database = Depends(get_database),
):
    """Register a new user."""
    async with db.session() as session:
        # Check if email exists
        result = await session.execute(
            select(User).where(User.email == user_data.email)
        )
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )
        
        # Create user
        user = User(
            email=user_data.email,
            password_hash=hash_password(user_data.password),
            full_name=user_data.full_name,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        
        return user


@router.post("/login", response_model=SessionResponse)
async def login(
    credentials: UserLogin,
    db: Database = Depends(get_database),
):
    """Login and create session."""
    async with db.session() as session:
        # Find user
        result = await session.execute(
            select(User).where(User.email == credentials.email)
        )
        user = result.scalar_one_or_none()
        
        if not user or not verify_password(
            credentials.password, user.password_hash
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials",
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account disabled",
            )
        
        # Create session
        user_session = create_session(user.id)
        session.add(user_session)
        await session.commit()
        
        return SessionResponse(
            user=UserResponse.model_validate(user),
            session_id=user_session.id,
            expires_at=user_session.expires_at,
        )


@router.post("/logout")
async def logout(
    session_id: str,
    db: Database = Depends(get_database),
):
    """Logout and invalidate session."""
    async with db.session() as session:
        result = await session.execute(
            select(Session).where(Session.id == session_id)
        )
        user_session = result.scalar_one_or_none()
        
        if user_session:
            await session.delete(user_session)
            await session.commit()
        
        return {"status": "ok"}
