"""FastAPI application entry point."""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app_schemas.settings import Settings

from .dependencies import get_database
from .routers import auth, health, llm

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    db = get_database()
    
    # Log LLM status
    settings = Settings()
    if settings.llm_enabled:
        logger.info("LLM features enabled - Anthropic API key configured")
    else:
        logger.warning(
            "LLM features disabled - No Anthropic API key provided. "
            "Set APP_ANTHROPIC_API_KEY to enable LLM endpoints."
        )
    
    yield
    # Shutdown
    await db.close()


def create_app(settings: Settings | None = None) -> FastAPI:
    """Create and configure FastAPI application."""
    if settings is None:
        settings = Settings()
    
    app = FastAPI(
        title="App API",
        version="0.1.0",
        lifespan=lifespan,
    )
    
    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Routers
    app.include_router(health.router, prefix="/api/v1", tags=["health"])
    app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
    app.include_router(llm.router, prefix="/api/v1/llm", tags=["llm"])
    
    return app


# Application instance
app = create_app()
