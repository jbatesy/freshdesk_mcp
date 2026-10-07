# Chainguard Python images are minimal, rebuilt daily and ship with zero known CVEs.
# Both stages are pinned by digest so the venv built in the builder matches the
# runtime's Python exactly. Bump both digests together to pick up fixes.

# Build stage: has a shell, pip and uv
FROM cgr.dev/chainguard/python:latest-dev@sha256:630df1be3733f7b38d1b535872904248adfe23fbea4befcb08da47cb7436ddb2 AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON=/usr/bin/python \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Install locked dependencies first so this layer is cached across source changes
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src ./src
RUN uv sync --frozen --no-dev --no-editable

# Runtime stage: distroless, no shell or package manager, runs as nonroot
FROM cgr.dev/chainguard/python:latest@sha256:8c6e0d0a587455e8a8d145e20234d5ef5a531a1c052a7b9d76b155ccc7fcded2

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH" \
    MCP_TRANSPORT=streamable-http \
    MCP_HOST=0.0.0.0 \
    MCP_PORT=8000

# Streamable HTTP endpoint is served at http://<host>:8000/mcp
EXPOSE 8000

# Clear the base image's python entrypoint so the command can be overridden as before
ENTRYPOINT []
CMD ["freshdesk-mcp"]
