from fastapi import FastAPI

app = FastAPI(
    title="Seshy Device Fingerprint Service",
    description="Device fingerprinting service for Seshy",
    version="0.1.0",
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Seshy Device Fingerprint Service", "version": "0.1.0"}


@app.get("/healthz")
async def healthz():
    """Health check endpoint."""
    return {"status": "ok"}

