# syntax=docker/dockerfile:1.7

# Stage 1 — copy uv binary from official image
FROM ghcr.io/astral-sh/uv:0.5.11 AS uv-bin

# Stage 2 — runtime
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PATH=/opt/venv/bin:/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless \
        curl \
        ca-certificates \
        git \
        procps \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Bring in uv from the official image (multi-stage, keeps final image lean)
COPY --from=uv-bin /uv /uvx /usr/local/bin/

WORKDIR /workspace

# Copy lock + manifest first to leverage Docker layer cache
COPY pyproject.toml uv.lock* .python-version /workspace/

# Install Python 3.11 and project dependencies into /opt/venv
RUN uv python install 3.11 && \
    uv sync --frozen --no-install-project --group docs || \
    uv sync --no-install-project --group docs

# Now copy the rest of the project
COPY . /workspace

EXPOSE 8888 8000

# Tini as PID 1 for clean signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# JupyterLab without token (localhost-only via docker-compose port binding)
CMD ["uv", "run", "--no-sync", "jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--ServerApp.token=", \
     "--ServerApp.password=", \
     "--ServerApp.root_dir=/workspace"]
