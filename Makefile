.PHONY: help build-api run-api test-api build-auth run-auth test-auth build-fingerprint run-fingerprint test-fingerprint

# Default target
help:
	@echo "Available targets:"
	@echo "  build-api         - Build Docker image for API"
	@echo "  run-api           - Run Docker container for API"
	@echo "  test-api          - Test API health endpoint"
	@echo "  build-auth        - Build Docker image for Auth service"
	@echo "  run-auth          - Run Docker container for Auth service"
	@echo "  test-auth         - Test Auth health endpoint"
	@echo "  build-fingerprint - Build Docker image for Fingerprint service"
	@echo "  run-fingerprint   - Run Docker container for Fingerprint service"
	@echo "  test-fingerprint  - Test Fingerprint health endpoint"

# API service
build-api:
	docker build -t seshy-api:dev services/api

run-api:
	docker run -p 8080:8080 seshy-api:dev

test-api:
	@echo "Testing http://localhost:8080/healthz"
	@curl -s http://localhost:8080/healthz || echo "API not running. Run 'make run-api' first."

# Auth service
build-auth:
	docker build -t seshy-auth:dev services/auth

run-auth:
	docker run -p 8081:8080 seshy-auth:dev

test-auth:
	@echo "Testing http://localhost:8081/healthz"
	@curl -s http://localhost:8081/healthz || echo "Auth not running. Run 'make run-auth' first."

# Fingerprint service
build-fingerprint:
	docker build -t seshy-fingerprint:dev services/fingerprint

run-fingerprint:
	docker run -p 8082:8080 seshy-fingerprint:dev

test-fingerprint:
	@echo "Testing http://localhost:8082/healthz"
	@curl -s http://localhost:8082/healthz || echo "Fingerprint not running. Run 'make run-fingerprint' first."
