"""Session management.

This module implements database-backed sessions using PostgreSQL.
Sessions are stored in the database, not Redis, which makes Redis optional
for the infrastructure. This simplifies deployment and reduces costs while
maintaining security and functionality.

For high-traffic applications, sessions could be migrated to Redis by:
1. Adding redis settings to app_schemas/settings.py
2. Implementing a RedisSessionStore class
3. Updating authentication middleware to use Redis
"""
import secrets
from datetime import datetime, timedelta

from app_schemas.database import Session


def generate_session_id() -> str:
    """Generate a cryptographically secure session ID."""
    return secrets.token_urlsafe(48)


def create_session(
    user_id: int,
    ttl_days: int = 30,
) -> Session:
    """Create a new session."""
    session_id = generate_session_id()
    now = datetime.utcnow()
    expires_at = now + timedelta(days=ttl_days)
    
    return Session(
        id=session_id,
        user_id=user_id,
        created_at=now,
        expires_at=expires_at,
        last_activity=now,
    )


def is_session_valid(session: Session) -> bool:
    """Check if a session is still valid."""
    return datetime.utcnow() < session.expires_at
