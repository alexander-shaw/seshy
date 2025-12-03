# Services

Monolithic FastAPI backend service for Seshy.

## Architecture

**Monolithic API Service** (`services/api/`):
- Single FastAPI application containing all backend functionality
- All endpoints (users, events, places, members, invites, media, vibes, notifications, payments)
- Shared database connections and transactions
- Simplified deployment and development

**Why Monolithic:**
- Faster development and deployment
- Shared database transactions for data consistency
- Lower latency (no inter-service network calls)
- Easier debugging and testing
- Can split into microservices later if needed

## Current Services

### API Service (`services/api/`)
FastAPI application with all backend endpoints.

**What:**
- FastAPI application with REST endpoints
- Dockerized for Cloud Run deployment
- Python 3.11-slim base image
- PostgreSQL database (via Google Cloud SQL)

**Endpoints:**
- User management: `/me/public-profile`, `/me/settings`, `/me/login`
- Events: `/events/*` (to be implemented)
- Places: `/places/*` (to be implemented)
- Members: `/events/{id}/members/*` (to be implemented)
- Invites: `/events/{id}/invites/*` (to be implemented)
- Media: `/media/*` (to be implemented)
- Vibes: `/vibes/*` (to be implemented)
- Notifications: `/notifications/*` (to be implemented)
- Payments: `/tickets/*`, `/payments/*` (to be implemented)

**Benefits:**
- Fast development with auto-generated docs (`/docs`)
- Scales to zero when not in use (Cloud Run)
- Simple Docker-based deployment
- Easy to extend with new endpoints
- Shared database for transactional consistency

**Tradeoffs:**
- Cold starts can cause latency (use min_instances > 0 if needed)
- Stateless design - no local storage or sessions
- Vendor lock-in to GCP (but portable Docker images)

## Testing Locally

```bash
# Build and run API
make build-api
make run-api

# Test health endpoint
curl http://localhost:8080/healthz
```

The API exposes health checks at `/healthz` for monitoring.

## Development

See `services/api/README.md` for detailed development instructions.
