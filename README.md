# Full-Stack Application Template

FastAPI + Next.js + LLM (Optional) + AWS ECS

A production-ready template for building full-stack applications with:
- **Backend**: FastAPI (Python 3.13) with async PostgreSQL
- **Frontend**: Next.js 16 (TypeScript)
- **LLM**: Optional Anthropic Claude integration
- **Infrastructure**: Docker + AWS ECS (Terraform)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- (Optional) Anthropic API key for LLM features

### Running the Application

1. **Start all services** (no configuration needed!):
   ```bash
   docker-compose up -d
   ```

2. **Access the application**:
   - Frontend: http://localhost:3000
   - API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Health Check: http://localhost:8000/api/v1/health

3. **(Optional) Enable LLM features**:
   ```bash
   # Create .env file
   cp .env.example .env
   
   # Add your Anthropic API key to .env
   # APP_ANTHROPIC_API_KEY=sk-ant-your-key-here
   
   # Restart API service
   docker-compose restart api
   ```

That's it! The application runs perfectly fine without an API key - LLM features are completely optional.

## Testing the Application

Once Docker is running, test your application with any of these methods:

**Quick Test (30 seconds):**
```bash
# Check health
curl http://localhost:8000/api/v1/health

# View interactive docs
open http://localhost:8000/docs  # macOS
# or visit http://localhost:8000/docs in your browser
```

**Automated Testing:**
```bash
# Run complete test suite
./scripts/test-api.sh
```

**For comprehensive testing guide:** See [`TESTING.md`](TESTING.md) for:
- Interactive Swagger UI testing (no coding!)
- curl command examples
- Postman collection
- Automated test scripts
- Troubleshooting guide

## What's Running

| Service    | Port | URL                          | Description                    |
|-----------|------|------------------------------|--------------------------------|
| Frontend  | 3000 | http://localhost:3000        | Next.js web application        |
| API       | 8000 | http://localhost:8000        | FastAPI backend                |
| Docs      | 8000 | http://localhost:8000/docs   | Interactive API documentation  |
| PostgreSQL| 5432 | localhost:5432               | Database                       |
| Redis     | 6379 | localhost:6379               | Cache                          |

## Features

### Implemented
- ✅ User authentication (register, login, logout)
- ✅ Session management with secure password hashing (Argon2)
- ✅ Database migrations with Alembic
- ✅ Health check endpoints
- ✅ Optional LLM integration (works without API key!)
- ✅ Type-safe API contracts (Pydantic)
- ✅ Async database operations (SQLModel + asyncpg)
- ✅ CORS configuration
- ✅ Docker containerization
- ✅ Production-ready Terraform infrastructure

### LLM Integration (Optional)
When you add an Anthropic API key, you get:
- Text completion endpoint (`/api/v1/llm/complete`)
- Streaming responses (`/api/v1/llm/stream`)
- Conversation history tracking
- Configurable models and parameters

Without an API key, the LLM endpoints return a clear 503 error explaining how to enable them.

## Development

### Using Docker (Recommended)
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after changes
docker-compose build
```

### Local Development (Without Docker)

**Backend:**
```bash
# Install dependencies (requires Python 3.13+)
cd packages/api
pip install uv
uv pip install -e .

# Run development server
uvicorn app_api.main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**
```bash
# Install dependencies (requires Node.js 20+)
cd frontend
npm install

# Run development server
npm run dev
```

**Database:**
```bash
# Make sure PostgreSQL is running on localhost:5432
# Or use Docker:
docker-compose up -d postgres redis
```

## Common Commands

### Managing Services
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart api

# View service status
docker-compose ps

# View logs
docker-compose logs -f api
docker-compose logs -f frontend
```

### Database Migrations
```bash
# Create a new migration
docker-compose exec api app-migrate revision "add users table" --autogenerate

# Run migrations
docker-compose exec api app-migrate upgrade head

# Rollback last migration
docker-compose exec api app-migrate downgrade -1

# For production ECS migrations, see MIGRATIONS.md
```

### Testing the API
```bash
# Health check
curl http://localhost:8000/api/v1/health

# Register a user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secure-password-123"}'

