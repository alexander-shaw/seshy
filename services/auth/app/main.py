from fastapi import FastAPI

app = FastAPI(
    title="Seshy Auth Service",
    description="Authentication service for Seshy",
    version="0.1.0",
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Seshy Auth Service", "version": "0.1.0"}


@app.get("/healthz")
async def healthz():
    """Health check endpoint."""
    return {"status": "ok"}

