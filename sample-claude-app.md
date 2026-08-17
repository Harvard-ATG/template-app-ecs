Full-Stack Application Template: FastAPI + Next.js + LLM + AWS ECS
Purpose: This document provides comprehensive instructions for creating a production-ready, containerized full-stack application with LLM integration, deployed on AWS ECS.
Audience: AI coding agents and developers scaffolding new applications
Architecture Pattern: Modern monorepo with clear service boundaries, type-safe contracts, and infrastructure-as-code
---
Table of Contents
1. Architecture Overview (#architecture-overview)
2. Technology Stack (#technology-stack)
3. Project Structure (#project-structure)
4. Prerequisites (#prerequisites)
5. Step-by-Step Scaffolding (#step-by-step-scaffolding)
6. AWS Infrastructure (Terraform) (#aws-infrastructure-terraform)
7. Docker Containerization (#docker-containerization)
8. Development Environment (#development-environment)
9. Deployment Pipeline (#deployment-pipeline)
10. Production Checklist (#production-checklist)
11. Common Patterns & Best Practices (#common-patterns--best-practices)
---
Architecture Overview
System Components
┌─────────────────────────────────────────────────────────────┐
│                     Application Load Balancer               │
│                    (HTTPS Termination)                       │
└───────────────┬─────────────────────────┬───────────────────┘
                │                         │
     ┌──────────▼──────────┐   ┌─────────▼──────────┐
     │   Frontend Service   │   │    API Service     │
     │   (Next.js)          │   │    (FastAPI)       │
     │   Port: 3000         │   │    Port: 8000      │
     └──────────────────────┘   └─────────┬──────────┘
                                           │
                        ┌──────────────────┼──────────────────┐
                        │                  │                  │
              ┌─────────▼────────┐  ┌──────▼─────┐  ┌───────▼────────┐
              │   RDS PostgreSQL  │  │ ElastiCache│  │  LLM API       │
              │   (Primary + Read)│  │  (Redis)   │  │  (Anthropic)   │
              └──────────────────┘  └────────────┘  └────────────────┘
Service Responsibilities
1. Frontend Service - Next.js standalone server (SSR/SSG)
2. API Service - FastAPI with async PostgreSQL, background tasks, LLM orchestration
3. Migration Job - Alembic database schema management (ECS Fargate task)
4. Worker Service (Optional) - Background job processor (Celery/arq)
---
Technology Stack
Backend
- Language: Python 3.13+
- Framework: FastAPI 0.136+
- ASGI Server: Uvicorn with standard extras
- Database: PostgreSQL 16+ (via RDS)
- ORM: SQLModel + SQLAlchemy 2.0 (async)
- Migrations: Alembic
- Caching: Redis (via ElastiCache)
- LLM SDK: Anthropic Claude SDK 0.40+
- Validation: Pydantic 2.13+
- Authentication: argon2-cffi for password hashing
- Async Driver: asyncpg
Frontend
- Framework: Next.js 16+ (App Router)
- Language: TypeScript 5.9+
- Styling: Tailwind CSS 4.0+
- Package Manager: pnpm 11+
- Type Generation: openapi-typescript (contract-driven)
Infrastructure (AWS)
- Compute: ECS Fargate
- Database: RDS PostgreSQL (Multi-AZ)
- Cache: ElastiCache Redis
- Secrets: AWS Secrets Manager
- Load Balancer: Application Load Balancer (ALB)
- Container Registry: ECR
- Logging: CloudWatch Logs
- Monitoring: CloudWatch Metrics + Alarms
- IaC: Terraform 1.9+
DevOps
- CI/CD: GitHub Actions
- Container: Docker + Docker Compose (local dev)
- Observability: OpenTelemetry + CloudWatch
- Testing: pytest (backend), Jest (frontend)
- Linting: ESLint (frontend), Ruff (backend)
- Type Checking: Pyright (backend), TypeScript (frontend)
---
Project Structure
project-root/
├── infrastructure/              # Terraform IaC
│   ├── modules/
│   │   ├── ecs/                # ECS cluster, services, task definitions
│   │   ├── rds/                # PostgreSQL RDS instance
│   │   ├── elasticache/        # Redis cluster
│   │   ├── networking/         # VPC, subnets, security groups
│   │   ├── alb/                # Application Load Balancer
│   │   └── ecr/                # Container registry
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── packages/                    # Python packages (monorepo)
│   ├── schemas/                # Pydantic models, shared types
│   │   ├── src/
│   │   │   └── app_schemas/
│   │   │       ├── __init__.py
│   │   │       ├── settings.py       # Base settings
│   │   │       ├── contracts.py      # API request/response models
│   │   │       ├── database.py       # DB models (SQLModel)
│   │   │       └── llm.py           # LLM-specific schemas
│   │   └── pyproject.toml
│   │
│   ├── database/               # Database layer
│   │   ├── src/
│   │   │   └── app_database/
│   │   │       ├── __init__.py
│   │   │       ├── settings.py
│   │   │       ├── engine.py         # Async engine setup
│   │   │       ├── session.py        # Session management
│   │   │       ├── models/          # SQLModel tables
│   │   │       └── migrations/      # Alembic versions
│   │   │           ├── env.py
│   │   │           └── versions/
│   │   └── pyproject.toml
│   │
│   ├── auth/                   # Authentication module
│   │   ├── src/
│   │   │   └── app_auth/
│   │   │       ├── __init__.py
│   │   │       ├── hashing.py        # Password hashing (argon2)
│   │   │       ├── sessions.py       # Session management
│   │   │       ├── tokens.py         # JWT/API tokens
│   │   │       └── middleware.py     # Auth middleware
│   │   └── pyproject.toml
│   │
│   ├── llm/                    # LLM integration
│   │   ├── src/
│   │   │   └── app_llm/
│   │   │       ├── __init__.py
│   │   │       ├── client.py         # Anthropic client wrapper
│   │   │       ├── prompts.py        # Prompt templates
│   │   │       ├── streaming.py      # SSE streaming
│   │   │       └── agents.py         # Agent workflows
│   │   └── pyproject.toml
│   │
│   └── api/                    # FastAPI service
│       ├── src/
│       │   └── app_api/
│       │       ├── __init__.py
│       │       ├── main.py           # FastAPI app
│       │       ├── settings.py
│       │       ├── dependencies.py   # DI containers
│       │       ├── middleware/
│       │       ├── routers/
│       │       │   ├── health.py
│       │       │   ├── auth.py
│       │       │   ├── llm.py
│       │       │   └── data.py
│       │       └── background/       # Background tasks
│       ├── tests/
│       ├── Dockerfile
│       └── pyproject.toml
│
├── frontend/                    # Next.js application
│   ├── src/
│   │   ├── app/                # App Router pages
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   ├── login/
│   │   │   └── dashboard/
│   │   ├── components/
│   │   ├── lib/
│   │   │   ├── api-client.ts        # Generated API client
│   │   │   ├── types.d.ts           # Generated from OpenAPI
│   │   │   └── auth.ts
│   │   └── styles/
│   ├── public/
│   ├── scripts/
│   │   └── gen-types.mjs            # OpenAPI → TypeScript
│   ├── next.config.ts
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   ├── package.json
│   ├── Dockerfile
│   └── server.js                    # Custom standalone server
│
├── scripts/
│   ├── check_drift.sh               # Contract validation
│   ├── seed_db.py                   # Database seeding
│   └── run_migrations.sh            # Alembic wrapper
│
├── .github/
│   └── workflows/
│       ├── ci.yml                   # Tests + linting
│       ├── build.yml                # Docker builds
│       └── deploy.yml               # ECS deployments
│
├── docker-compose.yml               # Local development
├── .env.example
├── README.md
└── Makefile                         # Common tasks
---
## Prerequisites
### Required Tools
- **Docker** 24+ and Docker Compose 2.20+
- **Terraform** 1.9+
- **AWS CLI** 2.x (configured with credentials)
- **Python** 3.13+
- **Node.js** 22+
- **pnpm** 11+
- **uv** (Python package manager, optional but recommended)
### AWS Account Setup
- IAM user with ECS, RDS, ECR, VPC, ALB, Secrets Manager permissions
- S3 bucket for Terraform state
- Route53 hosted zone (for custom domain)
---
Step-by-Step Scaffolding
Phase 1: Initialize Project Structure
# Create root directory
mkdir my-app && cd my-app
# Create monorepo structure
mkdir -p packages/{schemas,database,auth,llm,api}/src
mkdir -p frontend/src/{app,components,lib,styles}
mkdir -p infrastructure/{modules,environments/{dev,staging,prod}}
mkdir -p scripts .github/workflows
# Initialize git
git init
git branch -M main
Phase 2: Backend - Schemas Package
File: packages/schemas/pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
[project]
name = "app_schemas"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "pydantic[email]~=2.13",
    "pydantic-settings~=2.13",
]
[tool.setuptools.packages.find]
where = ["src"]
[tool.setuptools.package-data]
app_schemas = ["py.typed"]
[tool.pyright]
include = ["src"]
typeCheckingMode = "standard"
File: packages/schemas/src/app_schemas/__init__.py
"""Shared schemas and settings for the application."""
from .contracts import *
from .database import *
from .settings import *
__all__ = [
    "Settings",
    "HealthResponse",
    "UserCreate",
    "UserResponse",
    "LLMRequest",
    "LLMResponse",
]
File: packages/schemas/src/app_schemas/settings.py
"""Base application settings."""
from pydantic import Field
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
        description="Secret key for session encryption"
    )
    cookie_secure: bool = Field(
        default=True,
        description="Use secure cookies (HTTPS only)"
    )
    
    # LLM Configuration
    anthropic_api_key: str = Field(
        description="Anthropic API key for Claude"
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
File: packages/schemas/src/app_schemas/contracts.py
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
File: packages/schemas/src/app_schemas/database.py
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
Phase 3: Backend - Database Package
File: packages/database/pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
[project]
name = "app_database"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "sqlmodel>=0.0.38",
    "sqlalchemy[asyncio]~=2.0.46",
    "asyncpg~=0.31",
    "alembic~=1.18",
    "typer~=0.12",
    "app_schemas",
]
[tool.uv.sources]
app_schemas = { path = "../schemas" }
[project.scripts]
app-migrate = "app_database.cli:app"
[tool.setuptools.packages.find]
where = ["src"]
[tool.pyright]
include = ["src"]
typeCheckingMode = "standard"
File: packages/database/src/app_database/settings.py
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
File: packages/database/src/app_database/engine.py
"""Database engine and session management."""
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlmodel import SQLModel
from .settings import DatabaseSettings
class Database:
    """Database connection manager."""
    
    def __init__(self, settings: DatabaseSettings):
        self.settings = settings
        self.engine: AsyncEngine = create_async_engine(
            settings.url,
            echo=settings.echo,
            pool_size=settings.pool_size,
            max_overflow=settings.max_overflow,
            pool_timeout=settings.pool_timeout,
            pool_recycle=settings.pool_recycle,
        )
        self.session_factory = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )
    
    async def create_all(self):
        """Create all tables (dev/test only)."""
        async with self.engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.create_all)
    
    async def close(self):
        """Close database connections."""
        await self.engine.dispose()
    
    @asynccontextmanager
    async def session(self) -> AsyncGenerator[AsyncSession, None]:
        """Provide a transactional scope."""
        async with self.session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise
File: packages/database/src/app_database/migrations/env.py
"""Alembic migration environment."""
import asyncio
from logging.config import fileConfig
from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from sqlmodel import SQLModel
# Import all models to ensure they're registered
from app_schemas.database import *  # noqa: F403
from app_database.settings import DatabaseSettings
config = context.config
settings = DatabaseSettings()
# Override URL from environment
config.set_main_option("sqlalchemy.url", settings.url.replace("+asyncpg", ""))
if config.config_file_name is not None:
    fileConfig(config.config_file_name)
target_metadata = SQLModel.metadata
def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    
    with context.begin_transaction():
        context.run_migrations()
def do_run_migrations(connection: Connection) -> None:
    """Run migrations with connection."""
    context.configure(connection=connection, target_metadata=target_metadata)
    
    with context.begin_transaction():
        context.run_migrations()
async def run_async_migrations() -> None:
    """Run migrations in async mode."""
    configuration = config.get_section(config.config_ini_section, {})
    configuration["sqlalchemy.url"] = settings.url
    
    connectable = async_engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    
    await connectable.dispose()
def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
File: packages/database/src/app_database/cli.py
"""CLI for database operations."""
import typer
app = typer.Typer(help="Database management commands")
@app.command()
def upgrade(revision: str = "head"):
    """Upgrade database to a later version."""
    from alembic import command
    from alembic.config import Config
    
    config = Config("alembic.ini")
    command.upgrade(config, revision)
    typer.echo(f"✓ Upgraded to {revision}")
@app.command()
def downgrade(revision: str = "-1"):
    """Revert database to a previous version."""
    from alembic import command
    from alembic.config import Config
    
    config = Config("alembic.ini")
    command.downgrade(config, revision)
    typer.echo(f"✓ Downgraded to {revision}")
@app.command()
def revision(message: str, autogenerate: bool = True):
    """Create a new migration."""
    from alembic import command
    from alembic.config import Config
    
    config = Config("alembic.ini")
    command.revision(config, message=message, autogenerate=autogenerate)
    typer.echo(f"✓ Created migration: {message}")
if __name__ == "__main__":
    app()
Phase 4: Backend - Auth Package
File: packages/auth/pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
[project]
name = "app_auth"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "argon2-cffi~=23.1",
    "pydantic~=2.13",
    "app_schemas",
]
[tool.uv.sources]
app_schemas = { path = "../schemas" }
[tool.setuptools.packages.find]
where = ["src"]
[tool.pyright]
include = ["src"]
typeCheckingMode = "standard"
File: packages/auth/src/app_auth/hashing.py
"""Password hashing utilities."""
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
# Industry-standard Argon2id parameters
_hasher = PasswordHasher(
    time_cost=2,
    memory_cost=65536,
    parallelism=4,
    hash_len=32,
    salt_len=16,
)
def hash_password(password: str) -> str:
    """Hash a password using Argon2id."""
    return _hasher.hash(password)
def verify_password(password: str, password_hash: str) -> bool:
    """Verify a password against its hash."""
    try:
        _hasher.verify(password_hash, password)
        return True
    except VerifyMismatchError:
        return False
def needs_rehash(password_hash: str) -> bool:
    """Check if hash uses outdated parameters."""
    return _hasher.check_needs_rehash(password_hash)
File: packages/auth/src/app_auth/sessions.py
"""Session management."""
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
Phase 5: Backend - LLM Package
File: packages/llm/pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
[project]
name = "app_llm"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "anthropic~=0.40",
    "pydantic~=2.13",
    "app_schemas",
]
[tool.uv.sources]
app_schemas = { path = "../schemas" }
[tool.setuptools.packages.find]
where = ["src"]
[tool.pyright]
include = ["src"]
typeCheckingMode = "standard"
File: packages/llm/src/app_llm/client.py
"""Anthropic Claude client wrapper."""
from typing import AsyncGenerator
from anthropic import AsyncAnthropic
from anthropic.types import Message, MessageStreamEvent
from app_schemas.contracts import LLMRequest, LLMResponse
from app_schemas.settings import Settings
class LLMClient:
    """Wrapper for Anthropic Claude API."""
    
    def __init__(self, settings: Settings):
        self.settings = settings
        self.client = AsyncAnthropic(api_key=settings.anthropic_api_key)
    
    async def complete(self, request: LLMRequest) -> LLMResponse:
        """Generate a completion (non-streaming)."""
        message = await self.client.messages.create(
            model=request.model or self.settings.default_model,
            max_tokens=request.max_tokens or self.settings.max_tokens,
            temperature=request.temperature or self.settings.temperature,
            system=request.system_prompt or "",
            messages=[{"role": "user", "content": request.prompt}],
        )
        
        return self._convert_response(message)
    
    async def stream(
        self, request: LLMRequest
    ) -> AsyncGenerator[str, None]:
        """Generate a streaming completion."""
        async with self.client.messages.stream(
            model=request.model or self.settings.default_model,
            max_tokens=request.max_tokens or self.settings.max_tokens,
            temperature=request.temperature or self.settings.temperature,
            system=request.system_prompt or "",
            messages=[{"role": "user", "content": request.prompt}],
        ) as stream:
            async for event in stream:
                if (
                    hasattr(event, "type")
                    and event.type == "content_block_delta"
                ):
                    yield event.delta.text
    
    def _convert_response(self, message: Message) -> LLMResponse:
        """Convert Anthropic response to our schema."""
        content = "".join(
            block.text for block in message.content if hasattr(block, "text")
        )
        
        return LLMResponse(
            content=content,
            model=message.model,
            usage={
                "input_tokens": message.usage.input_tokens,
                "output_tokens": message.usage.output_tokens,
            },
            finish_reason=message.stop_reason or "unknown",
        )
Phase 6: Backend - API Service
File: packages/api/pyproject.toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"
[project]
name = "app_api"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "fastapi~=0.136",
    "uvicorn[standard]~=0.32",
    "python-multipart~=0.0.20",
    "sse-starlette~=2.1",
    "app_schemas",
    "app_database",
    "app_auth",
    "app_llm",
]
[tool.uv.sources]
app_schemas = { path = "../schemas" }
app_database = { path = "../database" }
app_auth = { path = "../auth" }
app_llm = { path = "../llm" }
[dependency-groups]
dev = [
    "pyright~=1.1",
    "pytest~=8.3",
    "pytest-asyncio~=0.24",
    "httpx~=0.27",
]
[tool.setuptools.packages.find]
where = ["src"]
[tool.pyright]
include = ["src"]
typeCheckingMode = "standard"
[tool.pytest.ini_options]
asyncio_mode = "auto"
File: packages/api/src/app_api/main.py
"""FastAPI application entry point."""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app_schemas.settings import Settings
from .dependencies import get_database
from .routers import auth, health, llm
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    db = get_database()
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
        allow_origins=settings.allowed_origins,
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
File: packages/api/src/app_api/routers/health.py
"""Health check endpoint."""
from fastapi import APIRouter, Depends
from sqlalchemy import text
from app_database.engine import Database
from app_schemas.contracts import HealthResponse
from ..dependencies import get_database
router = APIRouter()
@router.get("/health", response_model=HealthResponse)
async def health_check(db: Database = Depends(get_database)):
    """Health check endpoint for load balancer."""
    database_status = "ok"
    
    try:
        async with db.session() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        database_status = "down"
    
    status = "ok" if database_status == "ok" else "degraded"
    
    return HealthResponse(
        status=status,
        database=database_status,
        cache="ok",  # TODO: Add Redis check
    )
File: packages/api/src/app_api/routers/auth.py
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
File: packages/api/src/app_api/routers/llm.py
"""LLM endpoints."""
from fastapi import APIRouter, Depends
from sse_starlette.sse import EventSourceResponse
from app_llm.client import LLMClient
from app_schemas.contracts import LLMRequest, LLMResponse
from ..dependencies import get_llm_client
router = APIRouter()
@router.post("/complete", response_model=LLMResponse)
async def complete(
    request: LLMRequest,
    llm: LLMClient = Depends(get_llm_client),
):
    """Generate a completion (non-streaming)."""
    if request.stream:
        return {"error": "Use /stream endpoint for streaming"}
    
    return await llm.complete(request)
@router.post("/stream")
async def stream(
    request: LLMRequest,
    llm: LLMClient = Depends(get_llm_client),
):
    """Generate a streaming completion (SSE)."""
    
    async def event_generator():
        async for chunk in llm.stream(request):
            yield {"data": chunk}
    
    return EventSourceResponse(event_generator())
File: packages/api/src/app_api/dependencies.py
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
def get_llm_client() -> LLMClient:
    """Get LLM client (cached)."""
    settings = get_settings()
    return LLMClient(settings)
Phase 7: Frontend - Next.js Application
File: frontend/package.json
{
  "name": "app-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=22"
  },
  "packageManager": "pnpm@11.1.3",
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "node server.js",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "gen-types": "node scripts/gen-types.mjs"
  },
  "dependencies": {
    "next": "^16.2.6",
    "react": "^19.2.6",
    "react-dom": "^19.2.6"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.0.0",
    "@types/node": "^22.10.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "eslint": "^9.39.4",
    "eslint-config-next": "^16.2.6",
    "openapi-typescript": "^7.13.0",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.9.0"
  }
}
File: frontend/next.config.ts
import type { NextConfig } from 'next';
const nextConfig: NextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  env: {
    API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:8000',
  },
};
export default nextConfig;
File: frontend/server.js
/**
 * Custom standalone server for production
 */
const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');
const port = parseInt(process.env.PORT || '3000', 10);
const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev, dir: __dirname });
const handle = app.getRequestHandler();
app.prepare().then(() => {
  createServer((req, res) => {
    const parsedUrl = parse(req.url, true);
    handle(req, res, parsedUrl);
  }).listen(port, '0.0.0.0', () => {
    console.log(`> Ready on http://0.0.0.0:${port}`);
  });
});
File: frontend/src/lib/api-client.ts
/**
 * Type-safe API client
 */
