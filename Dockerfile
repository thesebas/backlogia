FROM python:3.11-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install system dependencies (git used by legendary-gl at runtime)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with uv (layer cached until lockfile changes)
ENV UV_PROJECT_ENVIRONMENT=/app/.venv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Copy application code
COPY web/ ./web/

# Create data directory for the database
RUN mkdir -p /data

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DATABASE_PATH=/data/game_library.db
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 5050

# Run the FastAPI application
CMD ["uvicorn", "web.main:app", "--host", "0.0.0.0", "--port", "5050"]
