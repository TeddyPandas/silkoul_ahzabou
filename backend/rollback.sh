#!/bin/bash

# rollback.sh
# Usage: ./rollback.sh

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit

echo "⏪ Starting Rollback Process..."

# 1. Rollback API Container
if docker image inspect backend-api:backup &>/dev/null; then
    echo "📦 Reverting API to backup image..."
    docker tag backend-api:backup backend-api:latest
    docker compose up -d --force-recreate api
    echo "✅ API rolled back successfully."
else
    echo "❌ No backup image (backend-api:backup) found. Cannot rollback API."
fi

# 2. Rollback Frontend Files
if [ -d "/var/www/silkoul-frontend_backup" ]; then
    echo "🌐 Restoring frontend files from backup..."
    # Remove current and move backup to current
    sudo rm -rf /var/www/silkoul-frontend/*
    sudo cp -r /var/www/silkoul-frontend_backup/* /var/www/silkoul-frontend/
    echo "✅ Frontend files restored."
else
    echo "⚠️  No frontend backup found at /var/www/silkoul-frontend_backup."
fi

echo "🎉 Rollback completed!"
docker compose ps
