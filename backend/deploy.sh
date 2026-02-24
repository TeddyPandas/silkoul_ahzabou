#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit

echo "📂 Working directory: $SCRIPT_DIR"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker could not be found. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "⚠️  docker-compose command not found. Trying 'docker compose'..."
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose could not be found. Please install Docker Compose first."
        exit 1
    fi
    DOCKER_COMPOSE_CMD="docker compose"
else
    DOCKER_COMPOSE_CMD="docker-compose"
fi

# Pull latest changes (assuming git is used)
if [ -d ".git" ]; then
    echo "⬇️  Pulling latest changes from git..."
    git pull origin main
else
    echo "⚠️  Not a git repository. Skipping git pull."
fi

# Check if Docker network exists
if ! docker network inspect silkoul-network >/dev/null 2>&1; then
    echo "🌐 Creating Docker network 'silkoul-network'..."
    docker network create silkoul-network
else
    echo "✅ Network 'silkoul-network' already exists."
fi

# Deploy Infra Stack (NPM, Kuma, Dozzle)
if [ -f "docker-compose.infra.yml" ]; then
    echo "🏗️  Checking Infrastructure Stack..."
    $DOCKER_COMPOSE_CMD -f docker-compose.infra.yml up -d
fi

# Build and start Application containers (zero-downtime: no "down" step)
# Docker Compose will recreate only containers whose config/image changed
echo "🚀 Deploying Application Stack (API + Frontend)..."
$DOCKER_COMPOSE_CMD -f docker-compose.yml up -d --build --force-recreate

# Prune unused images to save space
echo "🧹 Cleaning up unused Docker images..."
docker image prune -f

echo "✅ Deployment completed successfully!"
$DOCKER_COMPOSE_CMD ps
