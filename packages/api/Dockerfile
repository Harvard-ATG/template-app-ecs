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

# Copy entrypoint script
COPY --chown=appuser:appuser packages/api/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')"

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["serve"]
