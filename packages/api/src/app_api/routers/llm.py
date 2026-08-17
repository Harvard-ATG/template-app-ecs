"""LLM endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sse_starlette.sse import EventSourceResponse

from app_llm.client import LLMClient
from app_schemas.contracts import LLMRequest, LLMResponse

from ..dependencies import get_llm_client

router = APIRouter()


@router.post("/complete", response_model=LLMResponse)
async def complete(
    request: LLMRequest,
    llm: LLMClient | None = Depends(get_llm_client),
):
    """Generate a completion (non-streaming)."""
    if llm is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "LLM service not configured",
                "message": "Anthropic API key not provided. Set APP_ANTHROPIC_API_KEY environment variable to enable LLM features.",
            },
        )
    
    if request.stream:
        return {"error": "Use /stream endpoint for streaming"}
    
    return await llm.complete(request)


@router.post("/stream")
async def stream(
    request: LLMRequest,
    llm: LLMClient | None = Depends(get_llm_client),
):
    """Generate a streaming completion (SSE)."""
    if llm is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error": "LLM service not configured",
                "message": "Anthropic API key not provided. Set APP_ANTHROPIC_API_KEY environment variable to enable LLM features.",
            },
        )
    
    async def event_generator():
        async for chunk in llm.stream(request):
            yield {"data": chunk}
    
    return EventSourceResponse(event_generator())
