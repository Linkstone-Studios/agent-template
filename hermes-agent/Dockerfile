# Dockerfile for Hermes Agent Configuration
# This container runs the Hermes Agent with the current config repository.

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Clone the main Hermes Agent repository
WORKDIR /app
RUN git clone https://github.com/NousResearch/hermes-agent.git hermes-agent

# Install dependencies for the agent
WORKDIR /app/hermes-agent
RUN pip install --no-cache-dir -e .

# Set up the .hermes directory
RUN mkdir -p /root/.hermes

# Set environment variables
# HERMES_HOME is where the agent looks for its config
ENV HERMES_HOME="/root/.hermes"
# Ensure the API server is enabled by default in the container environment
ENV API_SERVER_ENABLED=true
# Set a default API port
ENV API_SERVER_PORT=8642

# Expose the API and Gateway ports
EXPOSE 8642
EXPOSE 8000

# Default command: run the gateway (which includes the API server if enabled)
CMD ["python", "-m", "hermes_cli.main", "gateway", "run", "--replace"]