const API_BASE = process.env.API_BASE_URL || 'http://localhost:8000';
class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}
async function fetchAPI<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    credentials: 'include',
  });
  if (!response.ok) {
    throw new APIError(response.status, await response.text());
  }
  return response.json();
}
export const api = {
  health: () => fetchAPI<any>('/api/v1/health'),
  
  auth: {
    register: (data: { email: string; password: string }) =>
      fetchAPI<any>('/api/v1/auth/register', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    
    login: (data: { email: string; password: string }) =>
      fetchAPI<any>('/api/v1/auth/login', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    
    logout: (sessionId: string) =>
      fetchAPI<any>('/api/v1/auth/logout', {
        method: 'POST',
        body: JSON.stringify({ session_id: sessionId }),
      }),
  },
  
  llm: {
    complete: (data: { prompt: string }) =>
      fetchAPI<any>('/api/v1/llm/complete', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
  },
};
File: frontend/scripts/gen-types.mjs
/**
 * Generate TypeScript types from OpenAPI schema
 */
import fs from 'fs/promises';
import openapiTS from 'openapi-typescript';
const API_URL = process.env.API_BASE_URL || 'http://localhost:8000';
const OPENAPI_URL = `${API_URL}/openapi.json`;
const OUTPUT_FILE = 'src/lib/types.d.ts';
async function generateTypes() {
  try {
    console.log(`Fetching OpenAPI schema from ${OPENAPI_URL}...`);
    const output = await openapiTS(OPENAPI_URL);
    
    await fs.writeFile(OUTPUT_FILE, output);
    console.log(`✓ Generated types at ${OUTPUT_FILE}`);
  } catch (error) {
    console.error('Failed to generate types:', error);
    process.exit(1);
  }
}
generateTypes();
File: frontend/src/app/layout.tsx
import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = {
  title: 'My App',
  description: 'Full-stack application',
};
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
File: frontend/src/app/page.tsx
export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <h1 className="text-4xl font-bold">Welcome to My App</h1>
      <p className="mt-4">Full-stack application with FastAPI + Next.js + LLM</p>
    </main>
  );
}
Phase 8: Docker Containerization
File: packages/api/Dockerfile
# Multi-stage build for FastAPI API
FROM python:3.13-slim AS builder
WORKDIR /build
# Install uv
RUN pip install --no-cache-dir uv
# Copy all packages
COPY packages /build/packages
# Install dependencies
WORKDIR /build/packages/api
RUN uv pip install --system .
# Production stage
FROM python:3.13-slim
WORKDIR /app
# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
# Copy source code
COPY packages /app/packages
WORKDIR /app/packages/api
# Non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')"
EXPOSE 8000
CMD ["uvicorn", "app_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
File: frontend/Dockerfile
# Multi-stage build for Next.js frontend
FROM node:22-slim AS builder
WORKDIR /build
# Install pnpm
RUN corepack enable && corepack prepare pnpm@11.1.3 --activate
# Copy package files
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
# Copy source
COPY frontend .
# Build standalone
RUN pnpm build
# Production stage
FROM node:22-slim
WORKDIR /app
# Copy standalone build
COPY --from=builder /build/.next/standalone ./
COPY --from=builder /build/.next/static ./.next/static
COPY --from=builder /build/public ./public
COPY --from=builder /build/server.js ./
# Non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
EXPOSE 3000
CMD ["node", "server.js"]
File: docker-compose.yml (local development)
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: app_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app_user"]
      interval: 10s
      timeout: 5s
      retries: 5
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
  api:
    build:
      context: .
      dockerfile: packages/api/Dockerfile
    ports:
      - "8000:8000"
    environment:
      APP_ENVIRONMENT: development
      APP_DB_HOST: postgres
      APP_DB_USER: app_user
      APP_DB_PASSWORD: dev_password
      APP_DB_NAME: app_db
      APP_SECRET_KEY: dev-secret-key-change-in-prod
      APP_ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      APP_ALLOWED_ORIGINS: '["http://localhost:3000"]'
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
  frontend:
    build:
      context: .
      dockerfile: frontend/Dockerfile
    ports:
      - "3000:3000"
    environment:
      API_BASE_URL: http://api:8000
      NODE_ENV: production
    depends_on:
      - api
volumes:
  postgres_data:
---
Phase 9: AWS Infrastructure (Terraform)
File: infrastructure/main.tf
terraform {
  required_version = ">= 1.9"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "my-app-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-locks"
  }
}
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "my-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
# VPC and Networking
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
}
# ECR Repositories
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  repositories = ["api", "frontend"]
}
# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  database_name       = var.database_name
  database_username   = var.database_username
  instance_class      = var.database_instance_class
  allocated_storage   = var.database_allocated_storage
  multi_az            = var.database_multi_az
}
# ElastiCache Redis
module "elasticache" {
  source = "./modules/elasticache"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  node_type          = var.redis_node_type
  num_cache_nodes    = var.redis_num_nodes
}
# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  certificate_arn    = var.acm_certificate_arn
}
# ECS Cluster and Services
module "ecs" {
  source = "./modules/ecs"
  
  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  
  # Load balancer
  alb_target_group_api_arn = module.alb.target_group_api_arn
  alb_target_group_web_arn = module.alb.target_group_web_arn
  alb_security_group_id    = module.alb.security_group_id
  
