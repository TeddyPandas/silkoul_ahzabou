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

# Ensure Docker Compose V2 plugin is available
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose V2 plugin not found. Please install it."
    exit 1
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

# Deploy Infra Stack (NPM, Kuma, Portainer)
if [ -f "docker-compose.infra.yml" ]; then
    echo "🏗️  Checking Infrastructure Stack..."
    docker compose -f docker-compose.infra.yml up -d
fi

# ══════════════════════════════════════════════════════════════
# ZERO-DOWNTIME DEPLOYMENT WITH ROLLBACK
# ══════════════════════════════════════════════════════════════

# Tag current image as backup before building new one
echo "💾 Saving backup of current API image..."
docker tag backend-api:latest backend-api:backup 2>/dev/null || echo "⚠️  No previous image to backup (first deploy?)"

# Build and start Application containers (zero-downtime)
echo "🚀 Deploying Application Stack (API + Frontend)..."
docker compose -f docker-compose.yml up -d --build --force-recreate

# Wait for container to be healthy
echo "⏳ Waiting for API health check (30s timeout)..."
HEALTH_OK=false
for i in $(seq 1 15); do
    sleep 2
    HTTP_CODE=$(docker exec backend-api-1 wget -q -O /dev/null -S http://localhost:3000/health 2>&1 | grep "HTTP/" | awk '{print $2}' || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        HEALTH_OK=true
        echo "✅ API health check passed after $((i*2))s"
        break
    fi
    echo "   ⏳ Attempt $i/15 — waiting..."
done

# ROLLBACK if health check failed
if [ "$HEALTH_OK" = false ]; then
    echo "❌ Health check FAILED! Rolling back to previous version..."
    
    if docker image inspect backend-api:backup &>/dev/null; then
        docker tag backend-api:backup backend-api:latest
        docker compose -f docker-compose.yml up -d --force-recreate
        echo "🔙 ROLLBACK completed. Previous version restored."
    else
        echo "⚠️  No backup image found. Cannot rollback. Manual intervention needed."
    fi
    
    exit 1
fi

# Prune unused images to save space (keep backup)
echo "🧹 Cleaning up unused Docker images..."
docker image prune -f

echo ""
echo "══════════════════════════════════════════════════════"
echo "  ✅ Deployment completed successfully!"
echo "══════════════════════════════════════════════════════"
docker compose -f docker-compose.yml ps
docker compose -f docker-compose.infra.yml ps
