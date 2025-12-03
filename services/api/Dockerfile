FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy dependency files
COPY pyproject.toml ./
COPY README.md ./

# Copy application code
COPY app/ ./app/

# Install Python dependencies
RUN pip install --no-cache-dir .

# Copy Alembic migration assets after dependency install to avoid packaging issues
COPY alembic.ini ./
COPY alembic/ ./alembic/

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Run uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