  # Database
  database_host           = module.rds.endpoint
  database_name           = var.database_name
  database_username       = var.database_username
  database_password_arn   = module.rds.password_secret_arn
  
  # Redis
  redis_host              = module.elasticache.endpoint
  
  # ECR
  api_image_uri           = "${module.ecr.repository_urls["api"]}:latest"
  frontend_image_uri      = "${module.ecr.repository_urls["frontend"]}:latest"
  
  # Secrets
  anthropic_api_key_arn   = var.anthropic_api_key_secret_arn
  session_secret_arn      = var.session_secret_arn
}
File: infrastructure/modules/networking/main.tf
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}
# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.azs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.azs[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-${var.environment}-public-${var.azs[count.index]}"
    Type = "public"
  }
}
# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.azs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = var.azs[count.index]
  
  tags = {
    Name = "${var.project_name}-${var.environment}-private-${var.azs[count.index]}"
    Type = "private"
  }
}
# NAT Gateways (one per AZ for HA)
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }
}
resource "aws_nat_gateway" "main" {
  count = length(var.azs)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.main]
}
# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}
resource "aws_route_table" "private" {
  count = length(var.azs)
  
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  }
}
# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.azs)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count = length(var.azs)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
File: infrastructure/modules/ecs/main.tf
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}-${var.environment}/api"
  retention_in_days = 30
}
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}/frontend"
  retention_in_days = 30
}
# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Allow reading secrets
resource "aws_iam_role_policy" "secrets_access" {
  name = "secrets-access"
  role = aws_iam_role.ecs_task_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      Resource = [
        var.database_password_arn,
        var.anthropic_api_key_arn,
        var.session_secret_arn,
      ]
    }]
  })
}
# ECS Task Role (for app runtime)
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "API from ALB"
  }
  
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "Frontend from ALB"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  }
}
# API Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-${var.environment}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([{
    name  = "api"
    image = var.api_image_uri
    
    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]
    
    environment = [
      { name = "APP_ENVIRONMENT", value = var.environment },
      { name = "APP_DB_HOST", value = var.database_host },
      { name = "APP_DB_NAME", value = var.database_name },
      { name = "APP_DB_USER", value = var.database_username },
      { name = "APP_DB_PORT", value = "5432" },
      { name = "APP_COOKIE_SECURE", value = "true" },
    ]
    
    secrets = [
      {
        name      = "APP_DB_PASSWORD"
        valueFrom = var.database_password_arn
      },
      {
        name      = "APP_ANTHROPIC_API_KEY"
        valueFrom = var.anthropic_api_key_arn
      },
      {
        name      = "APP_SECRET_KEY"
        valueFrom = var.session_secret_arn
      },
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.api.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "api"
      }
    }
    
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])
}
# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([{
    name  = "frontend"
    image = var.frontend_image_uri
    
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    
    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "API_BASE_URL", value = "http://api.${var.project_name}-${var.environment}.local:8000" },
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "frontend"
      }
    }
    
    healthCheck = {
      command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/', (r) => process.exit(r.statusCode === 200 ? 0 : 1))\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])
}
# API ECS Service
resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-${var.environment}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.alb_target_group_api_arn
    container_name   = "api"
    container_port   = 8000
  }
  
  depends_on = [var.alb_target_group_api_arn]
}
# Frontend ECS Service
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-${var.environment}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.alb_target_group_web_arn
    container_name   = "frontend"
    container_port   = 3000
  }
  
  depends_on = [var.alb_target_group_web_arn]
}
data "aws_region" "current" {}
---
## Production Checklist
### Security
- [ ] Rotate all secrets and API keys
- [ ] Enable AWS WAF on ALB
- [ ] Configure VPC Flow Logs
- [ ] Enable GuardDuty
- [ ] Set up AWS Config for compliance
- [ ] Implement least-privilege IAM policies
- [ ] Enable MFA for AWS console access
- [ ] Configure Security Groups with minimal access
### Observability
- [ ] Set up CloudWatch dashboards
- [ ] Configure CloudWatch alarms (CPU, memory, errors)
- [ ] Enable X-Ray tracing
- [ ] Set up log aggregation and search
- [ ] Configure PagerDuty/OpsGenie integration
- [ ] Implement application metrics (Prometheus/OpenTelemetry)
### High Availability
- [ ] Enable Multi-AZ for RDS
- [ ] Configure RDS automated backups (point-in-time recovery)
- [ ] Set up Read Replicas for RDS (if needed)
- [ ] Deploy ECS tasks across multiple AZs
- [ ] Configure auto-scaling policies
- [ ] Test failover scenarios
### Performance
- [ ] Enable CloudFront CDN for static assets
- [ ] Configure ElastiCache Redis
- [ ] Optimize database indexes
- [ ] Enable RDS Performance Insights
- [ ] Implement database connection pooling
- [ ] Profile and optimize API response times
### Data Protection
- [ ] Enable encryption at rest (RDS, ElastiCache)
- [ ] Enable encryption in transit (TLS everywhere)
- [ ] Set up automated database backups
- [ ] Test disaster recovery procedures
- [ ] Configure backup retention policies
- [ ] Implement GDPR/compliance requirements
### CI/CD
- [ ] Set up GitHub Actions workflows
- [ ] Configure automated testing (unit, integration, E2E)
- [ ] Implement blue/green deployments
- [ ] Set up staging environment
- [ ] Configure rollback procedures
- [ ] Implement drift detection
### Cost Optimization
- [ ] Right-size ECS task resources
- [ ] Use Savings Plans or Reserved Instances
- [ ] Enable AWS Cost Explorer
- [ ] Set up billing alarms
- [ ] Review and optimize log retention
- [ ] Clean up unused resources
---
Common Patterns & Best Practices
1. Environment Variables
Always use a consistent naming convention:
# Application-wide
APP_ENVIRONMENT=production
APP_LOG_LEVEL=INFO
# Database
APP_DB_HOST=...
APP_DB_PORT=5432
APP_DB_NAME=...
APP_DB_USER=...
APP_DB_PASSWORD=...  # From Secrets Manager
# Secrets (always from Secrets Manager)
APP_SECRET_KEY=...
APP_ANTHROPIC_API_KEY=...
# Feature flags
APP_FEATURE_XYZ_ENABLED=true
2. Health Checks
Implement comprehensive health checks:
@router.get("/health")
async def health_check():
    checks = {
        "database": await check_database(),
        "cache": await check_redis(),
        "external_api": await check_anthropic(),
    }
    
    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503
    
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ok" if all_healthy else "degraded",
            "checks": checks,
        },
    )
