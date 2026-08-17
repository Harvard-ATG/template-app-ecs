"""Base application settings."""
from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Base settings for all services."""
    
    model_config = SettingsConfigDict(
        env_prefix="APP_",
        env_file=".env",
        extra="ignore",
    )
    
    # Environment
    environment: str = Field(default="development")
    log_level: str = Field(default="INFO")
    
    # Security
    secret_key: str = Field(
        default="dev-secret-change-in-production",
        description="Secret key for session encryption"
    )
    cookie_secure: bool = Field(
        default=True,
        description="Use secure cookies (HTTPS only)"
    )
    
    # LLM Configuration (Optional)
    anthropic_api_key: str | None = Field(
        default=None,
        description="Anthropic API key for Claude (optional)"
    )
    default_model: str = Field(
        default="claude-opus-4-8",
        description="Default Claude model"
    )
    max_tokens: int = Field(default=4096)
    temperature: float = Field(default=0.7)
    
    # CORS
    allowed_origins: list[str] = Field(
        default_factory=lambda: ["http://localhost:3000"],
        description="CORS allowed origins"
    )
    
    @computed_field
    @property
    def llm_enabled(self) -> bool:
        """Check if LLM features are enabled."""
        return bool(self.anthropic_api_key)
