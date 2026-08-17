"""Dependency injection containers."""
from functools import lru_cache

from app_database.engine import Database
from app_database.settings import DatabaseSettings
from app_llm.client import LLMClient
from app_schemas.settings import Settings


@lru_cache
def get_settings() -> Settings:
    """Get application settings (cached)."""
    return Settings()


@lru_cache
def get_database() -> Database:
    """Get database connection (cached)."""
    settings = DatabaseSettings()
    return Database(settings)


@lru_cache
def get_llm_client() -> LLMClient | None:
    """Get LLM client (cached). Returns None if API key not configured."""
    settings = get_settings()
    if not settings.llm_enabled:
        return None
    try:
        return LLMClient(settings)
    except ValueError:
        return None