3. Database Migrations
Always test migrations:
# Create migration
app-migrate revision "add users table" --autogenerate
# Review migration file before applying
# Apply to dev first
app-migrate upgrade head
# Test rollback
app-migrate downgrade -1
app-migrate upgrade head
4. Contract-Driven Development
Generate frontend types from API:
# After API changes
cd frontend
pnpm gen-types
# Verify type safety
pnpm typecheck
5. Error Handling
Use consistent error responses:
from fastapi import HTTPException, status
class AppError(HTTPException):
    def __init__(self, detail: str, status_code: int = 400):
        super().__init__(status_code=status_code, detail=detail)
class NotFoundError(AppError):
    def __init__(self, resource: str, id: Any):
        super().__init__(
            detail=f"{resource} with id={id} not found",
            status_code=status.HTTP_404_NOT_FOUND,
        )
6. Async Best Practices
Use async consistently:
# Good
async def get_user(user_id: int) -> User:
    async with db.session() as session:
        result = await session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
# Bad (mixing sync/async)
def get_user_sync(user_id: int) -> User:
    # Will block the event loop!
    return session.query(User).get(user_id)
7. LLM Streaming
Implement proper SSE streaming:
from sse_starlette.sse import EventSourceResponse
@router.post("/stream")
async def stream_completion(request: LLMRequest):
    async def event_generator():
        try:
            async for chunk in llm_client.stream(request):
                yield {"event": "message", "data": chunk}
        except Exception as e:
            yield {"event": "error", "data": str(e)}
        finally:
            yield {"event": "done", "data": ""}
    
    return EventSourceResponse(event_generator())
