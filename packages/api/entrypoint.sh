#!/bin/bash
set -e

# Navigate to database package where alembic.ini lives
cd /app/packages/database

case "$1" in
  migrate)
    echo "Running database migrations..."
    app-migrate upgrade --revision head
    echo "✓ Migrations completed successfully"
    ;;
  serve)
    echo "Starting API server..."
    cd /app/packages/api
    exec uvicorn app_api.main:app --host 0.0.0.0 --port 8000
    ;;
  *)
    echo "Usage: $0 {migrate|serve}"
    exit 1
    ;;
esac
