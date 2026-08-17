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
