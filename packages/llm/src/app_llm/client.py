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
        if not settings.anthropic_api_key:
            raise ValueError(
                "Anthropic API key is required to use LLM features. "
                "Set APP_ANTHROPIC_API_KEY environment variable."
            )
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