8. Deployment Strategy
Use blue/green deployments:
# Deploy new version
terraform apply -target=module.ecs
# Monitor health
aws ecs describe-services --cluster my-app-prod --services api
# Rollback if needed
aws ecs update-service --cluster my-app-prod \
  --service api \
  --task-definition my-app-prod-api:PREVIOUS_VERSION
---
## Decision Points for LLMs
When scaffolding an application, follow this decision tree:
### 1. **Does the application need real-time features?**
   - **Yes** → Add WebSocket support (FastAPI WebSockets)
   - **No** → Standard REST API is sufficient
### 2. **Does the application need background jobs?**
   - **Yes** → Add worker service (Celery/arq + Redis)
   - **No** → Use FastAPI BackgroundTasks for simple async tasks
### 3. **Does the application need file storage?**
   - **Yes** → Add S3 module + presigned URLs
   - **No** → Skip file storage infrastructure
### 4. **Does the application need search?**
   - **Yes** → Add OpenSearch/Elasticsearch module
   - **No** → Use PostgreSQL full-text search
### 5. **Does the application need authentication?**
   - **Session-based** → Use cookies + database sessions (included)
   - **JWT-based** → Replace session management with JWT tokens
   - **OAuth/OIDC** → Add AWS Cognito or Auth0 integration
