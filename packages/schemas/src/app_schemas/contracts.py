"""API request/response contracts."""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field


# Health check
class HealthResponse(BaseModel):
    """Health check response."""
    status: Literal["ok", "degraded", "down"]
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    version: str = "0.1.0"
    database: Literal["ok", "down"] = "ok"
    cache: Literal["ok", "down"] = "ok"


# Authentication
class UserCreate(BaseModel):
    """User registration request."""
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    full_name: str | None = None


class UserLogin(BaseModel):
    """User login request."""
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """User response (safe for API)."""
    id: int
    email: EmailStr
    full_name: str | None
    created_at: datetime
    
    model_config = {"from_attributes": True}


class SessionResponse(BaseModel):
    """Session response after login."""
    user: UserResponse
    session_id: str
    expires_at: datetime


# LLM Interaction
class LLMRequest(BaseModel):
    """LLM completion request."""
    prompt: str = Field(min_length=1, max_length=10000)
    system_prompt: str | None = None
    model: str | None = None
    max_tokens: int | None = None
    temperature: float | None = Field(default=None, ge=0.0, le=2.0)
    stream: bool = False


class LLMResponse(BaseModel):
    """LLM completion response."""
    content: str
    model: str
    usage: dict[str, int]
    finish_reason: str
