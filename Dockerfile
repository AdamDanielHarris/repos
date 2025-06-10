FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    git \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    gettext-base \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir PyYAML

# Create non-root user
RUN useradd -m -s /bin/bash -u 1000 repouser

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy essential application files
COPY repos functions yaml_lookup.py ./

# Copy tests directory if it exists
COPY tests/ ./tests/

# Make scripts executable
RUN chmod +x repos functions tests/run_tests.sh

# Set git safe directory for mounted volumes
RUN git config --global --add safe.directory /app \
    && git config --global --add safe.directory '/app/git/*' \
    && git config --global --add safe.directory '*'

# Switch to non-root user
USER repouser

# Default command
CMD ["bash", "-c", "if [ -f /tmp/host_gitconfig ]; then cp /tmp/host_gitconfig /home/repouser/.gitconfig && chown repouser:repouser /home/repouser/.gitconfig; fi && exec ./repos --help"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import yaml; print('Dependencies OK')" || exit 1

# Labels
LABEL maintainer="Repository Management Tool" \
      description="Docker container for multi-repository Git management" \
      version="1.0"