# LLM completion (requires API key)
curl -X POST http://localhost:8000/api/v1/llm/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello, world!"}'
```

## Project Structure

```
template-app-ecs/
├── packages/              # Python backend packages (monorepo)
│   ├── schemas/          # Shared Pydantic models and settings
│   ├── database/         # Database layer (SQLModel + Alembic)
│   ├── auth/             # Authentication (Argon2 hashing, sessions)
│   ├── llm/              # LLM integration (Anthropic Claude)
│   └── api/              # FastAPI application
│       ├── routers/      # API endpoints (health, auth, llm)
│       └── Dockerfile    # API container
├── frontend/             # Next.js application
│   ├── src/
│   │   ├── app/         # App Router pages
│   │   └── lib/         # API client, utilities
│   ├── scripts/         # Type generation from OpenAPI
│   └── Dockerfile       # Frontend container
├── infrastructure/       # Terraform for AWS ECS
│   ├── modules/         # Reusable Terraform modules
│   └── environments/    # Environment configs (dev, staging, prod)
├── docker-compose.yml   # Local development environment
├── .env.example         # Environment variables template
├── README.md           # This file
└── SETUP_SUMMARY.md    # Detailed setup guide
```

## Configuration

### Environment Variables

The application uses environment variables for configuration. See `.env.example` for all available options.

**Required (have defaults):**
- `APP_SECRET_KEY` - Session encryption key (default: dev-secret-change-in-production)
- `APP_DB_HOST` - Database host (default: localhost)
- `APP_DB_NAME` - Database name (default: app_db)
- `APP_DB_USER` - Database user (default: app_user)
- `APP_DB_PASSWORD` - Database password (default: dev_password)

**Optional:**
- `APP_ANTHROPIC_API_KEY` - Anthropic API key for LLM features
- `APP_DEFAULT_MODEL` - Claude model to use (default: claude-opus-4-8)
- `APP_LOG_LEVEL` - Logging level (default: INFO)
- `APP_ALLOWED_ORIGINS` - CORS origins (default: ["http://localhost:3000"])

## Deployment

### AWS ECS (Production)

This template includes complete Terraform configuration for AWS ECS deployment:

1. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

2. **Update Terraform variables**:
   ```bash
   cd infrastructure/environments/prod
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Build and push Docker images**:
   ```bash
   # See infrastructure/README.md for detailed instructions
   ```

See `infrastructure/` directory and `sample-claude-app.md` for detailed deployment documentation.

## Technology Stack

**Backend:**
- FastAPI 0.136+ (async Python web framework)
- SQLModel + SQLAlchemy 2.0 (async ORM)
- PostgreSQL 16+ (database)
- Redis 7 (caching)
- Alembic (database migrations)
- Anthropic Claude SDK 0.40+ (LLM integration)
- Argon2 (password hashing)
- Pydantic 2.13+ (data validation)
- uvicorn (ASGI server)

**Frontend:**
- Next.js 16+ (React framework with App Router)
- TypeScript 5.9+
- Tailwind CSS 4.0+
- npm (package manager)

**Infrastructure:**
- Docker + Docker Compose (containerization)
- AWS ECS Fargate (serverless containers)
- AWS RDS (managed PostgreSQL)
- AWS ElastiCache (managed Redis)
- Terraform (infrastructure as code)
- GitHub Actions (CI/CD)

## Troubleshooting

### Services won't start
```bash
# Check service status
docker-compose ps

# View logs for errors
docker-compose logs

# Common fix: remove old containers and volumes
docker-compose down -v
docker-compose up -d
```

### Port already in use
If you see errors about ports 3000, 8000, 5432, or 6379 being in use:
```bash
# Find process using the port
lsof -i :3000

# Kill the process or stop conflicting services
```

### Database connection errors
```bash
# Ensure PostgreSQL is healthy
docker-compose ps postgres

# Restart database
docker-compose restart postgres

# Check database logs
docker-compose logs postgres
```

### LLM endpoints not working
- Without API key: This is expected! LLM endpoints return 503 with instructions
- With API key: Check logs for errors: `docker-compose logs api`
- Verify API key is set correctly in `.env`

## Documentation

- **Setup Guide**: See `SETUP_SUMMARY.md` for detailed setup instructions
- **Migrations**: See `MIGRATIONS.md` for database migration guide (local + ECS)
- **Architecture**: See `sample-claude-app.md` for complete architecture documentation
- **API Docs**: Visit http://localhost:8000/docs when running
- **Infrastructure**: See `infrastructure/` directory for AWS deployment docs

## Getting an Anthropic API Key

1. Visit https://console.anthropic.com
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Add it to your `.env` file:
   ```
   APP_ANTHROPIC_API_KEY=sk-ant-your-key-here
   ```
6. Restart the API: `docker-compose restart api`

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
