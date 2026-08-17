"""Database settings."""
from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class DatabaseSettings(BaseSettings):
    """Database configuration."""
    
    model_config = SettingsConfigDict(
        env_prefix="APP_DB_",
        extra="ignore",
    )
    
    host: str = Field(default="localhost")
    port: int = Field(default=5432)
    user: str = Field(default="app_user")
    password: str = Field(default="")
    name: str = Field(default="app_db")
    
    pool_size: int = Field(default=10)
    max_overflow: int = Field(default=10)
    pool_timeout: float = Field(default=30.0)
    pool_recycle: int = Field(default=3600)
    
    echo: bool = Field(default=False)
    
    @computed_field
    @property
    def url(self) -> str:
        """Construct async PostgreSQL DSN."""
        if self.password:
            return (
                f"postgresql+asyncpg://{self.user}:{self.password}"
                f"@{self.host}:{self.port}/{self.name}"
            )
        return (
            f"postgresql+asyncpg://{self.user}"
            f"@{self.host}:{self.port}/{self.name}"
        )
