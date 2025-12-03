# Seshy API

FastAPI service for Seshy.

## Getting Started

### Development

#### Local Python environment

Install dependencies:
```bash
pip install -e ".[dev]"
```

Run the server:
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`.

#### Docker Compose

You can launch the API together with a local PostgreSQL instance via Docker Compose (recommended for parity with production):

```bash
cd services/api
docker compose up --build
```

The API will be available at `http://localhost:8080` and Postgres at `localhost:5432`.

##### Persistence

- Database rows persist across container restarts because `db` mounts the named volume `pg_data:/var/lib/postgresql/data`.
- To reset the database, remove the volume: `docker compose down -v`.

##### Bind mounts for hot-reload development

The `api` service bind-mounts the local source tree so code/migration edits are visible inside the container without rebuilding:

```yaml
volumes:
  - ./app:/app/app
  - ./alembic:/app/alembic
  - ./alembic.ini:/app/alembic.ini
```

Edit files locally, then restart the container (or rely on `--reload` if you run uvicorn that way) and the changes take effect immediately.

Apply the latest database migrations inside the running image:

```bash
cd services/api
docker compose run --rm api alembic upgrade head
```

Shut everything down when you're done:

```bash
docker compose down
```

### System Vibes

- Edit `app/seed_data/default_vibes.py` to change the canonical list of tags/vibes.
- Run `make seed-vibes` (or `python -m app.services.vibe_seed` from `services/api`) to apply the changes locally.
- Every FastAPI startup also calls the seeder so new environments (or deploys) always have the defaults.
- Users need enough reputation (`public_profiles.reputation_score`) before they can create their own vibes through `POST /vibes`.

### Endpoints

- `GET /` - Root endpoint
- `GET /healthz` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

### Deployment

Deployed to Cloud Run.
