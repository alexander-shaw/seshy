.PHONY: help build-api run-api test-api seed-vibes

# Default target
help:
	@echo "Available targets:"
	@echo "  build-api         - Build Docker image for API"
	@echo "  run-api           - Run Docker container for API"
	@echo "  test-api          - Test API health endpoint"

# API service
build-api:
	docker build -t seshy-api:dev services/api

run-api:
	docker run -p 8080:8080 seshy-api:dev

test-api:
	@echo "Testing http://localhost:8080/healthz"
	@curl -s http://localhost:8080/healthz || echo "API not running. Run 'make run-api' first."

seed-vibes:
	cd services/api && python3 -m app.services.vibe_seed
