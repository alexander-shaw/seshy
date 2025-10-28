# Seshy Device Fingerprint Service

Device fingerprinting microservice for Seshy.

## Getting Started

### Development

Install dependencies:
```bash
pip install -e ".[dev]"
```

Run the server:
```bash
uvicorn app.main:app --reload
```

The service will be available at `http://localhost:8000`.

### Endpoints

- `GET /` - Root endpoint
- `GET /healthz` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation (ReDoc)

### Deployment

Deployed to Cloud Run.

