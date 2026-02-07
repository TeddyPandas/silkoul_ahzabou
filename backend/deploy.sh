#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit

echo "📂 Working directory: $SCRIPT_DIR"

# Pull latest changes (assuming git is used)
if [ -d ".git" ]; then
    echo "⬇️  Pulling latest changes from git..."
    git pull origin main
else
    echo "⚠️  Not a git repository. Skipping git pull."
fi

# Build and start containers
echo "🏗️  Building and starting containers..."
$DOCKER_COMPOSE_CMD down
$DOCKER_COMPOSE_CMD up -d --build

# Prune unused images to save space
echo "🧹 Cleaning up unused Docker images..."
docker image prune -f

echo "✅ Deployment completed successfully!"
$DOCKER_COMPOSE_CMD ps
