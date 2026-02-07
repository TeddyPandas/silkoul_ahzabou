#!/bin/bash

# Configuration
APP_DIR="/var/www/app" # Change this if needed
REPO_URL="YOUR_REPO_URL" # The user should replace this

echo "🚀 Starting Deployment Process..."

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

# Create app directory if it doesn't exist
if [ ! -d "$APP_DIR" ]; then
    echo "📁 Creating application directory at $APP_DIR..."
    mkdir -p "$APP_DIR"
    # Clone the repo here if it's the first time, but usually we just copy files or pull
    # git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR" || exit

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
