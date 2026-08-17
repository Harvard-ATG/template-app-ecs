.PHONY: help dev build test clean

help:
	@echo "Available commands:"
	@echo "  make dev     - Start development environment"
	@echo "  make build   - Build Docker containers"
	@echo "  make test    - Run tests"
	@echo "  make clean   - Clean up containers and volumes"

dev:
	docker-compose up -d

build:
	docker-compose build

test:
	docker-compose exec api pytest
	cd frontend && pnpm test

clean:
	docker-compose down -v