### 6. **What's the expected scale?**
   - **Low** (<1000 users) → Single RDS instance, minimal redundancy
   - **Medium** (<100k users) → Multi-AZ RDS, auto-scaling ECS, CloudFront
   - **High** (>100k users) → Add read replicas, ElastiCache, CDN, auto-scaling
### 7. **Does the application need multi-tenancy?**
   - **Yes** → Add tenant_id to all models, row-level security
   - **No** → Skip tenant isolation logic
### 8. **Does the application need audit logging?**
   - **Yes** → Add audit_log table, event streaming
   - **No** → Standard application logging is sufficient
---
Execution Instructions for LLMs
When generating code from this template:
1. Always start with schemas - Define data models first
2. Generate migrations immediately after creating database models
3. Create health checks for every service
4. Generate types from OpenAPI schema before writing frontend code
5. Use environment variables for all configuration
6. Never hardcode secrets - always use Secrets Manager
7. Include Dockerfiles for every service
8. Write Terraform incrementally (networking → data → compute)
9. Add CloudWatch alarms for every critical metric
10. Test locally with docker-compose before deploying
File Creation Order
1. packages/schemas/ - Foundation
2. packages/database/ - Data layer
3. packages/auth/ - Security
4. packages/llm/ - External integrations
5. packages/api/ - API layer
6. frontend/ - UI
7. infrastructure/ - AWS resources
8. docker-compose.yml - Local dev
9. .github/workflows/ - CI/CD
---
Example Commands
# Local development
docker-compose up -d
docker-compose exec api app-migrate upgrade head
docker-compose logs -f api
# Build containers
docker build -f packages/api/Dockerfile -t my-app-api:latest .
docker build -f frontend/Dockerfile -t my-app-frontend:latest .
# Push to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag my-app-api:latest <account>.dkr.ecr.us-east-1.amazonaws.com/my-app-api:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/my-app-api:latest
# Deploy infrastructure
cd infrastructure/environments/prod
terraform init
terraform plan
terraform apply
# Run migrations on ECS
aws ecs run-task \
  --cluster my-app-prod \
  --task-definition my-app-prod-migrate \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
---
**End of Template**
This template provides a production-ready starting point for full-stack applications with FastAPI, Next.js, PostgreSQL, Redis, LLM integration, and AWS ECS deployment. Customize as needed for your specific requirements.
---