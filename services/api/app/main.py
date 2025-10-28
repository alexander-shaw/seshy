from fastapi import FastAPI

app = FastAPI(
    title="Seshy API",
    description="API service for Seshy",
    version="0.1.0",
)


@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Seshy API", "version": "0.1.0"}


@app.get("/healthz")
async def healthz():
    """Health check endpoint."""
    return {"status": "ok"}
