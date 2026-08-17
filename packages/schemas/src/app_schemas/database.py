"""Database models (SQLModel)."""
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


class User(SQLModel, table=True):
    """User account."""
    
    __tablename__ = "users"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True, max_length=255)
    password_hash: str = Field(max_length=255)
    full_name: Optional[str] = Field(default=None, max_length=255)
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class Session(SQLModel, table=True):
    """User session."""
    
    __tablename__ = "sessions"
    
    id: str = Field(primary_key=True, max_length=64)
    user_id: int = Field(foreign_key="users.id", index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    last_activity: datetime = Field(default_factory=datetime.utcnow)


class LLMConversation(SQLModel, table=True):
    """LLM conversation history."""
    
    __tablename__ = "llm_conversations"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    model: str = Field(max_length=100)
    prompt: str
    response: str
    tokens_used: int
    created_at: datetime = Field(default_factory=datetime.utcnow)
