# Services

Deployable backend microservices for Seshy.

## What Was Built

### API Service (`services/api/`)
FastAPI microservice exposing REST endpoints.

**What:**
- FastAPI application with `/` and `/healthz` endpoints
- Dockerized for Cloud Run deployment
- Python 3.11-slim base image

**Why:**
- FastAPI provides async performance and automatic OpenAPI docs
- Separate API service enables independent scaling and deployments
- Cloud Run for serverless, cost-effective hosting

**Benefits:**
- Fast development with auto-generated docs (`/docs`)
- Scales to zero when not in use
- Simple Docker-based deployment
- Easy to extend with new endpoints

**Tradeoffs:**
- Cold starts can cause latency (use min_instances > 0 if needed)
- Stateless design - no local storage or sessions
- Vendor lock-in to GCP (but portable Docker images)

### Auth Service (`services/auth/`)
Authentication microservice (scaffolded for future implementation).

**Why separate:**
- Isolate security concerns
- Scale independently based on auth load
- Enable different deployment strategies per service

### Fingerprint Service (`services/fingerprint/`)
Device fingerprinting microservice (scaffolded for future implementation).

**Why separate:**
- Specialized device tracking logic
- Privacy-sensitive data isolation
- Modular for future ML model integration

## Architecture

Services follow a microservices pattern:
- Each service has its own FastAPI app
- Independent Docker containers
- Shared infrastructure (Cloud Run, Artifact Registry)
- Environment-based deployments (staging/production)

## Testing Locally

```bash
# Build and run API
make build-api
make run-api

# Test health endpoint
curl http://localhost:8080/healthz
```

All services expose health checks at `/healthz` for monitoring.